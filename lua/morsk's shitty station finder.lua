/silent-command
--[[
  shitty station finder
]]
local function find()
  local found,out = 0," limit > 0 \n "
  local found1,out1 = 0," limit > 1 \n "
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
        if e.trains_limit > 1 then
            found1 = found1 + 1
            out1 = out1..found1..":[gps="..e.position.x..","..e.position.y.."] "
        else
            found = found + 1
            out = out..found..":[gps="..e.position.x..","..e.position.y.."] "
        end
    end
  end
  game.player.print( out ~= "" and out or "None found.")
  game.player.print( out1 ~= "" and out1 or "None found.")
end
find()
