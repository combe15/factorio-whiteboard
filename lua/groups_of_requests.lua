/silent-command
function checking_schedule(train, station_name)
    schedule = train.schedule
    if schedule then
        records = schedule["records"]
        for i = 1, #records do
            if records[i]["station"] == station_name then
                return true
            end
        end
    end
    return false
end

function change_request_for_availability_of_items(request, items)
    for i = 1, #request do
        if request[i]["signal"]["type"] == "item" and not items[request[i]["signal"]["name"]] then
            request[i]["count"] = 0
        end
    end
end

function process_group_of_requests(station_name, group_1, group_2, group_3, request_1, request_2, request_3)
    local items = {}
    for _, train in pairs(force.get_trains()) do
        if train.manual_mode == false and checking_schedule(train, station_name) then
            for k, v in pairs(train.get_contents()) do
                items[k] = (v > 0)
            end
        end
    end

    change_request_for_availability_of_items(request_1, items)
    change_request_for_availability_of_items(request_2, items)
    change_request_for_availability_of_items(request_3, items)

    for _, entity in pairs(
        game.surfaces["nauvis"].find_entities_filtered {name = {"constant-combinator"}, force = force}
    ) do
        control_behavior = entity.get_control_behavior()
        if control_behavior then
            local par = control_behavior.parameters
            local is_this_request_1 = false
            local is_this_request_2 = false
            local is_this_request_3 = false
            for i = 1, #par do
                if par[i]["signal"]["name"] == "signal-G" then
                    if par[i]["count"] == group_1 then
                        is_this_request_1 = true
                        break
                    elseif par[i]["count"] == group_2 then
                        is_this_request_2 = true
                        break
                    elseif par[i]["count"] == group_3 then
                        is_this_request_3 = true
                        break
                    end
                end
            end
            if is_this_request_1 then
                entity.get_control_behavior().parameters = request_1
            elseif is_this_request_2 then
                entity.get_control_behavior().parameters = request_2
            elseif is_this_request_3 then
                entity.get_control_behavior().parameters = request_3
            end
        end
    end
end

function table.clone(oldTable)
    local res = {}
    for i = 1, #oldTable do
        res[i] = {
            signal = {type = oldTable[i]["signal"]["type"], name = oldTable[i]["signal"]["name"]},
            count = oldTable[i]["count"],
            index = oldTable[i]["index"]
        }
    end
    return res
end

mine_group_1 = 100001
mine_group_2 = 100002
mine_group_3 = 100003
mine_request_1 = {
    {signal = {type = "item", name = "electric-mining-drill"}, count = 30, index = 1},
    {signal = {type = "item", name = "speed-module"}, count = 20, index = 2},
    {signal = {type = "item", name = "rail-signal"}, count = 5, index = 3},
    {signal = {type = "item", name = "big-electric-pole"}, count = 5, index = 4},
    {signal = {type = "item", name = "medium-electric-pole"}, count = 10, index = 5},
    {signal = {type = "item", name = "small-electric-pole"}, count = 10, index = 6},
    {signal = {type = "item", name = "rail-chain-signal"}, count = 5, index = 7},
    {signal = {type = "item", name = "rail"}, count = 50, index = 8},
    {signal = {type = "item", name = "train-stop"}, count = 2, index = 9},
    {signal = {type = "item", name = "storage-tank"}, count = 5, index = 10},
    {signal = {type = "item", name = "pipe-to-ground"}, count = 20, index = 11},
    {signal = {type = "item", name = "landfill"}, count = 50, index = 12},
    {signal = {type = "item", name = "cliff-explosives"}, count = 20, index = 13},
    {signal = {type = "item", name = "repair-pack"}, count = 50, index = 14},
    {signal = {type = "item", name = "pump"}, count = 5, index = 15},
    {signal = {type = "item", name = "pipe"}, count = 30, index = 16},
    {signal = {type = "item", name = "beacon"}, count = 10, index = 17},
    {signal = {type = "item", name = "speed-module-3"}, count = 20, index = 18},
    {signal = {type = "item", name = "logistic-chest-storage"}, count = 3, index = 19},
    {signal = {type = "virtual", name = "signal-G"}, count = mine_group_1, index = 20}
}
mine_request_2 = {
    {signal = {type = "item", name = "logistic-chest-buffer"}, count = 3, index = 1},
    {signal = {type = "item", name = "logistic-chest-active-provider"}, count = 3, index = 2},
    {signal = {type = "item", name = "stack-inserter"}, count = 20, index = 3},
    {signal = {type = "item", name = "stack-filter-inserter"}, count = 20, index = 4},
    {signal = {type = "item", name = "decider-combinator"}, count = 5, index = 5},
    {signal = {type = "item", name = "roboport"}, count = 2, index = 6},
    {signal = {type = "item", name = "radar"}, count = 2, index = 7},
    {signal = {type = "item", name = "fast-inserter"}, count = 10, index = 8},
    {signal = {type = "item", name = "arithmetic-combinator"}, count = 5, index = 9},
    {signal = {type = "item", name = "constant-combinator"}, count = 5, index = 10},
    {signal = {type = "item", name = "programmable-speaker"}, count = 3, index = 11},
    {signal = {type = "item", name = "transport-belt"}, count = 100, index = 12},
    {signal = {type = "item", name = "fast-transport-belt"}, count = 100, index = 13},
    {signal = {type = "item", name = "express-transport-belt"}, count = 100, index = 14},
    {signal = {type = "item", name = "wooden-chest"}, count = 15, index = 15},
    {signal = {type = "item", name = "splitter"}, count = 5, index = 16},
    {signal = {type = "item", name = "fast-splitter"}, count = 5, index = 17},
    {signal = {type = "item", name = "express-splitter"}, count = 5, index = 18},
    {signal = {type = "item", name = "underground-belt"}, count = 25, index = 19},
    {signal = {type = "virtual", name = "signal-G"}, count = mine_group_2, index = 20}
}
mine_request_3 = {
    {signal = {type = "item", name = "fast-underground-belt"}, count = 25, index = 1},
    {signal = {type = "item", name = "express-underground-belt"}, count = 25, index = 2},
    {signal = {type = "item", name = "steel-chest"}, count = 15, index = 3},
    {signal = {type = "item", name = "laser-turret"}, count = 20, index = 4},
    {signal = {type = "item", name = "pumpjack"}, count = 2, index = 5},
    {signal = {type = "item", name = "substation"}, count = 1, index = 6},
    {signal = {type = "item", name = "filter-inserter"}, count = 1, index = 7},
    {signal = {type = "item", name = "roboport"}, count = 1, index = 8},
    {signal = {type = "virtual", name = "signal-G"}, count = mine_group_3, index = 20}
}

function groups_of_requests(EventData)
    local loc_mine_request_1 = table.clone(mine_request_1)
    local loc_mine_request_2 = table.clone(mine_request_2)
    local loc_mine_request_3 = table.clone(mine_request_3)
    process_group_of_requests(
        "[L] MINE BUILDER [item=electric-mining-drill]",
        mine_group_1,
        mine_group_2,
        mine_group_3,
        loc_mine_request_1,
        loc_mine_request_2,
        loc_mine_request_3
    )
end

force = game.player.force
script.on_nth_tick(3600, groups_of_requests)