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

function process_group_of_requests(requests)
    local items = {}
    for _, train in pairs(force.get_trains()) do
        if train.manual_mode == false and checking_schedule(train, requests["station_name"]) then
            for k, v in pairs(train.get_contents()) do
                items[k] = (v > 0)
            end
        end
    end

    for i = 1, #requests["requests"] do
        change_request_for_availability_of_items(requests["requests"][i]["request"], items)
    end

    for _, entity in pairs(
        game.surfaces["nauvis"].find_entities_filtered {name = {"constant-combinator"}, force = force}
    ) do
        control_behavior = entity.get_control_behavior()
        if control_behavior then
            local par = control_behavior.parameters
            local index = nil
            for i = 1, #par do
                if par[i]["signal"]["name"] == "signal-G" then
                    local c = par[i]["count"]
                    for i = 1, #requests["requests"] do
                        if c == requests["requests"][i]["group"] then
                            index = i
                            break
                        end
                    end
                end
            end
            if index then
                entity.get_control_behavior().parameters = requests["requests"][index]["request"]
            end
        end
    end
end

function request_clone(request)
    local new_request = {}
    for i = 1, #request do
        new_request[i] = {
            signal = {type = request[i]["signal"]["type"], name = request[i]["signal"]["name"]},
            count = request[i]["count"],
            index = request[i]["index"]
        }
    end
    return new_request
end

function requests_clone(requests)
    local new_requests = {}
    new_requests["station_name"] = requests["station_name"]
    new_requests["requests"] = {}
    for i = 1, #requests["requests"] do
        new_requests["requests"][i] = {}
        new_requests["requests"][i]["group"] = requests["requests"][i]["group"]
        new_requests["requests"][i]["request"] = request_clone(requests["requests"][i]["request"])
    end
    return new_requests
end

local mine_group_1 = -100001
local mine_group_2 = -100002
local mine_group_3 = -100003
mine_requests = {
    station_name = "[L] MINE BUILDER [item=electric-mining-drill]",
    requests = {
        {
            group = mine_group_1,
            request = {
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
        },
        {
            group = mine_group_2,
            request = {
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
        },
        {
            group = mine_group_3,
            request = {
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
        }
    }
}

function groups_of_requests(EventData)
    local loc_mine_requests = requests_clone(mine_requests)
    process_group_of_requests(loc_mine_requests)
end

force = game.player.force
script.on_nth_tick(3600, groups_of_requests)
