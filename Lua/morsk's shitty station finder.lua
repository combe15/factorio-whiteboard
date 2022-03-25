/sc --[[ shitty station finder ]]
local function find()
  local found,out = 0,""
  for _,e in pairs(game.player.surface.find_entities_filtered{type = {"train-stop"}}) do
    local c = e.get_control_behavior()
    if c
       and (c.connect_to_logistic_network
            or (c.enable_disable
                and (c.get_circuit_network(defines.wire_type.red)
                     or c.get_circuit_network(defines.wire_type.green))
               )
           )
    then
      found = found + 1
      out = out..found..":[gps="..e.position.x..","..e.position.y.."] "
    end
  end
  game.player.print(found > 0 and out or "None found.")
end
find()
