import json
import os
from glob import glob
import base64
from typing import Dict, Optional
import zlib
from collections import namedtuple

import mkdocs_gen_files  # pip install mkdocs-gen-files


def process_lua():
    """
    For each .lua files in the ./lua/ folder
    Create a markdown file in docs/lua_scripts/{script_name}.md
    """
    for path in glob("./lua/*.lua"):
        print(f"Processing {path}")
        basename = os.path.basename(path)
        with open(path) as f:
            contents = f.read()
        script_name = basename.split(".lua")[0]
        filename = f"lua_scripts/{script_name}.md"
        with mkdocs_gen_files.open(filename, "w") as f:
            print(f'```lua title="{path}"\n', file=f)
            print(contents, file=f)
            print(f"\n```\n", file=f)
        mkdocs_gen_files.set_edit_path(filename, path)


def process_blueprints():
    """
    For each ./blueprints/ folder
    It will create a markdown file in docs/blueprints/{script_name}.md
    """
    for path in glob("./blueprints/*"):
        print(f"Processing {path}")
        basename = os.path.basename(path)
        with open(path) as f:
            contents = f.read().strip()
        filename = f"blueprints/{basename}.md"
        with mkdocs_gen_files.open(filename, "w") as f:
            # display blueprint string in code block
            print(f"### Blueprint string\n", file=f)
            print(f'```txt title="{path}"\n', file=f)
            print(contents, file=f)
            print(f"\n```\n", file=f)
            print(
                f"""<div id="blueprintContainer">
                Processing blueprint string ...
                </div>
                <script>
                window.blueprint = `{contents}`;
                if (typeof processBlueprint === "undefined") {{ 
                    window.addEventListener('load', (event) => {{
                        processBlueprint(window.blueprint, document.getElementById("blueprintContainer"));
                    }});
                }} else {{ 
                    processBlueprint(window.blueprint, document.getElementById("blueprintContainer")); 
                }}
                </script>""".replace(
                    "    ", ""
                ),
                file=f,
            )
        mkdocs_gen_files.set_edit_path(filename, path)


process_lua()
process_blueprints()
print(f"Done processing")
