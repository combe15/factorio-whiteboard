/silent-command --[[ module everything ]]
local function proxy_for(e)
  return e.surface.find_entity("item-request-proxy", e.position)
end
--[[ cached table for direct lookup, instead of scanning lists over and over --]]
local allowed = setmetatable({}, {
  __index = function(mytable, module_name)
    local table_of_allowed = {}
    for _,allowed_recipe in pairs(game.item_prototypes[module_name].limitations) do
      table_of_allowed[allowed_recipe] = true
    end
    rawset(mytable, module_name, table_of_allowed)
    return table_of_allowed
  end
})
local function adjust_if_cant_prod(e, modules)
  local ok, recipe = pcall(function()
    return e.get_recipe().name
  end)
  local mod = next(modules) --[[ first key in table --]]
  if ok and not allowed[mod][recipe] then
    local n = modules[mod]
    modules[mod] = nil
    modules["effectivity-module"] = math.min(n, 3)
  end
end
local function go(types_to_mod)
  local n_modules, n_machines, types_for_search = 0,0,{}
  for typename,_ in pairs(types_to_mod) do
    table.insert(types_for_search, typename)
  end
  for _,e in pairs(game.player.surface.find_entities_filtered{type=types_for_search}) do
    local mod_inv = e.get_module_inventory()
    if #mod_inv > 0 and mod_inv.is_empty() and not proxy_for(e) then
      local modules = { [types_to_mod[e.type]] = #mod_inv }
      adjust_if_cant_prod(e, modules)
      e.surface.create_entity{name="item-request-proxy", position=e.position, force=e.force, target=e, modules=modules}
      n_modules = n_modules + #mod_inv
      n_machines = n_machines + 1
    end
  end
  game.print(string.format("Requesting %d modules in %d machines.", n_modules, n_machines))
end
go{
  ["assembling-machine"]="productivity-module",
  furnace="productivity-module",
  beacon="speed-module",
  ["mining-drill"]="effectivity-module"
}
