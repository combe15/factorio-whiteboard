/silent-command
--[[
  hack roboports
  take a BP or a BOOK in the cursor and execute the script
  I recommend doing it on the BPs in the inventory
]]
local player = game.player

local function table_concat(t1, t2)
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

local function get_blueprint(bp)
    --[[
        returns an array of bps from the entire book
    ]]
    if not (bp and bp.valid and bp.valid_for_read) then
        return nil
    elseif bp.is_blueprint_book then
        local bps = {}
        local inv = bp.get_inventory(defines.inventory.item_main)
        for i = 1, #inv do
            table_concat(bps, get_blueprint(inv[i]))
        end
        return bps
    elseif bp.is_blueprint then
        return {bp}
    else
        return nil
    end
end

if player.is_cursor_blueprint() then
    local bps = get_blueprint(player.cursor_stack)
    for _, bp in pairs(bps) do
        if bp then
            local ents = bp.get_blueprint_entities()
            if ents then
                for _, e in pairs(ents) do
                    --[game.print(game.table_to_json(e))]
                    if e["name"] == "roboport" then
                        e["items"] = {["construction-robot"] = 5}
                    end
                end
                bp.set_blueprint_entities(ents)
            end
        end
    end
end