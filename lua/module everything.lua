/silent-command --[[ module everything --]]
local function box_on_surface(s)
  local a,b,c,d,m,M,n=1/0,1/0,-1/0,-1/0,math.min,math.max
  for x,y,z in s:gmatch("%[gps=([+-]?[%d%.]+),([+-]?[%d%.]+),?([^%]]*)%]")do a=m(a,x+0)b=m(b,y+0)c=M(c,x+0)d=M(d,y+0)n=z end
  return{left_top={x=a,y=b},right_bottom={x=c,y=d}}, game.get_surface(#n>0 and n or 1)
end
local function proxy_for(e)
  return e.surface.find_entity("item-request-proxy", e.position)
end
--[[ allowed[module][recipe] + caches result --]]
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
local function add_to(t, add_me)
  for k,v in pairs(add_me) do
    t[k] = (t[k] or 0) + v
  end
end
local function total_count(t)
  local total = 0
  for _,v in pairs(t) do
    total = total + v
  end
  return total
end
local function speed_if_cant_prod(recipe, modules)
  local substitutes = {}
  for mod,_ in pairs(modules) do
    if not allowed[mod][recipe] then
      local n = modules[mod]
      modules[mod] = nil
      local substitute_mod = mod:gsub("productivity%-", "speed-")
      if substitute_mod == mod then
        substitute_mod = "speed-module"
      end
      substitutes[substitute_mod] = (substitutes[substitute_mod] or 0) + n
    end
  end
  add_to(modules, substitutes)
end
local function main(types_to_mod, gps)
  local n_modules, n_machines, types_for_search = 0,0,{}
  for typename,_ in pairs(types_to_mod) do
    table.insert(types_for_search, typename)
  end
  local box, surface = box_on_surface(gps)
  for _,e in pairs(surface.find_entities_filtered{area=box,type=types_for_search}) do
    local totals = {}
    local mod_inv = e.get_module_inventory()
    add_to(totals, mod_inv.get_contents())
    local req = proxy_for(e)
    if req then
      add_to(totals, req.item_requests)
    end
    local unused = #mod_inv - total_count(totals)
    if unused > 0 then
      local new_reqs = { [types_to_mod[e.type]] = unused }
      if e.prototype.crafting_categories and e.get_recipe() then
        speed_if_cant_prod(e.get_recipe().name, new_reqs)
      end
      if req then
        add_to(new_reqs, req.item_requests)
        req.item_requests = new_reqs
      else
        e.surface.create_entity{name="item-request-proxy", position=e.position, force=e.force, target=e, modules=new_reqs}
      end
      n_modules = n_modules + unused
      n_machines = n_machines + 1
    end
  end
  --[[ again, for ghosts --]]
  for _,e in pairs(surface.find_entities_filtered{area=box,ghost_type=types_for_search}) do
    local unused = e.ghost_prototype.module_inventory_size - total_count(e.item_requests)
    if unused > 0 then
      local new_reqs = { [types_to_mod[e.ghost_type]] = unused }
      if e.ghost_prototype.crafting_categories and e.get_recipe() then
        speed_if_cant_prod(e.get_recipe().name, new_reqs)
      end
      add_to(new_reqs, e.item_requests)
      e.item_requests = new_reqs
      n_modules = n_modules + unused
      n_machines = n_machines + 1
    end
  end
  game.print(string.format("Requesting %d modules in %d machines.", n_modules, n_machines))
end
local function go(gps) main({
  ["assembling-machine"]="productivity-module",
  furnace="productivity-module",
  beacon="speed-module",
  ["mining-drill"]="effectivity-module"
}, gps) end
go "
