"use strict";

const factorio = {};

factorio.FBSR_SERVER = "https://fbsr.petal.org";

// decode a blueprint string into a javascript object
factorio.decodeBlueprint = (blueprintString) =>
  JSON.parse(
    pako.inflate(
      Uint8Array.from(atob(blueprintString.substr(1)), (c) => c.charCodeAt(0)),
      { to: "string" }
    )
  );

// encodes a javascript object into blueprint string format
factorio.encodeBlueprint = (blueprintObject) => {
  const byteArray = pako.deflate(JSON.stringify(blueprintObject), { level: 9 });
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

// return pairs [name, count] for entities in list in descending order of count
factorio.getEntityCounts = (entities) => {
  const counter = {};
  entities.forEach((entity) => {
    counter[entity.name] =
      entity.name in counter ? counter[entity.name] + 1 : 1;
  });
  return [...Object.entries(counter)].sort((a, b) => b[1] - a[1]);
};

factorio.getBlueprintImageUrl = async (blueprint) => {
  // make sure we use blueprint string instead of object
  const blueprintString =
    typeof blueprint === "string" || blueprint instanceof String
      ? blueprint
      : factorio.encodeBlueprint(blueprint);
  function urlExists(url) {
    const http = new XMLHttpRequest();
    http.open('HEAD', url, false);
    http.send();
    return http.status === 200
  }
  const sha1hexdigest = factorio.sha1(blueprintString);
  const imageUrl = `${factorio.FBSR_SERVER}/cache/${sha1hexdigest}.png`;
  let imageUrlExists = false;
  try {
    imageUrlExists = urlExists(imageUrl);
  } catch(error) {
    imageUrlExists = false;
    console.log(error);
  }
  if (!imageUrlExists) {
    // post blueprint using JSON body
    const response = await fetch(`${factorio.FBSR_SERVER}/blueprint`, {
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
    console.assert(data.name === sha1hexdigest)
  }
  return imageUrl;
};

// internal name -> file name mapping
factorio.itemToIconName = {
  "straight-rail": "rail",
  "electric-energy-interface": "accumulator",
  "stone-wall": "wall",
  "heat-exchanger": "heat-boiler",
  "infinity-pipe": "pipe",
  "signal-check": "checked-green",
  "signal-dot": "list-dot",
};

// get <img> for entity icons
factorio.getEntityIcon = (name) => {
  const filename = name in factorio.itemToIconName ? factorio.itemToIconName[name] : name;
  const src = `${factorio.assetsPath}/factorio/icons/${filename}.png`;
  return `<img class="icon" src="${src}" loading="lazy" alt="${filename}">`;
};

// get <img> for blueprint icons
factorio.getSignalIcon = (icon) => {
  let filename =
    icon.signal.name in factorio.itemToIconName
      ? factorio.itemToIconName[icon.signal.name]
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
  const src = `${factorio.assetsPath}/factorio/icons/${filename}.png`;
  return `<img class="icon" src="${src}" loading="lazy" alt="[${icon.signal.type}=${icon.signal.name}]">`;
};

// convert [color=pink]text[/color] and [item=explosives] tags to html
factorio.formatString = (text) => {
  let formatted = text.replace(
    /\[color=(.+?)\](.+?)\[\/color\]/gm,
    `<span style="color:$1">$2</span>`
  );
  formatted = formatted.replace(/\[item=(.+?)\]/gm, (match, name) => {
    return factorio.getEntityIcon(name);
  });
  return formatted;
};

// get html representation of blueprint object (called recursively for books)
factorio.getBlueprintHTML = (blueprint) => {
  const htmlFragments = [];
  // blueprint label with item image
  const iconImg = factorio.getSignalIcon({
    signal: { name: blueprint.item, type: "item" },
  });
  const icons =
    "icons" in blueprint
      ? blueprint.icons.map((icon) => factorio.getSignalIcon(icon))
      : [];
  htmlFragments.push(
    `<div class="property-row">
      <div class="property-value" style="display:flex">
        <div class="label-icon">
          <div class="item-icon">${iconImg}</div>
          <div class="blueprint-icons icons-${icons.length}">${icons.join("")}</div>
        </div>
        <span class="blueprint-label">${blueprint.label ? factorio.formatString(blueprint.label) : ""}<span>
        </div>
    </div>`
  );
  // The CSS property `white-space: pre-line;` preserves newlines
  if ("description" in blueprint) {
    htmlFragments.push(
      `<div class="property-row">
        <!-- <div class="property-name">description</div> -->
        <div class="property-value" style="white-space: pre-line;">${factorio.formatString(
          blueprint.description.trim()
        )}</div>
      </div>`
    );
  }
  // The CSS property `white-space: pre-line;` preserves newlines
  if ("settings" in blueprint) {
    console.log(JSON.stringify(blueprint.settings, null, 2));
    const details = "entity_filters" in blueprint.settings 
      ? blueprint.settings.entity_filters.map(({name, index}) => factorio.getEntityIcon(name)).join("") 
      : blueprint.settings.mappers.map(({from, to}) => `${factorio.getEntityIcon(from.name)} &rarr; ${factorio.getEntityIcon(to.name)}`).join("<br />");
    htmlFragments.push(
      `<div class="property-row">
        <!-- <div class="property-name">settings</div> -->
        <div class="property-value" style="white-space: pre-line;">${details}</div>
      </div>`
    );
  }
  // entities count, collapsible
  if ("entities" in blueprint) {
    const entities = [];
    let totalCount = 0;
    const allEntities =
      "tiles" in blueprint
        ? [...blueprint.entities, ...blueprint.tiles]
        : blueprint.entities;
    const counts = factorio.getEntityCounts(allEntities);
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
          ${factorio.getEntityIcon(name)}
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
      return factorio.getBlueprintHTML(blueprintObject[key]);
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
    const blueprintString = factorio.encodeBlueprint({ blueprint: blueprint });
    const uuid = factorio.uuidv4();
    htmlFragments.push(
      `<div class="property-row">
        <div id="${uuid}" class="blueprint-preview" style="padding: 0.3rem">
          Fetching blueprint preview... ${factorio.loader}
        </div>
      </div>`
    );
    window.setTimeout(() => {
      factorio.getBlueprintImageUrl(blueprintString).then((url) => {
        const div = document.getElementById(uuid);
        div.innerHTML = '';
        const img = document.createElement("img");
        img.src = `${url}#${new Date().getTime()}`;
        img.setAttribute("loading", "lazy");
        img.style.display = "block";
        img.onload = function () {
          img.style.width = `${this.naturalWidth / 1.5}px`;
        };
        const a = document.createElement("a")
        a.href = img.src
        a.target="_blank";
        a.appendChild(img);
        div.appendChild(a);
      }).catch((error) => {
        const div = document.getElementById(uuid);
        div.style.whiteSpace = "pre-line";
        div.style.color = "organge";
        div.innerHTML = error.stack;
      });
      factorio.requestStagger += 150;
    }, factorio.requestStagger);
  }
  // put it all together
  return [`<div class="blueprint">`, ...htmlFragments, "</div>"].join("");
};

// generate unique ids for image placeholders
factorio.uuidv4 = () => ([1e7] + -1e3 + -4e3 + -8e3 + -1e11).replace(/[018]/g, (c) => (c ^ (crypto.getRandomValues(new Uint8Array(1))[0] & (15 >> (c / 4)))).toString(16));

// from https://gist.github.com/bellbind/18ff65781512151f53ed6eb093bac0f9
factorio.sha1 = (bluprintString) => {
  const hs = Array.from(Array(16), (_, i) => i.toString(16));
  const hsr = hs.slice().reverse();
  const h2s = hs.join("").match(/../g), h2sr = hsr.join("").match(/../g);
  const h2mix = hs.map((h, i) => `${hsr[i]}${h}`);
  const hseq = h2s.concat(h2sr, h2mix).map(hex => parseInt(hex, 16));
  const H = new Uint32Array(Uint8Array.from(hseq.slice(0, 20)).buffer);
  const K = Uint32Array.from(
    [2, 3, 5, 10], v => Math.floor(Math.sqrt(v) * (2 ** 30)));
  const F = [
    (b, c, d) => ((b & c) | ((~b >>> 0) & d)) >>> 0,
    (b, c, d) => b ^ c ^ d,
    (b, c, d) => (b & c) | (b & d) | (c & d),
    (b, c, d) => b ^ c ^ d,
  ];
  function rotl(v, n) {
    return ((v << n) | (v >>> (32 - n))) >>> 0;
  }
  function sha1(buffer) {
    const u8a = ArrayBuffer.isView(buffer) ?
      new Uint8Array(buffer.buffer, buffer.byteOffset, buffer.byteLength) :
      new Uint8Array(buffer);
    const total = Math.ceil((u8a.length + 9) / 64) * 64;
    const chunks = new Uint8Array(total);
    chunks.set(u8a);
    chunks.fill(0, u8a.length);
    chunks[u8a.length] = 0x80;
    const lenbuf = new DataView(chunks.buffer, total - 8);
    const low = u8a.length % (1 << 29);
    const high = (u8a.length - low) / (1 << 29);
    lenbuf.setUint32(0, high, false);
    lenbuf.setUint32(4, low << 3, false);
    const hash = H.slice();
    const w = new Uint32Array(80);
    for (let offs = 0; offs < total; offs += 64) {
      const chunk = new DataView(chunks.buffer, offs, 64);
      for (let i = 0; i < 16; i++) w[i] = chunk.getUint32(i * 4, false);
      for (let i = 16; i < 80; i++) {
        w[i] = rotl(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
      }
      let [a, b, c, d, e] = hash;
      for (let s = 0; s < 4; s++) {
        for (let i = s * 20, end = i + 20; i < end; i++) {
          const ne = rotl(a, 5) + F[s](b, c, d) + e + K[s] + w[i];
          [a, b, c, d, e] = [ne >>> 0, a, rotl(b, 30), c, d];
        }
      }
      hash[0] += a; hash[1] += b; hash[2] += c; hash[3] += d; hash[4] += e;
    }
    const digest = new DataView(new ArrayBuffer(20));
    hash.forEach((v, i) => digest.setUint32(i * 4, v, false));
    return digest.buffer;
  }
  const digest = sha1(Uint8Array.from(bluprintString, c => c.charCodeAt(0)));
  const hexDigest = Array.prototype.map.call(new Uint8Array(digest), x => ('00' + x.toString(16)).slice(-2)).join('');
  return hexDigest;
}

factorio.loader=`<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" style="margin: auto; background: transparent; display: inline-block;vertical-align:middle;" width="18px" height="18px" viewBox="0 0 100 100" preserveAspectRatio="xMidYMid">
  <g transform="translate(50 50)">
  <g>
  <animateTransform attributeName="transform" type="rotate" values="0;45" keyTimes="0;1" dur="0.2s" repeatCount="indefinite"></animateTransform><path d="M29.491524206117255 -5.5 L37.491524206117255 -5.5 L37.491524206117255 5.5 L29.491524206117255 5.5 A30 30 0 0 1 24.742744050198738 16.964569457146712 L24.742744050198738 16.964569457146712 L30.399598299691117 22.621423706639092 L22.621423706639096 30.399598299691114 L16.964569457146716 24.742744050198734 A30 30 0 0 1 5.5 29.491524206117255 L5.5 29.491524206117255 L5.5 37.491524206117255 L-5.499999999999997 37.491524206117255 L-5.499999999999997 29.491524206117255 A30 30 0 0 1 -16.964569457146705 24.742744050198738 L-16.964569457146705 24.742744050198738 L-22.621423706639085 30.399598299691117 L-30.399598299691117 22.621423706639092 L-24.742744050198738 16.964569457146712 A30 30 0 0 1 -29.491524206117255 5.500000000000009 L-29.491524206117255 5.500000000000009 L-37.491524206117255 5.50000000000001 L-37.491524206117255 -5.500000000000001 L-29.491524206117255 -5.500000000000002 A30 30 0 0 1 -24.742744050198738 -16.964569457146705 L-24.742744050198738 -16.964569457146705 L-30.399598299691117 -22.621423706639085 L-22.621423706639092 -30.399598299691117 L-16.964569457146712 -24.742744050198738 A30 30 0 0 1 -5.500000000000011 -29.491524206117255 L-5.500000000000011 -29.491524206117255 L-5.500000000000012 -37.491524206117255 L5.499999999999998 -37.491524206117255 L5.5 -29.491524206117255 A30 30 0 0 1 16.964569457146702 -24.74274405019874 L16.964569457146702 -24.74274405019874 L22.62142370663908 -30.39959829969112 L30.399598299691117 -22.6214237066391 L24.742744050198738 -16.964569457146716 A30 30 0 0 1 29.491524206117255 -5.500000000000013 M0 -20A20 20 0 1 0 0 20 A20 20 0 1 0 0 -20" fill="#ec9312"></path></g></g>
  </svg>`;
