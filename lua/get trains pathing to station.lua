/silent-command
l = ''
ups = 60 * game.speed
stop = game.player.selected
s = stop.position
for k,v in pairs(game.player.surface.get_trains()) do
  if v.path_end_stop ~= nil then
    p = v.path_end_stop.position
    if p.x == s.x and p.y == s.y then
      l = l .. '[train=' .. v.locomotives.front_movers[1].unit_number ..
        '] (T -' .. string.format("%.2f", (v.path.total_distance - v.path.travelled_distance)/(298.1/3.6)*(60/ups)) .. ' wall seconds)'
    end
  end
end
game.print('Trains headed to [' .. stop.backer_name .. '] at [gps=' .. s.x .. ',' .. s.y .. ']: ' .. l)
