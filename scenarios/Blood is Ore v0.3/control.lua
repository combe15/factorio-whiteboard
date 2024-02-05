-- Factorio script to drop specific items when entities are damaged based on the cause of the damage.

-- Require necessary libraries for the script.
local handler = require("event_handler")
handler.add_lib(require("freeplay"))
handler.add_lib(require("silo-script"))

-- Table for categorizing damage causes and their corresponding item drops.
local damage_categories = {
    -- Each key is a damage cause (entity name), and the value is a table of items and their counts.
    -- Values of the keys are its weights, 0.1 is a 10% chance of drop, while 1.0 is a 100% chance.
    ["character"] = { ["iron-ore"] = 0.4355, ["copper-ore"] = 0.2755, ["stone"] = 0.0997, ["coal"] = 0.133, ["uranium-ore"] = 0.00, ["crude-oil-barrel"] = 0.0126 },
    -- ["locomotive"] = { ["iron-ore"] = 0.03, ["copper-ore"] = 0.69, ["stone"] = 0.79, ["coal"] = 0.9, ["uranium-ore"] = 0.31, ["crude-oil-barrel"] = 0.28 },
    -- ["cargo-wagon"] = { ["iron-ore"] = 0.19, ["copper-ore"] = 0.34, ["stone"] = 0.41, ["coal"] = 0.8, ["uranium-ore"] = 0.1, ["crude-oil-barrel"] = 0.39 },
    ["fluid-wagon"] = { ["iron-ore"] = 0, ["copper-ore"] = 0, ["stone"] = 0, ["coal"] = 0, ["water-barrel"] = 0.63, ["crude-oil-barrel"] = 0.29 },
    -- ["artillery-wagon"] = { ["iron-ore"] = 0.71, ["copper-ore"] = 0.6, ["stone"] = 0.9, ["coal"] = 0.32, ["uranium-ore"] = 0.83, ["crude-oil-barrel"] = 0.24 },
    -- ["small-biter"] = { ["iron-ore"] = 0.99, ["copper-ore"] = 0.81, ["stone"] = 0.24, ["coal"] = 0.3, ["uranium-ore"] = 0.12, ["crude-oil-barrel"] = 0.26 },
    -- ["medium-biter"] = { ["iron-ore"] = 0.69, ["copper-ore"] = 0.65, ["stone"] = 0.67, ["coal"] = 0.79, ["uranium-ore"] = 0.94, ["crude-oil-barrel"] = 0.71 },
    -- ["big-biter"] = { ["iron-ore"] = 0.25, ["copper-ore"] = 0.15, ["stone"] = 0.55, ["coal"] = 0.44, ["uranium-ore"] = 0.23, ["crude-oil-barrel"] = 0.18 },
    -- ["behemoth-biter"] = { ["iron-ore"] = 0.38, ["copper-ore"] = 0.27, ["stone"] = 0.24, ["coal"] = 0.28, ["uranium-ore"] = 0.97, ["crude-oil-barrel"] = 0.45 },
    -- ["small-spitter"] = { ["iron-ore"] = 0.36, ["copper-ore"] = 0.64, ["stone"] = 0.28, ["coal"] = 0.11, ["uranium-ore"] = 0.58, ["crude-oil-barrel"] = 0.05 },
    -- ["medium-spitter"] = { ["iron-ore"] = 0.73, ["copper-ore"] = 0.69, ["stone"] = 0.91, ["coal"] = 0.13, ["uranium-ore"] = 0.17, ["crude-oil-barrel"] = 0.35 },
    -- ["big-spitter"] = { ["iron-ore"] = 0.86, ["copper-ore"] = 0.21, ["stone"] = 0.54, ["coal"] = 0.61, ["uranium-ore"] = 0.49, ["crude-oil-barrel"] = 0.6 },
    -- ["behemoth-spitter"] = { ["iron-ore"] = 0.63, ["copper-ore"] = 0.08, ["stone"] = 0.73, ["coal"] = 0.73, ["uranium-ore"] = 0.88, ["crude-oil-barrel"] = 0.53 },
    -- ["small-worm-turret"] = { ["iron-ore"] = 0.71, ["copper-ore"] = 0.99, ["stone"] = 0.92, ["coal"] = 0.69, ["uranium-ore"] = 0.71, ["crude-oil-barrel"] = 0.9 },
    -- ["medium-worm-turret"] = { ["iron-ore"] = 0.61, ["copper-ore"] = 0.19, ["stone"] = 0.74, ["coal"] = 0.21, ["uranium-ore"] = 0.18, ["crude-oil-barrel"] = 0.65 },
    -- ["big-worm-turret"] = { ["iron-ore"] = 0.95, ["copper-ore"] = 0.09, ["stone"] = 0.23, ["coal"] = 0.05, ["uranium-ore"] = 0.8, ["crude-oil-barrel"] = 0.92 },
    -- ["behemoth-worm-turret"] = { ["iron-ore"] = 0.21, ["copper-ore"] = 0.06, ["stone"] = 0.76, ["coal"] = 0.6, ["uranium-ore"] = 0.82, ["crude-oil-barrel"] = 0.09 },
    ["gun-turret"] = { ["iron-ore"] = 0.4655, ["copper-ore"] = 0.2755, ["stone"] = 0.0997, ["coal"] = 0.133, ["uranium-ore"] = 0, ["crude-oil-barrel"] = 0 },
    ["flamethrower-turret"] = { ["iron-ore"] = 0.4655, ["copper-ore"] = 0.2755, ["stone"] = 0.00, ["coal"] = 0.2, ["uranium-ore"] = 0, ["crude-oil-barrel"] = 0.05 },
    ["laser-turret"] = { ["iron-ore"] = 0.94, ["copper-ore"] = 0.15, ["stone"] = 0.71, ["coal"] = 0.67, ["uranium-ore"] = 0.01, ["crude-oil-barrel"] = 0.01 },
    -- ["artillery-turret"] = { ["iron-ore"] = 0.77, ["copper-ore"] = 0.21, ["stone"] = 0.97, ["coal"] = 0.36, ["uranium-ore"] = 0.73, ["crude-oil-barrel"] = 0.52 },
    ["land-mine"] = { ["iron-ore"] = 0.81, ["copper-ore"] = 0.94, ["stone"] = 0.44, ["coal"] = 1, ["uranium-ore"] = 0, ["crude-oil-barrel"] = 0 },
    -- ["poison-cloud"] = { ["iron-ore"] = 0.84, ["copper-ore"] = 0.13, ["stone"] = 0.66, ["coal"] = 0.24, ["uranium-ore"] = 0.54, ["crude-oil-barrel"] = 0.49 },
    -- ["defender"] = { ["iron-ore"] = 0.68, ["copper-ore"] = 0.54, ["stone"] = 0.66, ["coal"] = 0.85, ["uranium-ore"] = 0.15, ["crude-oil-barrel"] = 0.27 },
    -- ["distractor"] = { ["iron-ore"] = 0.68, ["copper-ore"] = 0.83, ["stone"] = 0.22, ["coal"] = 0.74, ["uranium-ore"] = 0.46, ["crude-oil-barrel"] = 0.79 },
    -- ["destroyer"] = { ["iron-ore"] = 0.51, ["copper-ore"] = 0.38, ["stone"] = 0.37, ["coal"] = 0.9, ["uranium-ore"] = 0.2, ["crude-oil-barrel"] = 0.46 },
    -- ["spidertron"] = { ["iron-ore"] = 0.25, ["copper-ore"] = 0.1, ["stone"] = 0.74, ["coal"] = 0.67, ["uranium-ore"] = 0.19, ["crude-oil-barrel"] = 0.27 },
    -- ["tank"] = { ["iron-ore"] = 0.23, ["copper-ore"] = 0.13, ["stone"] = 0.94, ["coal"] = 0.61, ["uranium-ore"] = 0.59, ["crude-oil-barrel"] = 0.29 },

    -- Acid should produce uranium than normal
    ["acid-splash-fire-worm-small"] = { ["iron-ore"] = 0, ["copper-ore"] = 0, ["stone"] = 0, ["coal"] = 0, ["uranium-ore"] = 0.005, ["crude-oil-barrel"] = 0 },
    ["acid-splash-fire-worm-medium"] = { ["iron-ore"] = 0, ["copper-ore"] = 0, ["stone"] = 0, ["coal"] = 0, ["uranium-ore"] = 0.005, ["crude-oil-barrel"] = 0 },
    ["acid-splash-fire-worm-big"] = { ["iron-ore"] = 0, ["copper-ore"] = 0, ["stone"] = 0, ["coal"] = 0, ["uranium-ore"] = 0.005, ["crude-oil-barrel"] = 0} ,
    ["acid-splash-fire-worm-behemoth"] = { ["iron-ore"] = 0, ["copper-ore"] = 0, ["stone"] = 0, ["coal"] = 0, ["uranium-ore"] = 0.005, ["crude-oil-barrel"] = 0 },
    ["acid-splash-fire-spitter-small"] = { ["iron-ore"] = 0, ["copper-ore"] = 0, ["stone"] = 0, ["coal"] = 0, ["uranium-ore"] = 0.03, ["crude-oil-barrel"] = 0 },
    ["acid-splash-fire-spitter-medium"] = { ["iron-ore"] = 0, ["copper-ore"] = 0, ["stone"] = 0, ["coal"] = 0, ["uranium-ore"] = 0.03, ["crude-oil-barrel"] = 0 },
    ["acid-splash-fire-spitter-big"] = { ["iron-ore"] = 0, ["copper-ore"] = 0, ["stone"] = 0, ["coal"] = 0, ["uranium-ore"] = 0.03, ["crude-oil-barrel"] = 0 },
    ["acid-splash-fire-spitter-behemoth"] = { ["iron-ore"] = 0, ["copper-ore"] = 0, ["stone"] = 0, ["coal"] = 0, ["uranium-ore"] = 0.03, ["crude-oil-barrel"] = 0 },

    ["default"] = { ["iron-ore"] = 0.04655, ["copper-ore"] = 0.02755, ["stone"] = 0.00997, ["coal"] = 0.0133, ["uranium-ore"] = 0, ["crude-oil-barrel"] = 0.01 }
    -- ["default"] = { ["empty-barrel"] = 1} -- for debugging
}

