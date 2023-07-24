/c 
for k,v in 
  pairs(game.player.surface.find_entities_filtered({name={'solar-panel','accumulator'}})) do 
  if not v.is_connected_to_electric_network() then 
    v.order_deconstruction(game.player.force) 
  end 
end
