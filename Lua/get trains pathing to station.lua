/c 
l = ''
stop = game.player.selected
s = stop.position
for k,v in pairs(game.player.surface.get_trains()) do 
  if v.path_end_stop ~= nil then 
    p = v.path_end_stop.position 
    if p.x == s.x and p.y == s.y then 
      l = l .. '[train=' .. v.locomotives.front_movers[1].unit_number .. '] (' .. v.path.total_distance - v.path.travelled_distance .. 'm)'
    end 
  end 
end
game.print('Trains headed to ' .. stop.backer_name .. ' at [gps=' .. s.x .. ',' .. s.y .. ']: ' .. l)
