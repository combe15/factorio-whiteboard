/silent-command 
--[[
Find and ping all entities that have zero finished products
]]
local found_ents = {} 
local ents = {"assembling-machine-1", "assembling-machine-2", "assembling-machine-3", "stone-furnace", "steel-furnace", "electric-furnace", "chemical-plant", "oil-refinery", "centrifuge"} 
for _, entity in pairs(game.player.surface.find_entities_filtered({name = ents})) do 
    if entity.products_finished  == 0 then 
      if not found_ents[entity.name] then found_ents[entity.name] = {} end 
        table.insert(found_ents[entity.name], {x = entity.position.x, y = entity.position.y}) 
    end 
end 

if not next(found_ents) then 
  game.print("No entities with zero finished products found!") 
else 
  game.print("Entities with zero products finished: ") 
  for loc_name, cord_sets in pairs(found_ents) do 
    local x = ""
    for _, cords in pairs(cord_sets) do 
      x = x .. " [gps="..cords.x..","..cords.y.."]" 
    end 
    game.print("[img=item."..loc_name.."]"..x.."\n") 
  end 
end 