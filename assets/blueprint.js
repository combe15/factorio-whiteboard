// decode blueprintString and put info into container: HTMLDivElement
const processBlueprint = (blueprintName, container) => {
  container.innerHTML = `Processing blueprint string ${factorio.loader}`;
  const url = `../${blueprintName}.txt`;
  fetch(url)
  .then(function(response) {
    response.text().then((text) => {
      const blueprintString = text.trim();
      document.querySelector(".highlight pre").querySelector("code").innerHTML = blueprintString;
      try {
        // get path to assets/ folder from logo image src
        factorio.assetsPath = document
          .querySelector("img[alt='logo']")
          .getAttribute("src")
          .split("assets/")[0] + "assets"; 
        const blueprintObject = factorio.decodeBlueprint(blueprintString);
        console.log(blueprintObject);
        const key = [...Object.keys(blueprintObject)][0];
        factorio.requestStagger = 0;
        container.innerHTML = factorio.getBlueprintHTML(blueprintObject[key]);
      } catch (e) {
        const error = new Error().stack;
        container.innerHTML = `<pre>${error}</pre>`;
        throw e;
      }
    });
  });
};
