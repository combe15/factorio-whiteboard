/silent-command
--[[
  Finds the location on the map where there is an assember crafting select item.
  Replace 'spidertron' with your searched item to find its location.
--]]
recipe = 'spidertron'

for k,v in pairs(game.player.surface.find_entities_filtered(
    {name={'assembling-machine-1', 'assembling-machine-2', 'assembling-machine-3', 'chemical-plant', 'refinery'}}))
do
  if
    v.get_recipe() ~= nil and
    v.get_recipe().name ~= nil and
    v.get_recipe().name == recipe then

    game.print(v.get_recipe().name .. ': [gps='.. v.position.x .. ', '.. v.position.y .. ']')

  end
end
