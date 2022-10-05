/c 
min = 1000000000 
for k,c in pairs(game.player.surface.find_entities_filtered{name="coal"}) do 
  d = ((c.position.x * c.position.x) + (c.position.y * c.position.y)) 
  if d < min then 
    min = d 
    game.print('new min [gps'..'='..c.position.x..','..c.position.y..']: ' .. d) 
  end 
end