-- Function to determine the number of items to drop based on damage and probability.
local function determineDropCounts(items, damageAmount)
    local dropCounts = {}
    for item, probability in pairs(items) do
        -- For each item, decide whether to drop it based on its probability.
        if math.random() < probability then
            -- Ensure damageAmount is at least 1 to avoid invalid range for math.random
            local adjustedDamageAmount = math.max(1, damageAmount/1.5)
            dropCounts[item] = math.random(1, adjustedDamageAmount) -- Randomize the count between 1 and the damage amount
        end
    end
    return dropCounts
end

-- Function to handle item spillage near the entity.
-- surface: The surface where the entity is located.
-- EntityPosition: The position of the entity.
-- itemName: The name of the item to be spilled.
-- itemCount: The number of items to spill.
local function groupSpillItems(surface, EntityPosition, itemName, itemCount)
    -- Define the search radius around the entity for existing spilled items.
    local searchRadius = 10 -- A small radius to optimize performance.
    
    -- Calculate the search area based on the entity's position and the search radius.
    local searchArea = {
        {EntityPosition.x - searchRadius, EntityPosition.y - searchRadius},
        {EntityPosition.x + searchRadius, EntityPosition.y + searchRadius}
    }

    -- Find all item entities within the defined search area.
    local existingItems = surface.find_entities_filtered{
        type = "item-entity",
        name = "item-on-ground",
        area = searchArea
    }

    -- Iterate through the found item entities to try and add to existing stacks.
    for _, itemEntity in pairs(existingItems) do
        -- Check if the item entity matches the item type we're spilling.
        if itemEntity.stack.name == itemName then
            -- Calculate how many items can be added to the existing stack.
            local canAdd = itemEntity.stack.prototype.stack_size - itemEntity.stack.count
            -- Determine the number of items to add, which is the lesser of the remaining spill amount or the stack capacity.
            local toAdd = math.min(canAdd, itemCount)
            -- Add the items to the stack.
            itemEntity.stack.count = itemEntity.stack.count + toAdd
            -- Reduce the itemCount by the number of items added.
            itemCount = itemCount - toAdd
            -- If all items have been spilled, exit the function.
            if itemCount <= 0 then
                return
            end
        end
    end

    -- If there are items left to spill after trying to add to existing stacks, spill them as a new item entity.
    if itemCount > 0 then
        surface.spill_item_stack(EntityPosition, {name=itemName, count=itemCount}, true)
    end
