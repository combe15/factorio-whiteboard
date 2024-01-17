import base64
import collections
import copy
import hashlib
import json
import math
import zlib
from fractions import Fraction
from pathlib import Path


#############################################
def input_def(text, default):
    str = input(text + "[" + default + "]:")
    return str if str else default


def get_blueprint(text, default):
    exchange_str = input_def(text, default)
    if Path(exchange_str).exists():
        with open(exchange_str, "r") as f:
            exchange_str = f.read()

    return blueprint.from_string(exchange_str)


#############################################
class position:
    def __init__(self, obj):
        self.data = obj

    @classmethod
    def new_position(cls, x, y):
        return cls({"x": x, "y": y})

    @classmethod
    def from_dict(cls, d):
        return cls(d)

    def __packing_numbers(self, a):
        """100.0 -> 100(int)"""
        """ 100.1 -> 100.1    """
        fractional, integer = math.modf(a)
        if fractional == 0:
            return int(integer)
        else:
            return a

    def __packing_pos(self):
        """100.0 -> 100(int)"""
        """ 100.1 -> 100.1    """
        self.data["x"] = self.__packing_numbers(self.data["x"])
        self.data["y"] = self.__packing_numbers(self.data["y"])

    def __iadd__(self, other):
        self.data["x"] += other.data["x"]
        self.data["y"] += other.data["y"]
        self.__packing_pos()
        return self

    def __isub__(self, other):
        self.data["x"] -= other.data["x"]
        self.data["y"] -= other.data["y"]
        self.__packing_pos()
        return self

    def rotate(self, cent_x, cent_y, angle_degrees):
        cent = position.new_position(cent_x, cent_y)
        self -= cent

        angle_radians = angle_degrees * math.pi / 180.0
        x = self.data["x"] * math.cos(angle_radians) - self.data["y"] * math.sin(
            angle_radians
        )
        y = self.data["x"] * math.sin(angle_radians) + self.data["y"] * math.cos(
            angle_radians
        )

        self.data["x"] = x
        self.data["x"] = y
        self += cent
        self.__packing_pos()

    def __str__(self):
        return "{{'x': {0}, 'y': {1}}}".format(self.data["x"], self.data["y"])

    def read_x(self):
        return self.data["x"]

    def read_y(self):
        return self.data["y"]

    def get_tuple(self):
        return tuple((self.data["x"], self.data["y"]))


#############################################
entity_required_parameters = {"entity_number": int, "name": str, "position": dict}

entity_optional_parameters = {
    "direction": int,
    "orientation": float,
    "connections": dict,
    # 'circuit_condition': dict,
    "neighbours": list,
    "control_behavior": dict,
    "items": dict,
    "recipe": str,
    "bar": int,
    "inventory": dict,
    "infinity_settings": dict,
    # 'type': ?,
    # 'input_priority': ?,
    # 'output_priority': ?,
    # 'filter': ?,
    "filters": list,
    # 'filter_mode': ?,
    # 'override_stack_size': ?,
    # 'drop_position': ?,
    # 'pickup_position': ?,
    "request_filters": list,
    "request_from_buffers": str,
    # 'parameters': ?,
    # 'alert_parameters': ?,
    # 'auto_launch': ?,
    # 'variation': ?,
    "color": dict,
    "station": str,
}

entity_may_contain_items = (
    "artillery-turret",
    "artillery-wagon",
    "assembling-machine-1",
    "assembling-machine-2",
    "assembling-machine-3",
    "beacon",
    "boiler",
    "burner-inserter",
    "burner-mining-drill",
    "cargo-wagon",
    "centrifuge",
    "chemical-plant",
    "electric-furnace",
    "electric-mining-drill",
    "gun-turret",
    "iron-chest",
    "lab",
    "locomotive",
    "nuclear-reactor",
    "oil-refinery",
    "pumpjack",
    "roboport",
    "rocket-silo",
    "steel-chest",
    "steel-furnace",
    "stone-furnace",
    "wooden-chest",
)


