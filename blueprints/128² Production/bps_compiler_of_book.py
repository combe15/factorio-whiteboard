import argparse
from pathlib import Path
from bp_from_json import blueprint
import json
import hashlib


# ====================================
def get_script_dir():
    return Path(__file__).parent.resolve()


# ====================================
def get_current_working_directory():
    return Path().resolve()


# ====================================
def get_md5(filename):
    with open(filename, "rb") as f:
        file_hash = hashlib.md5()
        while chunk := f.read(8192):
            file_hash.update(chunk)
        return file_hash.hexdigest()


# ====================================
def get_md5_for_files():
    result = {}
    for file in get_current_working_directory().iterdir():
        if file.is_file():
            # print("file.name = ", type(file.name), file.name)
            if file.name != "history" and file.suffix != ".out":
                result[file.name] = get_md5(file)
    return result


def get_filename(filename):
    files = tuple(get_current_working_directory().glob(filename))
    # print("files = ", type(files), files)
    if len(files) == 0:
        raise Exception("ERROR!!!  '{}' the file was not found ".format(filename))
    elif len(files) == 1:
        return files[0]
    else:
        print()
        print("Warning! Several files found!")
        for file in files:
            print("  {}".format(file.name))
        print()
        result = sorted(files, reverse=True)[0]
        print("  the file is selected - '{}'".format(result))
        print()

        return result


# ====================================
def init_parser():
    parser = argparse.ArgumentParser(
        description=(
            "the compiler of the book"
            'For example: bps_compiler_of_book.py -m="makefile_bps" -b="out-bp"'
        )
    )
    parser.add_argument(
        "-m",
        "--makefile_bps",
        type=str,
        default="",
        help=('(IN) makefile for the book. Default = "makefile_bps.json"'),
    )
    parser.add_argument(
        "-b",
        "--blueprint",
        type=str,
        default="",
        help=('(OUT) Blueprint file. Default = "bp_compiler_out.txt"'),
    )
    return parser


######################################
#
# main
if __name__ == "__main__":
    args = init_parser().parse_args()

    if args.makefile_bps:
        makefile_bps = args.makefile_bps
    else:
        makefile_bps = "makefile_bps.json"

    if args.blueprint:
        output_file = args.blueprint
    else:
        output_file = "bp_compiler_out.txt"

    history = {}
    try:
        history = json.load(Path("history").open(encoding="utf8"))
    except Exception:
        history["minor"] = -1
        history["files"] = {}

    files1 = get_md5_for_files()
    if files1 == history["files"]:
        print("The files have not changed, the project is not being built.")
    else:
        makefile_json = json.load(Path(makefile_bps).open(encoding="utf8"))

        history["minor"] += 1
        history["files"] = files1

        ver = "{}.{}".format(makefile_json["version"], history["minor"])

        # delete an old file
        old_file_name = history.get("old_file_name", output_file)
        Path(old_file_name).unlink(missing_ok=True)

        # new file name
        output_file = Path(output_file)
        output_file = output_file.with_stem("{}_v{}".format(output_file.stem, ver))
        history["old_file_name"] = str(output_file)

        with open("history", "w", encoding="utf8") as f:
            json_str = json.dumps(history, indent=4, ensure_ascii=False)
            print(json_str, file=f)

        # print(makefile_json["summary_of_book"])
        # print(makefile_json["indexes"])

        book = blueprint.new_blueprint_book()
        for key, value in makefile_json["summary_of_book"].items():
            book.obj[key] = value

        label = makefile_json["label"].format(ver)
        book.set_label(label)

        for index, val in makefile_json["indexes"].items():
            filename = get_filename(val["filename"])
            print("    index={:03d} <- file added '{}'".format(int(index), filename))
            bp = blueprint.from_file(filename)
            book.append_bp(bp, index)

        book.to_file(output_file)
        print("the book is saved: {}".format(output_file))
