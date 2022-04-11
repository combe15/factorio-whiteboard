const decodeBlueprintString = (blueprintString) => {
  return JSON.parse(
    pako.inflate(
      Uint8Array.from(atob(blueprintString.substr(1)), (c) => c.charCodeAt(0)),
      { to: "string" }
    )
  );
};

const encodeBlueprintString = (blueprintObject) => {
  return (
    "0" +
    btoa(String.fromCharCode(...pako.deflate(JSON.stringify(blueprintObject))))
  );
};

const getCustomEntries = (obj, defaultDenyList = []) => {
  const denyList = new Set([
    ...defaultDenyList,
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
  const keys = [...Object.keys(obj)].filter((key) => !denyList.has(key));
  // return Object.fromEntries(keys.map((key) => [key, obj[key]]));
  return keys.map((key) => {
    const value =
      typeof obj[key] === "string" || obj[key] instanceof String
        ? obj[key]
        : JSON.stringify(obj[key]);
    return [key, value];
  });
};

const getIconImg = (icon, assetsPath) => {
  let src = `${assetsPath}/factorio/icons/${icon.signal.name}.png`;
  if (icon.signal.type === "virtual") {
    src = `${assetsPath}/factorio/icons/signal/${icon.signal.name.replace(
      "-",
      "_"
    )}.png`;
  }
  if (icon.signal.name === "signal-check") {
    src = `${assetsPath}/factorio/icons/checked-green.png`;
  }
  return `<img class="icon" src="${src}" alt="[${icon.signal.type}=${icon.signal.name}]">`;
};

const getBlueprintHTML = (blueprint) => {
  const htmlFragments = [];
  const assetsPath =
    document
      .querySelector("img[alt='logo']")
      .getAttribute("src")
      .split("assets/")[0] + "assets";
  // if ("item" in blueprint) {
  //   htmlFragments.push(
  //     `<div class="property-row"><div class="property-name">item</div><div class="property-value">${blueprint.item}</div></div>`
  //   );
  // }
  if ("label" in blueprint) {
    const icon = { signal: { name: blueprint.item, type: "item" } };
    const iconImg = getIconImg(icon, assetsPath);
    htmlFragments.push(
      `<div class="property-row"><div class="property-name">label</div><div class="property-value">${iconImg} ${blueprint.label}</div></div>`
    );
  }
  if ("icons" in blueprint) {
    const icons = blueprint.icons.map((icon) => getIconImg(icon, assetsPath));
    htmlFragments.push(
      `<div class="property-row"><div class="property-name">icons</div><div class="property-value">${icons.join(
        ""
      )}</div></div>`
    );
  }
  if ("description" in blueprint) {
    htmlFragments.push(
      `<div class="property-row"><div class="property-name">description</div><div class="property-value">${blueprint.description}</div></div>`
    );
  }
  const customEntries = getCustomEntries(blueprint);
  customEntries.forEach(([key, val]) => {
    htmlFragments.push(
      `<div class="property-row"><div class="property-name">${key}</div><div class="property-value">${val}</div></div>`
    );
  });
  if ("blueprints" in blueprint) {
    const blueprints = blueprint.blueprints.map((blueprintObject) => {
      const key = [...Object.keys(blueprintObject)][0];
      return getBlueprintHTML(blueprintObject[key]);
    });
    htmlFragments.push(
      `<div class="property-row"><div class="property-name">blueprints</div><div class="property-value blueprints">${blueprints.join(
        ""
      )}</div></div>`
    );
  }
  return [`<div class="blueprint">`, ...htmlFragments, "</div>"].join("");
};

const processBlueprint = (blueprintString, container) => {
  const blueprintObject = decodeBlueprintString(blueprintString);
  console.log(blueprintObject);
  const key = [...Object.keys(blueprintObject)][0];
  container.innerHTML = getBlueprintHTML(blueprintObject[key]);
};