class entity:
    def __init__(self, obj):
        self.data = obj

    @classmethod
    def new_entity(cls, name, pos_x, pos_y, direction=None, orientation=None):
        entity = dict()
        entity["entity_number"] = 0
        entity["name"] = name
        entity["position"] = position.new_position(pos_x, pos_y).data
        if direction is not None:
            entity["direction"] = direction
        if orientation is not None:
            entity["orientation"] = orientation
        return cls(entity)

    def __eq__(self, other):
        a = self.data.copy()
        b = other.data.copy()
        a["entity_number"] = 0
        b["entity_number"] = 0
        return a == b

    # -------------------------------------
    #   append_

    def append_request_filters(self, filtr):
        if "request_filters" not in self.data:
            self.data["request_filters"] = list()
        self.data["request_filters"].append(filtr)

    # -------------------------------------
    #   get_

    def get_pos(self):
        return position(self.data["position"])

    # -------------------------------------
    #   set_

    def set(self, param, val):
        if not isinstance(param, str):
            print(f"{type(param)} - instead of a string")
            raise AttributeError
        else:
            if param in entity_required_parameters:
                if not isinstance(val, entity_required_parameters[param]):
                    print(
                        f"{type(val)} - instead of a"
                        f' "{entity_required_parameters[param]}"'
                    )
                    raise AttributeError
                else:
                    self.data[param] = val

            # optional parameters
            elif param in entity_optional_parameters:
                if not isinstance(val, entity_optional_parameters[param]):
                    print(
                        f"{type(val)} - instead of a"
                        f'"{entity_optional_parameters[param]}"'
                    )
                    raise AttributeError
                else:
                    self.data[param] = val

            else:
                print(f'Warning! "{param}" - there is no such parameter')
                raise AttributeError

    def set_entity_number(self, val):
        self.set("entity_number", val)

    def set_name(self, val):
        self.set("name", val)

    def set_position(self, val):
        self.set("position", val)

    def set_request_from_buffers(self, val):
        self.set("request_from_buffers", val)

    def set_station(self, val):
        self.set("station", val)

    def set_inventory_filter(self, filtr):
        if "inventory" not in self.data:
            self.data["inventory"] = dict()

        if "filters" not in self.data["inventory"]:
            self.data["inventory"]["filters"] = list()

        self.data["inventory"]["filters"].append(filtr)

    def set_inventory_bar(self, val):
        if "inventory" not in self.data:
            self.data["inventory"] = dict()
        self.data["inventory"]["bar"] = val

    # -------------------------------------
    #   read_

    def read(self, param):
        if not isinstance(param, str):
            print(f"{type(param)} - instead of a string")
            raise AttributeError
        else:
            if param in entity_required_parameters:
                return self.data[param]

            # optional parameters
            elif param in entity_optional_parameters:
                return self.data.get(param, entity_optional_parameters[param]())

            else:
                print(f'Warning! "{param}" - there is no such parameter')
                raise AttributeError

    def read_name(self):
        return self.read("name")

    def read_entity_number(self):
        return self.read("entity_number")

    def read_items(self):
        return self.read("items")

    def read_recipe(self):
        return self.read("recipe")

    # -------------------------------------
    #   update

    def update_items(self, item, name_verification=True):
        if self.data["name"] in entity_may_contain_items or name_verification is False:
            if "items" in self.data:
                self.data["items"].update(item)
            else:
                self.data["items"] = item
        else:
            print(f"Warning! '{self.data['name']}' cannot contain items")


#############################################
def print_id(s, a):
    print("{0:32} {1:20} {2:20} {3}".format(s, hex(id(a)), str(a), type(a)))


#############################################
def get_recipes_with_one_product(name_of_the_json_file=None):
    if name_of_the_json_file is None:
        name_of_the_json_file = "Factorio 1.1 Vanilla.json"
    # read json file
    with open(name_of_the_json_file, "r", encoding="utf8") as read_file:
        json_all = json.load(read_file)

    # json -> dist()
    recipes = dict()
    names = []
    for recipe in json_all["recipes"]:
        names.append(recipe["name"])
        if len(recipe["products"]) == 1:
            # print()
            # print("==================")
            # print()
            # print(recipe)
            if recipe["products"][0]["amount"] != 0:
                for ingredient in recipe["ingredients"]:
                    if isinstance(ingredient["amount"], int):
                        ingredient["amount"] = Fraction(
                            ingredient["amount"], recipe["products"][0]["amount"]
                        )
                    elif isinstance(ingredient["amount"], float):
                        ingredient["amount"] = Fraction(
                            ingredient["amount"]
                        ) / Fraction(recipe["products"][0]["amount"], 1)
                    else:
                        raise Exception(
                            "unknown type = " + str(type(ingredient["amount"]))
                        )
            recipes[recipe["name"]] = {
                "ingredients": recipe["ingredients"],
                "product": recipe["products"][0]["name"],
            }
            n1 = recipe["name"]
            n2 = recipe["products"][0]["name"]
            if n1 != n2:
                print()
                print("ATTENTION")
                print(f"recipe '{n1}' -> product '{n2}'")
        # else:
        #     print("****************")
        #     print(recipe["products"])
        #     print("****************")

    print()
    print("len(names) = {} - len(recipes) = {}".format(len(names), len(recipes)))
    print("ATTENTION: these recipes are ignored")
    diff = set(names) - set(recipes.keys())
    print(diff)
    print("len(diff) = {}".format(len(diff)))
    print()

    return recipes


