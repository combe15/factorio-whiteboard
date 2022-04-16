/c
-- Print out what trains currently report no path
for k,v in pairs(game.player.surface.get_trains()) do
  if v.state == defines.train_state.no_path then
    game.print('[train=' .. v.locomotives.front_movers[1].unit_number .. ']')
  end
end
