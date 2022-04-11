const FBSR_SERVER = "http://fbsr.petal.org:5000";

// get base path to assets for icons etc.
const assetsPath =
  document
    .querySelector("img[alt='logo']") // assumes that the logo is an image located in docs/assets/
    .getAttribute("src")
    .split("assets/")[0] + "assets";

// decodes a blueprint string into a javascript object
const decodeBlueprintString = (blueprintString) =>
  JSON.parse(
    pako.inflate(
      Uint8Array.from(atob(blueprintString.substr(1)), (c) => c.charCodeAt(0)),
      { to: "string" }
    )
  );

// encodes a javascript object into the factorio blueprint string
// const encodeBlueprintString = (blueprintObject) =>
//   "0" + btoa(String.fromCharCode(...pako.deflate(JSON.stringify(blueprintObject))));
// maximum call stack exceeded

const encodeBlueprintString = (blueprintObject) => {
  const byteArray = pako.deflate(JSON.stringify(blueprintObject)); // Uint8Array
  // avoid call stack size exceeded https://bugs.webkit.org/show_bug.cgi?id=80797
  const strChunks = [];
  const stride = 32768;
  for (let offset = 0; offset < byteArray.length; offset += stride) {
    strChunks.push(
      String.fromCharCode(...byteArray.subarray(offset, offset + stride))
    );
  }
  return "0" + btoa(strChunks.join(""));
};

// generate unique ids for image placeholders
const uuidv4 = () =>
  ([1e7] + -1e3 + -4e3 + -8e3 + -1e11).replace(/[018]/g, (c) =>
    (
      c ^
      (crypto.getRandomValues(new Uint8Array(1))[0] & (15 >> (c / 4)))
    ).toString(16)
  );

// return pairs [name, count] for entities in list in descending order of count
const getEntityCounts = (entities) => {
  const counter = {};
  entities.forEach((entity) => {
    counter[entity.name] =
      entity.name in counter ? counter[entity.name] + 1 : 1;
  });
  return [...Object.entries(counter)].sort((a, b) => b[1] - a[1]);
};

// get "custom" blueprint properties that don't have explicit display rules
// returns a list of [key, value] pairs
const getCustomEntries = (obj, denylist = []) => {
  const keys = [...Object.keys(obj)].filter((key) => !denylist.includes(key));
  return keys.map((key) => {
    const value =
      typeof obj[key] === "string" || obj[key] instanceof String
        ? obj[key]
        : `<code>${JSON.stringify(obj[key])}</code>`;
    return [key, value];
  });
};

const formatText = (text) => {
  const colors = text.replace(
    /\[color=(.+?)\](.+?)\[\/color\]/gm,
    `<span style="color:$1">$2</span>`
  );
  const icons = colors.replace(/\[item=(.+?)\]/gm, (match, name) => {
    return getEntityIcon(name);
  });
  return icons;
};

const remapping = {
  "straight-rail": "rail",
  "electric-energy-interface": "accumulator",
  "stone-wall": "wall",
  "heat-exchanger": "heat-boiler",
  "infinity-pipe": "pipe",
};

// get <img> html for entity icons
const getEntityIcon = (name) => {
  let filename = name in remapping ? remapping[name] : name;
  let src = `${assetsPath}/factorio/icons/${filename}.png`;
  return `<img class="icon" src="${src}" loading="lazy" alt="${filename}">`;
};

// get <img> html for blueprint icons
const getSignalIcon = (icon) => {
  let filename =
    icon.signal.name in remapping
      ? remapping[icon.signal.name]
      : icon.signal.name;
  if (icon.signal.type === "virtual") {
    filename = `signal/${icon.signal.name.replace("-", "_")}`;
  }
  if (icon.signal.type === "fluid") {
    filename = `fluid/${icon.signal.name}`;
  }
  if (icon.signal.name === "signal-check") {
    filename = `checked-green`;
  }
  if (icon.signal.name === "signal-dot") {
    filename = `list-dot`;
  }
  const src = `${assetsPath}/factorio/icons/${filename}.png`;
  return `<img class="icon" src="${src}" loading="lazy" alt="[${icon.signal.type}=${icon.signal.name}]">`;
};

const getBlueprintImageUrl = async (blueprint) => {
  const blueprintString =
    typeof blueprint === "string" || blueprint instanceof String
      ? blueprint
      : encodeBlueprintString(blueprint);
  const response = await fetch(`${FBSR_SERVER}/blueprint`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      blueprint: blueprintString,
    }),
  });

  const data = await response.json();
  console.log("data", data);
  const url = `${FBSR_SERVER}/cache/${data.name}.png`;
  return url;
};

