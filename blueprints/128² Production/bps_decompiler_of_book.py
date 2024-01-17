import argparse
from pathlib import Path
from bp_from_json import blueprint
import json


# ====================================
def get_script_dir():
    return Path(__file__).parent.resolve()


# ====================================
def get_current_working_directory():
    return Path().resolve()


# ====================================
def init_parser():
    parser = argparse.ArgumentParser(
        description=(
            "the decompiler of the book"
            'For example: bps_decompiler_of_book.py -b="bp-file"'
        )
    )
    parser.add_argument(
        "-b",
        "--blueprint",
        type=str,
        default="",
        help=('(IN) Blueprint file. Default = "bp.txt"'),
    )
    return parser


# ====================================
#
# main
if __name__ == "__main__":
    args = init_parser().parse_args()

    if args.blueprint:
        book = blueprint.from_file(args.blueprint)
    else:
        book = blueprint.from_file("bp.txt")

    if not book.is_blueprint_book():
        raise Exception("The script only works with books")
    else:
        makefile = {}
        makefile["label"] = "name {}"
        makefile["version"] = "1.38"
        makefile["summary_of_book"] = book.summary_of_book().obj
        makefile["indexes"] = {}

        for bp in book.read_blueprints():
            bp = blueprint(bp)
            index = bp.data.get("index", None)
            if index is None:
                raise Exception("bad index")
            else:
                filename = "bp_index_{}.bin".format(index)
                makefile["indexes"][index] = {
                    "filename": filename,
                    "label": bp.read_label(),
                    "description": bp.read_description(),
                }
                bp.to_file(filename)

        with open("makefile_bps.json", "w", encoding="utf8") as f:
            json_str = json.dumps(makefile, indent=4, ensure_ascii=False)
            print(json_str, file=f)
