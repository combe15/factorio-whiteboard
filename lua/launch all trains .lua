/silent-command
--[[ 
  Launches all trains on the map / sets them to automatic mode
]]
/silent-command 
for _,t in pairs(game.player.force.get_trains()) do t.manual_mode = false end 