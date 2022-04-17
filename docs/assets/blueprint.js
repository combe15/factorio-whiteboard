const FBSR_SERVER = "https://fbsr.petal.org:5000";

// get path to assets/ folder from logo image src
const assetsPath =
  document
    .querySelector("img[alt='logo']")
    .getAttribute("src")
    .split("assets/")[0] + "assets";

// decode a blueprint string into a javascript object
const decodeBlueprint = (blueprintString) =>
  JSON.parse(
    pako.inflate(
      Uint8Array.from(atob(blueprintString.substr(1)), (c) => c.charCodeAt(0)),
      { to: "string" }
    )
  );

// encodes a javascript object into blueprint string format
const encodeBlueprint = (blueprintObject) => {
  const byteArray = pako.deflate(JSON.stringify(blueprintObject));
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

// convert [color=pink]text[/color] and [item=explosives] tags to html
const formatTags = (text) => {
  let formatted = text.replace(
    /\[color=(.+?)\](.+?)\[\/color\]/gm,
    `<span style="color:$1">$2</span>`
  );
  formatted = formatted.replace(/\[item=(.+?)\]/gm, (match, name) => {
    return getEntityIcon(name);
  });
  return formatted;
};

// internal name -> file name mapping
const itemToIconName = {
  "straight-rail": "rail",
  "electric-energy-interface": "accumulator",
  "stone-wall": "wall",
  "heat-exchanger": "heat-boiler",
  "infinity-pipe": "pipe",
  "signal-check": "checked-green",
  "signal-dot": "list-dot",
};

// get <img> for entity icons
const getEntityIcon = (name) => {
  let filename = name in itemToIconName ? itemToIconName[name] : name;
  let src = `${assetsPath}/factorio/icons/${filename}.png`;
  return `<img class="icon" src="${src}" loading="lazy" alt="${filename}">`;
};

// get <img> for blueprint icons
const getSignalIcon = (icon) => {
  let filename =
    icon.signal.name in itemToIconName
      ? itemToIconName[icon.signal.name]
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

// get bluepring preview image URL from hosted fbsr service
const getBlueprintImageUrl = async (blueprint) => {
  // make sure we use blueprint string instead of object
  const blueprintString =
    typeof blueprint === "string" || blueprint instanceof String
      ? blueprint
      : encodeBlueprint(blueprint);
  // post blueprint using JSON body
  const response = await fetch(`${FBSR_SERVER}/blueprint`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      blueprint: blueprintString,
    }),
  });
  // `data.name` is the SHA1 hash of the blueprint string
  const data = await response.json();
  return `${FBSR_SERVER}/cache/${data.name}.png`;
};

// get html representation of blueprint object
const getBlueprintHTML = (blueprint) => {
  const htmlFragments = [];
  // blueprint label with item image
  const iconImg = getSignalIcon({
    signal: { name: blueprint.item, type: "item" },
  });
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
          blueprint.label ? formatTags(blueprint.label) : ""
        }<span>
        </div>
    </div>`
  );
  // The CSS property `white-space: pre-line;` preserves newlines
  if ("description" in blueprint) {
    htmlFragments.push(
      `<div class="property-row">
        <!-- <div class="property-name">description</div> -->
        <div class="property-value" style="white-space: pre-line;">${formatTags(
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
    "position-relative-to-grid",
    "absolute-snapping",
  ]);
  customEntries.forEach(([key, val]) => {
    htmlFragments.push(
      `<div class="property-row">
        <div class="property-name">${key}</div>
        <div class="property-value">${val}</div>
      </div>`
    );
  });
  // entities count, collapsible
  if ("entities" in blueprint) {
    const entities = [];
    let totalCount = 0;
    const allEntities =
      "tiles" in blueprint
        ? [...blueprint.entities, ...blueprint.tiles]
        : blueprint.entities;
    const counts = getEntityCounts(allEntities);
    const maxCount = counts.reduce((acc, val) => {
      return acc > val[1] ? acc : val[1];
    }, 0);
    const digits = `${maxCount}`.length;
    const leftPad = (count) => `${count}`.padStart(digits, "\u00A0");
    counts.forEach(([name, count]) => {
      totalCount += count;
      entities.push(
        `<div class="entity-count">
          <span class="count">${leftPad(count)}</span>
          ${getEntityIcon(name)}
          <span class="label">${name}</span>
        </div>`
      );
    });
    htmlFragments.push(
      `<div class="property-row">
        <div class="property-value entities">${
          entities.length <= 5
            ? `<div class="entity-list">${entities.join("")}</div>`
            : `<div class="entity-list-toggle" onclick="this.nextElementSibling.style.display='block';this.style.display='none';">
            <div class="entity-count">
              <span class="count">${leftPad(totalCount)}</span>
              entities 
              <span class="show-on-hover">(click to expand)</span>
            </div>
          </div>
          <div class="entity-list" style="display:none">${entities.join(
            ""
          )}</div>`
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
        <div class="property-value" style="display: block">${blueprints.join(
          ""
        )}</div>
      </div>`
    );
  }
  // blueprint image preview
  if (blueprint.item === "blueprint") {
    const blueprintString = encodeBlueprint({ blueprint: blueprint });
    const uuid = uuidv4();
    htmlFragments.push(
      `<div class="property-row">
        <div id="${uuid}" style="padding: 0.3rem">
          <img class="blueprint-preview" alt="blueprint preview" loading="lazy" style="display: none;"/>
        </div>
      </div>`
    );
    getBlueprintImageUrl(blueprintString).then((url) => {
      window.setTimeout(() => {
        const div = document.getElementById(uuid);
        const img = document.createElement("img");
        img.src = url;
        img.setAttribute("loading", "lazy");
        img.style.display = "block";
        img.onload = function () {
          img.style.width = `${this.naturalWidth / 1.5}px`;
        };
        div.appendChild(img);
      }, 0);
    });
  }
  // put it all together
  return [`<div class="blueprint">`, ...htmlFragments, "</div>"].join("");
};

// decode bluepringString and put info into container: HTMLDivElement
const processBlueprint = (blueprintString, container) => {
  try {
    let start = performance.now();
    const blueprintObject = decodeBlueprint(blueprintString);
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
