/silent-command
--[[
  adds a query for modules in drills and assembly machines
  drills: 3x speed-module
  assembly machines: 2x-4x productivity-module

  go "[gps=0,0.0][gps=32,-32.0]"
]]
local player = game.player
local module_allowed = {
    ["advanced-circuit"] = true,
    ["automation-science-pack"] = true,
    ["battery"] = true,
    ["chemical-science-pack"] = true,
    ["copper-cable"] = true,
    ["copper-plate"] = true,
    ["electric-engine-unit"] = true,
    ["electronic-circuit"] = true,
    ["empty-barrel"] = true,
    ["engine-unit"] = true,
    ["explosives"] = true,
    ["flying-robot-frame"] = true,
    ["iron-gear-wheel"] = true,
    ["iron-plate"] = true,
    ["iron-stick"] = true,
    ["logistic-science-pack"] = true,
    ["low-density-structure"] = true,
    ["lubricant"] = true,
    ["military-science-pack"] = true,
    ["nuclear-fuel"] = true,
    ["plastic-bar"] = true,
    ["processing-unit"] = true,
    ["production-science-pack"] = true,
    ["rocket-control-unit"] = true,
    ["rocket-fuel"] = true,
    ["rocket-part"] = true,
    ["steel-plate"] = true,
    ["stone-brick"] = true,
    ["sulfur"] = true,
    ["sulfuric-acid"] = true,
    ["uranium-fuel-cell"] = true,
    ["utility-science-pack"] = true,
    ["basic-oil-processing"] = true,
    ["advanced-oil-processing"] = true,
    ["coal-liquefaction"] = true,
    ["heavy-oil-cracking"] = true,
    ["light-oil-cracking"] = true,
    ["solid-fuel-from-light-oil"] = true,
    ["solid-fuel-from-petroleum-gas"] = true,
    ["solid-fuel-from-heavy-oil"] = true,
    ["uranium-processing"] = true,
    ["nuclear-fuel-reprocessing"] = true,
    ["kovarex-enrichment-process"] = true
}

local function get_number_of_installed_modules(entity)
    local number_of_modules = 0
    for _, v in pairs(entity.get_module_inventory().get_contents()) do
        number_of_modules = number_of_modules + v
    end
    return number_of_modules
end

local function create_request_for_modules(entity, modules)
    entity.surface.create_entity {
        name = "item-request-proxy",
        target = entity,
        position = entity.position,
        force = entity.force,
        modules = modules
    }
end

local function create_request_for_modules_assembling_machine(entity, modules)
    if entity.get_recipe() ~= nil and module_allowed[entity.get_recipe().name] then
        local number_of_modules = modules - get_number_of_installed_modules(entity)
        if number_of_modules > 0 then
            create_request_for_modules(entity, {["productivity-module"] = number_of_modules})
        end
    end
end

local function get_area_from_gps_tags(s)
    --[[
        "[gps=0,0.0][gps=32,-32.0]" -> { { "0", "-32.0" }, { "32", "0.0" } }
    ]]
    for x1, y1, x2, y2 in s:gmatch("%[gps=([+-]?[%d%.]+),([+-]?[%d%.]+)%]%[gps=([+-]?[%d%.]+),([+-]?[%d%.]+)%]") do
        return {{math.min(x1, x2), math.min(y1, y2)}, {math.max(x1, x2), math.max(y1, y2)}}
    end
end

local function go(str)
    local area_1 = get_area_from_gps_tags(str)
    for _, entity in pairs(
        player.surface.find_entities_filtered {
            area = area_1,
            name = {"electric-mining-drill", "assembling-machine-2", "assembling-machine-3"},
            force = player.force
        }
    ) do
        if entity.name == "electric-mining-drill" then
            local number_of_modules = 3 - get_number_of_installed_modules(entity)
            if number_of_modules > 0 then
                create_request_for_modules(entity, {["speed-module"] = number_of_modules})
            end
        elseif entity.name == "assembling-machine-2" then
            create_request_for_modules_assembling_machine(entity, 2)
        elseif entity.name == "assembling-machine-3" then
            create_request_for_modules_assembling_machine(entity, 4)
        end
    end
end

go "