#############################################
def get_machine_recipes_with_one_product(
    name_of_the_json_file, machine_name="assembling-machine-2"
):
    # read json file
    with open(name_of_the_json_file, "r", encoding="utf8") as read_file:
        json_all = json.load(read_file)

    # json -> dist()
    for a in (e for e in json_all["entities"] if machine_name in e["name"]):
        crafting_categories = a["crafting_categories"]

    recipes = dict()
    names = []
    for recipe in (
        r for r in json_all["recipes"] if r["category"] in crafting_categories
    ):
        names.append(recipe["name"])
        if len(recipe["products"]) == 1:
            for ingredient in recipe["ingredients"]:
                ingredient["amount"] = Fraction(
                    ingredient["amount"], recipe["products"][0]["amount"]
                )
            recipes[recipe["name"]] = {
                "ingredients": recipe["ingredients"],
                "product": recipe["products"][0]["name"],
            }
            n1 = recipe["name"]
            n2 = recipe["products"][0]["name"]
            if n1 != n2:
                print()
                print("ATTENTION")
                print(f"recipe '{n1}' -> product '{n2}'")

    print()
    print("len(names) = {} - len(recipes) = {}".format(len(names), len(recipes)))
    print("ATTENTION: these recipes are ignored")
    diff = set(names) - set(recipes.keys())
    print(diff)
    print("len(diff) = {}".format(len(diff)))
    print()

    return recipes


#############################################
def get_items(name_of_the_json_file=None):
    if name_of_the_json_file is None:
        name_of_the_json_file = "Factorio 1.1 Vanilla.json"

    # read json file
    with open(name_of_the_json_file, "r", encoding="utf8") as f:
        json_all = json.load(f)

    print(json_all.keys())
    # json -> dist()
    items = dict_bp()
    for i in json_all["items"]:
        items[i["name"]] = float(i["stack"])  # items["wooden-chest"] = 50.0

    return items


#############################################
class dict_bp(dict):
    def __add__(self, other):
        temp = dict_bp(self)
        for key, value in other.items():
            if key in temp:
                temp[key] += value
            else:
                temp[key] = value
        return temp

    def __iadd__(self, other):
        for key, value in other.items():
            if key in self:
                self[key] += value
            else:
                self[key] = value
        return self

    def __str__(self):
        s = str()
        for k, v in self.items():
            s += '"{}" = {}\n'.format(k, v)
        return s


