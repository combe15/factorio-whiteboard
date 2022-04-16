/sc 
-- Find solar pannel ghosts
r = '' 
for k,v in pairs(game.player.surface.find_entities_filtered({ghost_type={'solar-panel'}})) do 
  r = r .. '[gps=' .. v.position.x .. ',' .. v.position.y .. ']' 
end 
game.print(r)
