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

function groups_of_requests(EventData)
    local items = {}
    local mine_group_1 = 100001
    local mine_group_2 = 100002
    local mine_request_1 = {
        {signal = {type = "item", name = "stack-inserter"}, count = 20, index = 1},
        {signal = {type = "item", name = "stack-filter-inserter"}, count = 20, index = 2},
        {signal = {type = "item", name = "landfill"}, count = 50, index = 3},
        {signal = {type = "item", name = "steel-chest"}, count = 15, index = 4},
        {signal = {type = "item", name = "logistic-chest-storage"}, count = 3, index = 5},
        {signal = {type = "item", name = "roboport"}, count = 2, index = 6},
        {signal = {type = "item", name = "radar"}, count = 2, index = 7},
        {signal = {type = "item", name = "arithmetic-combinator"}, count = 5, index = 8},
        {signal = {type = "item", name = "decider-combinator"}, count = 5, index = 9},
        {signal = {type = "item", name = "constant-combinator"}, count = 5, index = 10},
        {signal = {type = "item", name = "storage-tank"}, count = 5, index = 11},
        {signal = {type = "item", name = "pipe"}, count = 30, index = 12},
        {signal = {type = "item", name = "pipe-to-ground"}, count = 20, index = 13},
        {signal = {type = "item", name = "pump"}, count = 5, index = 14},
        {signal = {type = "item", name = "electric-mining-drill"}, count = 30, index = 15},
        {signal = {type = "item", name = "speed-module"}, count = 20, index = 16},
        {signal = {type = "item", name = "rail"}, count = 50, index = 17},
        {signal = {type = "item", name = "rail-signal"}, count = 5, index = 18},
        {signal = {type = "item", name = "rail-chain-signal"}, count = 5, index = 19},
        {signal = {type = "virtual", name = "signal-G"}, count = mine_group_1, index = 20}
    }
    local mine_request_2 = {
        {signal = {type = "item", name = "train-stop"}, count = 2, index = 1},
        {signal = {type = "item", name = "medium-electric-pole"}, count = 10, index = 2},
        {signal = {type = "item", name = "small-electric-pole"}, count = 10, index = 3},
        {signal = {type = "item", name = "big-electric-pole"}, count = 5, index = 4},
        {signal = {type = "item", name = "express-transport-belt"}, count = 100, index = 5},
        {signal = {type = "item", name = "express-underground-belt"}, count = 50, index = 6},
        {signal = {type = "item", name = "express-splitter"}, count = 5, index = 7},
        {signal = {type = "virtual", name = "signal-G"}, count = mine_group_2, index = 20}
    }
    for _, train in pairs(force.get_trains()) do
        if train.manual_mode == false and checking_schedule(train, "[L] MINE BUILDER [item=electric-mining-drill]") then
            for k, v in pairs(train.get_contents()) do
                if v > 0 then
                    items[k] = true
                end
            end
        end
    end

    local request = mine_request_1
    for i = 1, #request do
        if request[i]["signal"]["type"] == "item" and not items[request[i]["signal"]["name"]] then
            request[i]["count"] = 0
        end
    end

    request = mine_request_2
    for i = 1, #request do
        if request[i]["signal"]["type"] == "item" and not items[request[i]["signal"]["name"]] then
            request[i]["count"] = 0
        end
    end

    for _, entity in pairs(game.surfaces["nauvis"].find_entities_filtered {name = {"constant-combinator"}}) do
        control_behavior = entity.get_control_behavior()
        if control_behavior then
            local par = control_behavior.parameters
            local is_this_mine_request_1 = false
            local is_this_mine_request_2 = false
            for i = 1, #par do
                if par[i]["signal"]["name"] == "signal-G" and par[i]["count"] == mine_group_1 then
                    is_this_mine_request_1 = true
                end
                if par[i]["signal"]["name"] == "signal-G" and par[i]["count"] == mine_group_2 then
                    is_this_mine_request_2 = true
                end
            end
            if is_this_mine_request_1 then
                entity.get_control_behavior().parameters = mine_request_1
            end
            if is_this_mine_request_2 then
                entity.get_control_behavior().parameters = mine_request_2
            end
        end
    end
end

force = game.player.force
script.on_nth_tick(3600, groups_of_requests)