end


-- Register an event handler for when an entity is damaged.
script.on_event(defines.events.on_entity_damaged, 
    function(event)
        -- Function to spill item stacks at the damaged entity's location.
        local spillStack = event.entity.surface.spill_item_stack
        local spillItems = function(itemName, itemCount) 
        spillStack(event.entity.position, {name=itemName, count=itemCount})
    end

    -- Determine the cause of damage and set the default damage category.
    local causeEntity = event.cause
    local damageCategory = "default" -- Default category is used if no specific cause is found.
    local damageAmount = event.final_damage_amount

    -- Skip spillage if damage amount is too small.
    if damageAmount < 1 then
        return
    end

    -- It should not be possible for an entity to have taken more damage than it has for health.
    if damageAmount > event.entity.health then
        damageAmount = event.entity.health
    end

    -- Check if the cause is defined in our damage categories table.
    if causeEntity and damage_categories[causeEntity.name] then
        damageCategory = causeEntity.name
    else
        -- Print the name of the unknown damage source, this is used for debugging only
        if causeEntity then
            --game.print("Unknown damage source: " .. causeEntity.name)
        end
    end

    -- Randomly choose items to drop based on the damage category's probabilities.
    local dropCounts = determineDropCounts(damage_categories[damageCategory], damageAmount)

    -- Drop the items.
    for item, count in pairs(dropCounts) do
        --event.entity.surface.spill_item_stack(event.entity.position, {name = item, count = count}, true)
        groupSpillItems(event.entity.surface, event.entity.position, item, count)
    end
end)

-- Stop ore generation on map
script.on_event(defines.events.on_chunk_generated, function(event)
    local area = event.area
    local surface = event.surface
    -- Loop through all entities in the generated chunk
    for _, entity in pairs(surface.find_entities(area)) do
        -- Check if the entity is an ore resource
        if entity.type == "resource" then
            -- You can also check for specific ores by name, e.g., "iron-ore", "copper-ore"
            -- if entity.name == "iron-ore" then
            entity.destroy()
            -- end
        end
    end
end)
