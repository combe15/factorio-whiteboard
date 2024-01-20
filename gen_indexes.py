import os
import time
from glob import glob
from collections import namedtuple

import mkdocs_gen_files  # pip install mkdocs-gen-files


def process_lua():
    """
    For each .lua files in the ./lua/ folder
    Create a markdown file in docs/lua_scripts/{script_name}.md
    """
    start_time = time.time()
    files = glob("./lua/*.lua")
    for path in files:
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
    print("Processed %s scripts in %0.3fs" % (len(files), time.time() - start_time))


def process_blueprints():
    """
    For each ./blueprints/ folder
    It will create a markdown file in docs/blueprints/{script_name}.md
    """
    start_time = time.time()
    # files = glob("./blueprints/*")
    # I don't know how to add directories correctly, so directories are ignored @flameSla
    files = [file for file in glob("./blueprints/*") if os.path.isfile(file)]
    for path in files:
        print(f"Processing {path}")
        basename = os.path.basename(path)
        with open(path) as f:
            contents = f.read().strip()
        filename = f"blueprints/{basename}.md"
        with mkdocs_gen_files.open(f"blueprints/{basename}.txt", "w") as f:
            print(contents, file=f)
        with mkdocs_gen_files.open(filename, "w") as f:
            print(f'```txt title="{path}"\n', file=f)
            # print(contents, file=f)
            print(f"\n```\n", file=f)
            # container and script for client-side blueprint string processing
            print(
                f"""<div id="blueprintContainer">Processing blueprint string ...</div>
                <script>
                if (typeof processBlueprint === "undefined") {{ 
                    window.addEventListener('load', (event) => {{
                        processBlueprint(`{basename}`, document.getElementById("blueprintContainer"));
                    }});
                }} else {{ 
                    processBlueprint(`{basename}`, document.getElementById("blueprintContainer")); 
                }}
                </script>""".replace(
                    "    ", ""
                ),  # replace whitespace to avoid markdown treating it as code block
                file=f,
            )
        mkdocs_gen_files.set_edit_path(filename, path)
    print("Processed %s blueprints in %0.3fs" % (len(files), time.time() - start_time))


process_lua()
process_blueprints()
