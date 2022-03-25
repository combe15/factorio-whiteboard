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


item_types = {
    "blueprint",
    "blueprint_book",
    "deconstruction_planner",
    "upgrade_planner",
}


def decode(bp: str) -> Optional[Dict]:
    """Parses factorio blueprint string into a python dictionary

    See https://wiki.factorio.com/Blueprint_string_format

    Args:
        bp (str): The blueprint string

    Returns:
        Optional[Dict]: Returns None if exception
    """
    try:
        if bp[0] != "0":
            return None
        return json.loads(zlib.decompress(base64.b64decode(bp[1:])))
    except:
        return None


def get_item_info(bp_dict: Dict) -> Optional[Dict]:
    if bp_dict is None:
        return None
    item_type = None
    for it in item_types:
        if it in bp_dict:
            item_type = it
            break
    if item_type is None:
        print(f"Unknown item type: ${item_type}")
        return None
    item = bp_dict[item_type]
    label = item.get("label", "")
    description = item.get("description", "")
    children = []
    if item_type == "blueprint_book":
        children = [get_item_info(bp) for bp in item.get("blueprints", [])]
    return {
        "item_type": item_type,
        "label": label,
        "description": description,
        "children": children,
    }


icons = {
    "blueprint": "📄",
    "blueprint_book": "📘",
    "deconstruction_planner": "🟥",
    "upgrade_planner": "🟩",
}


def process_blueprints():
    """
    For each ./blueprints/ folder
    It will create a markdown file in docs/blueprints/{script_name}.md
    """
    for path in glob("./blueprints/*"):
        print(f"Processing {path}")
        basename = os.path.basename(path)
        with open(path) as f:
            contents = f.read()
        filename = f"blueprints/{basename}.md"
        with mkdocs_gen_files.open(filename, "w") as f:
            bp_dict = decode(contents)
            bp = get_item_info(bp_dict)

            if bp is None:
                # display call-out https://squidfunk.github.io/mkdocs-material/reference/admonitions/
                print(
                    "!!! fail\n    \nAn error occurred when parsing the blueprint string\n",
                    file=f,
                )
                # display blueprint string in code block
                print(f"### Blueprint string\n", file=f)
                print(f'```txt title="{path}"\n', file=f)
                print(contents, file=f)
                print(f"\n```\n", file=f)
                continue

            # Use blueprint label as page title if available
            if bp["label"] != "":
                icon = icons.get(bp["item_type"], "")
                print(f"# {icon} {bp['label']}\n", file=f)

            # display blueprint string in code block
            print(f"### Blueprint string {{ data-search-exclude }}\n", file=f)
            print(f'```txt title="{path}"\n', file=f)
            print(contents, file=f)
            print(f"\n```\n", file=f)

            if bp["description"] != "":
                print(f"### Description \n", file=f)
                print(f"```\n", file=f)
                print(bp["description"], file=f)
                print(f"\n```\n", file=f)

            def child_str(child):
                label = f"{icons.get(child['item_type'],'')} {child.get('label')}"
                description = ""
                if child.get("description"):
                    description = "\n\n" + child.get("description")
                return f"```\n{label}{description}\n```\n"

            if len(bp["children"]) > 0:
                print(f"### Children \n", file=f)
                for child in bp["children"]:
                    # print(f"<pre>\n", file=f)
                    print(child_str(child), file=f)
                    # print(f"\n</pre>\n", file=f)

        mkdocs_gen_files.set_edit_path(filename, path)


process_lua()
process_blueprints()
print(f"Done processing")
