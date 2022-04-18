# Blueprints

Blueprint pages are automatically created by the `gen_indexes.py` script.

To add a new blueprint, create a file containing the blueprint string in the `blueprints/` directory.

## How blueprint pages work

1. The mkdocs-gen-files script creates a page stub in `docs/blueprints/{basename}.md` and also copies the blueprint string to the static assets as a text file `doc/assets/{basename}.txt`
1. The stub document has an empty code fence for the blueprint string and an embedded `<script>` that calls `processBlueprint(basename)` which is a function defined in `docs/assets/blueprint.js`. 
1. The script also populates code fence with the blueprint string which is fetched from `doc/assets/{basename}.txt` using an XMLHttpRequest after the page is loaded. 
1. The `processBlueprint()` function deserializes the blueprint string and renders the html representation of the blueprint data.
1. Blueprint previews are left as image stubs with a `window.setTimeout()` function that staggers requests to the blueprint preview server to fetch image data, defined in `doc/assets/factorio.js` as the constant `FBSR_SERVER`.

