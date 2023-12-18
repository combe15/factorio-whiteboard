/silent-command
--[[
  no path station finder
]]
local st = {}
for k, v in pairs(game.player.surface.get_trains()) do
    if v.state == defines.train_state.no_path then
        game.print("[train=" .. v.locomotives.front_movers[1].unit_number .. "]")
        st[v.schedule.records[v.schedule.current].station] = true
    end
end
game.print("no path stations:")
game.print(game.table_to_json(st))
local found, out = 0, "\n"
for _, e in pairs(game.player.surface.find_entities_filtered {type = {"train-stop"}}) do
    for st_name, _ in pairs(st) do
        if st_name == e.backer_name then
            if e.trains_limit > e.trains_count then
                found = found + 1
                out = out .. found .. ":[gps=" .. e.position.x .. "," .. e.position.y .. "] "
            end
        end
    end
end
game.player.print(out ~= "" and out or "None found.")