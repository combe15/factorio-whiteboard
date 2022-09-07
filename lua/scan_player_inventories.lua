/c 
local x='' 
for k,v in pairs(game.players) do 
  if v.get_inventory(defines.inventory.character_main) ~= nil then 
    x = x .. ', ' .. v.name  .. ': ' .. v.get_inventory(defines.inventory.character_main).count_empty_stacks() .. '/' .. #v
  else
    x = x .. ', ' .. v.name .. ': ??/??'
  end
end 
game.print(x)