// get html representation of blueprint object
const getBlueprintHTML = (blueprint) => {
  // assemble html as array instead of using string concatenation for performance
  const htmlFragments = [];
  // blueprint label with item image
  const icon = { signal: { name: blueprint.item, type: "item" } };
  const iconImg = getSignalIcon(icon);
  const icons =
    "icons" in blueprint
      ? blueprint.icons.map((icon) => getSignalIcon(icon))
      : [];
  htmlFragments.push(
    `<div class="property-row">
      <div class="property-value" style="display:flex">
        <div class="label-icon">
          <div class="item-icon">${iconImg}</div>
          <div class="blueprint-icons icons-${icons.length}">${icons.join(
      ""
    )}</div>
        </div>
        <span class="blueprint-label">${
          blueprint.label ? formatText(blueprint.label) : ""
        }<span>
        </div>
    </div>`
  );
  // The CSS property `white-space: pre-line;` preserves newlines
  // so we don't need to replace "\n" with <br />
  if ("description" in blueprint) {
    htmlFragments.push(
      `<div class="property-row">
        <!-- <div class="property-name">description</div> -->
        <div class="property-value" style="white-space: pre-line;">${formatText(
          blueprint.description.trim()
        )}</div>
      </div>`
    );
  }
  // get [key, value] pairs of blueprint object properties after applying denylist
  const customEntries = getCustomEntries(blueprint, [
    "item",
    "label",
    "icons",
    "description",
    "entities",
    "tiles",
    "blueprints",
    "version",
    "active_index",
    "schedules",
    "snap-to-grid",
  ]);
  customEntries.forEach(([key, val]) => {
    htmlFragments.push(
      `<div class="property-row">
        <div class="property-name">${key}</div>
        <div class="property-value">${val}</div>
      </div>`
    );
  });
  // entities count
  if ("entities" in blueprint) {
    const entities = [];
    let totalCount = 0;
    const allEntities =
      "tiles" in blueprint
        ? [...blueprint.entities, ...blueprint.tiles]
        : blueprint.entities;
    const counts = getEntityCounts(allEntities);
    let maxCount = 0;
    counts.forEach(([name, count]) => {
      if (count > maxCount) maxCount = count;
    });
    const digits = `${maxCount}`.length;
    counts.forEach(([name, count]) => {
      totalCount += count;
      const paddedCount = `${count}`.padStart(digits, "\u00A0");
      const icon = getEntityIcon(name);
      entities.push(
        `<div class="entity-count"><span class="count">${paddedCount}</span>${icon}<span class="label">${name}</span></div>`
      );
    });
    const noCollapse = entities.join("");
    const paddedTotalCount = `${totalCount}`.padStart(digits, "\u00A0");
    const collapse = `<div class="entity-list-toggle" onclick="this.nextElementSibling.style.display='block';this.style.display='none';">
      <div class="entity-count">
        <span class="count">${paddedTotalCount}</span> entities <span class="show-on-hover">(click to expand)</span>
      </div>
    </div>
    <div class="entity-list" style="display:none">${noCollapse}</div>`;
    htmlFragments.push(
      `<div class="property-row">
        <div class="property-value entities">${
          entities.length <= 5
            ? `<div class="entity-list" style="display:block">${noCollapse}</div>`
            : collapse
        }</div>
      </div>`
    );
  }
  // blueprint books contain a blueprints property which is an array of blueprintObjects
  if ("blueprints" in blueprint) {
    const blueprints = blueprint.blueprints.map((blueprintObject) => {
      const key = [...Object.keys(blueprintObject)][0];
      return getBlueprintHTML(blueprintObject[key]);
    });
    htmlFragments.push(
      `<div class="property-row">
        <!--<div class="property-name">blueprints</div>-->
        <div class="property-value" style="display: block">${blueprints.join(
          ""
        )}</div>
      </div>`
    );
  }
  // blueprint image preview
  if (blueprint.item === "blueprint") {
    const blueprintString = encodeBlueprintString({ blueprint: blueprint });
    const uuid = uuidv4();
    htmlFragments.push(
      `<div class="property-row">
        <!--<div class="property-name">blueprint preview</div>-->
        <img id="${uuid}" class="blueprint-preview" alt="${uuid}" loading="lazy" style="display: none;"/>
      </div>`
    );
    getBlueprintImageUrl(blueprintString).then((url) => {
      const image = document.getElementById(uuid);
      image.src = url;
      image.style.display = "block";
      image.onload = function () {
        image.style.width = `${this.naturalWidth / 1.5}px`;
        // image.style.height = `${this.naturalHeight / 1.5}px`;
      };
    });
  }
  // put it all together
  return [`<div class="blueprint">`, ...htmlFragments, "</div>"].join("");
};

// decode bluepringString and put info into container: HTMLDivElement
const processBlueprint = (blueprintString, container) => {
  try {
    let start = performance.now();
    console.log(
      `Decoding ${Math.round(
        blueprintString.length / 8192
      )} kB blueprint string`
    );
    const blueprintObject = decodeBlueprintString(blueprintString);
    console.log(`Decoded blueprint string in ${performance.now() - start} ms`);
    console.log(blueprintObject);
    const key = [...Object.keys(blueprintObject)][0];
    container.innerHTML = getBlueprintHTML(blueprintObject[key]);
  } catch (e) {
    const error = new Error().stack;
    container.innerHTML = `<pre>${error}</pre>`;
    throw e;
  }
};
