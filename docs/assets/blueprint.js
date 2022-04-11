// decodes a blueprint string into a javascript object
const decodeBlueprintString = (blueprintString) =>
  JSON.parse(
    pako.inflate(
      Uint8Array.from(atob(blueprintString.substr(1)), (c) => c.charCodeAt(0)),
      { to: "string" }
    )
  );

// encodes a javascript object into the factorio blueprint string
const encodeBlueprintString = (blueprintObject) =>
  "0" +
  btoa(String.fromCharCode(...pako.deflate(JSON.stringify(blueprintObject))));

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

const remapping = {
  "straight-rail": "rail",
  "electric-energy-interface": "accumulator",
  "stone-wall": "wall",
  "heat-exchanger": "heat-boiler",
  "infinity-pipe": "pipe",
};

// get <img> html for entity icons
const getEntityIcon = (name, assetsPath) => {
  let filename = name in remapping ? remapping[name] : name;
  let src = `${assetsPath}/factorio/icons/${filename}.png`;
  return `<img class="icon" src="${src}" alt="${filename}">`;
};

// get <img> html for blueprint icons
const getSignalIcon = (icon, assetsPath) => {
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
  return `<img class="icon" src="${src}" alt="[${icon.signal.type}=${icon.signal.name}]">`;
};

// get html representation of blueprint object
const getBlueprintHTML = (blueprint) => {
  // assemble html as array instead of using string concatenation for performance
  const htmlFragments = [];
  // get base path to assets for icons etc.
  const assetsPath =
    document
      .querySelector("img[alt='logo']") // assumes that the logo is an image located in docs/assets/
      .getAttribute("src")
      .split("assets/")[0] + "assets";
  // blueprint label with item image
  const icon = { signal: { name: blueprint.item, type: "item" } };
  const iconImg = getSignalIcon(icon, assetsPath);
  htmlFragments.push(
    `<div class="property-row">
      <div class="property-name">label</div>
      <div class="property-value">${iconImg} ${
      blueprint.label ? blueprint.label : ""
    }</div>
    </div>`
  );
  // display blueprint.icons as list of images
  if ("icons" in blueprint) {
    const icons = blueprint.icons.map((icon) =>
      getSignalIcon(icon, assetsPath)
    );
    htmlFragments.push(
      `<div class="property-row">
        <div class="property-name">icons</div>
        <div class="property-value">${icons.join("")}</div>
      </div>`
    );
  }
  // The CSS property `white-space: pre-line;` preserves newlines
  // so we don't need to replace "\n" with <br />
  if ("description" in blueprint) {
    htmlFragments.push(
      `<div class="property-row">
        <div class="property-name">description</div>
        <div class="property-value" style="white-space: pre-line;">${blueprint.description.trim()}</div>
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
    const maxCount = 0;
    counts.forEach((count) => {
      if (count > maxCount) maxCount = count;
    });
    const digits = `${maxCount}`.length;
    counts.forEach(([name, count]) => {
      totalCount += count;
      const paddedCount = `${count}`.padStart(digits, "\u00A0");
      const icon = getEntityIcon(name, assetsPath);
      entities.push(
        `<div class="entity-count"><span class="count">${paddedCount}</span>${icon}<span class="label">${name}</span></div>`
      );
    });
    const noCollapse = entities.join("");
    const paddedTotalCount = `${totalCount}`.padStart(digits, "\u00A0");
    const collapse = `<div class="entity-list-toggle" onclick="this.nextElementSibling.style.display='block';this.style.display='none';">
      <div class="entity-count">
        <span class="count">${paddedTotalCount}</span> entities
      </div>
    </div>
    <div class="entity-list" style="display:none">${noCollapse}</div>`;
    htmlFragments.push(
      `<div class="property-row">
        <div class="property-name">entities</div>
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
        <div class="property-name">blueprints</div>
        <div class="property-value" style="display: block">${blueprints.join(
          ""
        )}</div>
      </div>`
    );
  }
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