#############################################
class blueprint:
    def __init__(self, data):
        self.data = data
        if self.is_blueprint_book():
            self.obj = self.data["blueprint_book"]
        elif self.is_blueprint():
            self.obj = self.data["blueprint"]
        elif self.is_upgrade_planner():
            self.obj = self.data["upgrade_planner"]
        elif self.is_deconstruction_planner():
            self.obj = self.data["deconstruction_planner"]
        else:
            self.data = None
            self.obj = None

    @classmethod
    def new_blueprint(cls):
        bp_json = collections.OrderedDict()
        bp_json["blueprint"] = collections.OrderedDict()
        # bp_json['blueprint']['description'] = str()
        # bp_json['blueprint']['icons'] = list()
        # [{'signal': {'type': 'virtual', 'name': 'signal-a'}, 'index': 1}]
        bp_json["blueprint"]["entities"] = list()
        # bp_json['blueprint']['tiles'] = list()
        # bp_json['blueprint']['schedules'] = list()
        bp_json["blueprint"]["item"] = "blueprint"
        # bp_json['blueprint']['label'] = str()
        # bp_json['blueprint']['label_color']
        bp_json["blueprint"]["version"] = 281479275937792

        return cls(bp_json)

    @classmethod
    def new_blueprint_book(cls):
        bp_json = collections.OrderedDict()
        bp_json["blueprint_book"] = collections.OrderedDict()
        # bp_json['blueprint_book']['description'] = str()
        # bp_json['blueprint_book']['icons'] = list()
        bp_json["blueprint_book"]["item"] = "blueprint-book"
        # bp_json["blueprint_book"]["label"] = "new book"
        # bp_json['blueprint_book']['label_color']
        bp_json["blueprint_book"]["version"] = 281479275937792

        return cls(bp_json)

    @classmethod
    def from_string(cls, str):
        version_byte = str[0]
        if version_byte == "0":
            json_str = zlib.decompress(base64.b64decode(str[1:]))
            bp_json = json.loads(json_str, object_pairs_hook=collections.OrderedDict)
        else:
            print(
                "Warning! The version byte is currently 0 "
                "(for all Factorio versions through 1.1)"
            )
            print("Warning! Unsupported version: {0}".format(version_byte))
            bp_json = None

        return cls(bp_json)

    @classmethod
    def from_file(cls, filename):
        exchange_str = ""
        with open(filename, "r") as f:
            exchange_str = f.read()

        return cls.from_string(exchange_str)

    @classmethod
    def from_json_file(cls, filename):
        bp_json = ""
        with open(filename, "r", encoding="utf8") as f:
            bp_json = json.loads(f.read(), object_pairs_hook=collections.OrderedDict)

        return cls(bp_json)

    # -------------------------------------
    #   append

    def append_entity(self, e):
        e.set_entity_number(len(self.obj["entities"]) + 1)
        self.obj["entities"].append(e.data)

    def append_bp(self, bp, index=None):
        if not self.is_blueprint_book():
            print('the blueprint cannot contain other blueprints"')
            raise AttributeError
        else:
            if "blueprints" not in self.obj:
                self.obj["blueprints"] = list()

            d = collections.OrderedDict()
            if index is None:
                max_item = -1
                for x in self.obj["blueprints"]:
                    max_item = max(max_item, x.get("index", -1))

                d["index"] = max_item + 1
            else:
                d["index"] = index

            if bp.is_blueprint():
                d["blueprint"] = bp.obj.copy()
            elif bp.is_deconstruction_planner():
                d["deconstruction_planner"] = bp.obj.copy()
            elif bp.is_upgrade_planner():
                d["upgrade_planner"] = bp.obj.copy()
            elif bp.is_blueprint_book():
                d["blueprint_book"] = bp.obj.copy()
            else:
                print("bp.keys() = ", bp.data.keys())
                raise Exception("unknown bp type")

            self.obj["blueprints"].append(d)

    # -------------------------------------
    #   compare

    def __compare_entities(self, bp, debug):
        e1 = sorted(
            self.get_entities(),
            key=lambda a: (a.data["position"]["x"], a.data["position"]["y"]),
        )
        e2 = sorted(
            bp.get_entities(),
            key=lambda a: (a.data["position"]["x"], a.data["position"]["y"]),
        )
        if e1 == e2:
            return True
        else:
            """
            print("len1={} len2={}".format(len(e1), len(e2)))
            for i in range(len(e1)):
                print(f"{i} ", e1[i].data)
                print(f"{i} ", e2[i].data)
            """
            return False

    def __compare_bp_bp(self, bp, debug):
        result = dict()
        if debug:
            print("blueprint vs bplueprint")
        result["md5"] = self.get_md5() == bp.get_md5()
        if result["md5"] and debug:
            print("md5 are equal")
        result["label"] = self.read_label() == bp.read_label()
        if result["label"] and debug:
            print("label are equal")
        result["label_color"] = self.read_label_color() == bp.read_label_color()
        if result["label_color"] and debug:
            print("label_color are equal")
        result["description"] = self.read_description() == bp.read_description()
        if result["description"] and debug:
            print("description are equal")
        pmin_self = self.normalize_entities()
        pmin_bp = bp.normalize_entities()
        result["entities"] = self.__compare_entities(bp, debug)
        if result["entities"] and debug:
            print("entities are equal")
        self.denormalization_entities(pmin_self)
        bp.denormalization_entities(pmin_bp)
        result["tiles"] = self.read_tiles() == bp.read_tiles()
        if result["tiles"] and debug:
            print("tiles are equal")
        result["icons"] = self.read_icons() == bp.read_icons()
        if result["icons"] and debug:
            print("icons are equal")
        result["schedules"] = self.read_schedules() == bp.read_schedules()
        if result["schedules"] and debug:
            print("schedules are equal")
        result["version"] = self.read_version() == bp.read_version()
        if result["version"] and debug:
            print("version are equal")
        return [self.get_md5(), bp.get_md5(), result]

    def __compare_bp_book(self, bp, debug):
        result = list()
        if debug:
            print("blueprint vs book")
        for b in bp.get_all_bp(onedimensional=True, blueprint_only=True):
            result.append(self.__compare_bp_bp(b, debug))
        return result

    def compare(self, bp, debug=False):
        if self.is_blueprint() and bp.is_blueprint():
            return self.__compare_bp_bp(bp, debug)
        elif self.is_blueprint_book() and bp.is_blueprint_book():
            # TODO
            return {}
        else:
            if self.is_blueprint():
                return self.__compare_bp_book(bp, debug)
            else:
                return bp.__compare_bp_book(self, debug)

    # -------------------------------------
    #   get_all

    def __get_all_items_parse(self, bp, items):
        if bp.is_blueprint_book():
            for b in bp.read_blueprints():
                self.__get_all_items_parse(blueprint(b), items)
        elif bp.is_blueprint():
            for entity in bp.get_entities():
                if entity.read_name() == "curved-rail":
                    items += {"rail": 4}
                elif entity.read_name() == "straight-rail":
                    items += {"rail": 1}
                else:
                    items += {entity.read_name(): 1}
                items += entity.read_items()

    def get_all_items(self):
        items = dict_bp()
        self.__get_all_items_parse(self, items)
        return items

    def __get_all_tiles_parse(self, bp, tiles):
        if bp.is_blueprint_book():
            for b in bp.read_blueprints():
                self.__get_all_tiles_parse(blueprint(b), tiles)
        elif bp.is_blueprint():
            for t in bp.read_tiles():
                tiles += {t["name"]: 1}

    def get_all_tiles(self):
        tiles = dict_bp()
        self.__get_all_tiles_parse(self, tiles)
        return tiles

    def __get_all_bp_parse(self, bp, bps, current_directory):
        if bp.is_blueprint_book():
            # md5 = bp.get_md5()
            # current_directory += md5 + "\\"
            current_directory.append(bp)
            # bps.append([bp, md5, current_directory])
            bps.append([bp, list(current_directory)])
            for b in bp.read_blueprints():
                self.__get_all_bp_parse(blueprint(b), bps, list(current_directory))
        else:
            # md5 = bp.get_md5()
            # bps.append([bp, md5, current_directory])
            bps.append([bp, list(current_directory)])

    def get_all_bp(self, onedimensional=False, blueprint_only=False):
        bps = list()
        # self.__get_all_bp_parse(self, bps, "")
        self.__get_all_bp_parse(self, bps, [])

        if onedimensional is False:
            return bps
        elif onedimensional is True:
            temp = list()
            for a in bps:
                if blueprint_only is False:
                    temp.append(a[0])
                else:
                    if a[0].is_blueprint():
                        temp.append(a[0])
            return temp
        else:
            return list()

    def summary_of_book(self):
        res = copy.deepcopy(self)
        if self.is_blueprint_book():
            if "blueprints" in res.obj:
                del res.obj["blueprints"]
        elif self.is_blueprint():
            if "entities" in res.obj:
                del res.obj["entities"]
            if "tiles" in res.obj:
                del res.obj["tiles"]
        elif self.is_upgrade_planner():
            if "settings" in res.obj:
                del res.obj["settings"]
        elif self.is_deconstruction_planner():
            if "settings" in res.obj:
                del res.obj["settings"]
        else:
            res = ""

        return res

    # -------------------------------------
    #   get_

    def get_entities(self):
        if "entities" in self.obj:
            return list(map(lambda x: entity(x), self.obj["entities"]))
        else:
            return list()

    def __md5(self, data):
        return hashlib.md5(json.dumps(data, sort_keys=True).encode("utf-8")).hexdigest()

    def get_md5(self):
        return self.__md5(self.data)

    def get_filename(self):
        return "{:03d}_index_{}".format(self.data.get("index", 0), self.read_label())

    # -------------------------------------
    #   is_

    def is_deconstruction_planner(self):
        if self.data is not None:
            return "deconstruction_planner" in self.data
        else:
            return False

    def is_upgrade_planner(self):
        if self.data is not None:
            return "upgrade_planner" in self.data
        else:
            return False

    def is_blueprint_book(self):
        if self.data is not None:
            return "blueprint_book" in self.data
        else:
            return False

    def is_blueprint(self):
        if self.data is not None:
            return "blueprint" in self.data
        else:
            return False

    # -------------------------------------
    #   normalize_

    def denormalization_entities(self, p):
        for e in self.get_entities():
            e.get_pos().__iadd__(p)

    def normalize_entities(self):
        # position -= pos_min
        x = list()
        y = list()
        entities = self.get_entities()
        for e in entities:
            x.append(e.get_pos().read_x())
            y.append(e.get_pos().read_y())

        pmin = position.new_position(min(x), min(y))
        for e in entities:
            e.get_pos().__isub__(pmin)
        return pmin

    # -------------------------------------
    #   print_

    def print_entities(self):
        for e in self.get_entities():
            print(e.data)

    # -------------------------------------
    #   read_

    def read_blueprints(self):
        if self.is_blueprint_book():
            return self.obj.get("blueprints", list())
        else:
            print('the blueprint does not contain parameter "blueprints"')
            raise AttributeError

    def read_description(self):
        return self.obj.get("description", "description is missing")

    def read_icons(self):
        return self.obj.get("icons", None)

    def read_index(self):
        return self.data.get("index", None)

    def read_item(self):
        return self.obj["item"]

    def read_label(self):
        return self.obj.get("label", "untitled")

    def read_label_color(self):
        return self.obj.get("label_color", None)

    def read_schedules(self):
        return self.obj.get("schedules", list())

    def read_tiles(self):
        return self.obj.get("tiles", list())

    def read_version(self):
        return self.obj.get("version", "")

    # -------------------------------------
    #   set_

    def set_description(self, str):
        self.obj["description"] = str

    def set_icons(self, index, icon_type, name):
        new_icon = {"signal": {"type": icon_type, "name": name}, "index": index}
        if index >= 1 and index <= 4:
            if "icons" in self.obj:
                if index in [icon["index"] for icon in self.obj["icons"]]:
                    for i in range(len(self.obj["icons"])):
                        if self.obj["icons"][i]["index"] == index:
                            self.obj["icons"][i] = new_icon
                            break
                else:
                    self.obj["icons"].append(new_icon)
            else:
                self.obj["icons"] = [new_icon]

    def set_index(self, val):
        self.data["index"] = val

    def set_label(self, str):
        self.obj["label"] = str

    def set_label_color(self, r, g, b):
        self.obj["label_color"] = {"r": r, "g": g, "b": b}

    # -------------------------------------
    #   to_

    def to_json_str(self):
        json_str = json.dumps(
            self.data,
            separators=(",", ":"),
            indent=4,
            ensure_ascii=False,
            sort_keys=True,
        )
        return json_str

    def to_json_file(self, filename):
        with open(filename, "w", encoding="utf8") as f:
            print(self.to_json_str(), file=f, flush=True)

    def to_str(self):
        json_str = json.dumps(
            self.data, separators=(",", ":"), ensure_ascii=False
        ).encode("utf8")
        exchange_str = "0" + base64.b64encode(zlib.compress(json_str, 9)).decode(
            "utf-8"
        )
        return exchange_str

    def to_file(self, filename):
        with open(filename, "w") as f:
            print(self.to_str(), file=f, flush=True)


######################################
#
# main
if __name__ == "__main__":
    func_list = [
        name
        for (name, obj) in vars().items()
        if hasattr(obj, "__class__") and obj.__class__.__name__ == "function"
    ]

    for line in func_list:
        print(f"from bp_functions import {line}")

    def get_method_names(class_name):
        print("****************************")
        print(f"{class_name}")
        for name in dir(class_name):
            if name[-1] != "_":
                print(name)

    print("****************************")
    print("****************************")
    get_method_names(position)
    get_method_names(entity)
    get_method_names(blueprint)
