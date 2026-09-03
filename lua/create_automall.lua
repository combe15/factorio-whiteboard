--/sc
--[[
https://www.reddit.com/r/factorio/comments/1uksfm1/craft_everything_machine_with_a_single_decider/
version >=2.1.9

how to use:
1) change the constants: minimum_items_desired, maximum_items_desired, ingredient_stock_multiplier
2) set the necessary recipes: local recipes = {}
3) select a decider-combinator in the game and run the script
4) use combinators in the build, see example BP
]]
--[[
    local quality = "legendary"
    local quality = "epic"
    local quality = "rare"
    local quality = "uncommon"
    local quality = "normal"]]
local minimum_items_desired = 1 --[[the default value, unless otherwise specified in the local recipes = {}]]
local maximum_items_desired = 1 --[[the default value, unless otherwise specified in the local recipes = {}]]
local ingredient_stock_multiplier = 1 --[[to start production you need this supply in chests(the default value)]]

local recipes = {
    {name = "carbonic-asteroid-crushing", quality = "normal"},
    {name = "oxide-asteroid-crushing", quality = "normal"},
    {name = "metallic-asteroid-crushing", quality = "normal"}
}

local recipes = {
    {name = "iron-chest", quality = "normal", min = 10, max = 100, mult = 5},
    {name = "iron-chest", quality = "uncommon"},
    {name = "iron-chest", quality = "rare"},
    {name = "iron-chest", quality = "epic"},
    {name = "iron-chest", quality = "legendary"},
    {name = "stack-inserter", quality = "normal"},
    {name = "stack-inserter", quality = "uncommon"},
    {name = "stack-inserter", quality = "rare"},
    {name = "stack-inserter", quality = "epic"},
    {name = "stack-inserter", quality = "legendary"}
}
--[[-------------------------------------------------]]
local function add_recipe_conditions(recipe, combinator, quality, product_amount, ingr_stock_multiplier, recipe_signal)
    for _, result in pairs(recipe.products) do
        combinator.add_condition {
            first_signal = {type = result.type, name = result.name, quality = quality},
            first_signal_networks = {red = true, green = false},
            constant = product_amount,
            comparator = "<",
            compare_type = "and"
        }
    end
    for _, ingredient in pairs(recipe.ingredients) do
        local ingredient_quality = ingredient.type == "item" and quality or "normal"
        local required_amount = ingredient.amount * ingr_stock_multiplier
        combinator.add_condition {
            first_signal = {type = ingredient.type, name = ingredient.name, quality = ingredient_quality},
            first_signal_networks = {red = true, green = false},
            constant = required_amount,
            comparator = ">=",
            compare_type = "and"
        }
    end
    combinator.add_condition {
        first_signal = {type = "virtual", name = "signal-each"},
        first_signal_networks = {green = true, red = false},
        second_signal_networks = {green = true, red = false},
        second_signal = recipe_signal,
        comparator = "=",
        compare_type = "and"
    }
end
--[[-------------------------------------------------]]
local function make_everything_combinator(entity)
    if not entity then
        return
    end
    local combinator = entity.get_control_behavior()
    combinator.parameters = {conditions = {}, outputs = {}, else_outputs = {}}

    combinator.add_condition {
        first_signal = {type = "virtual", name = "signal-each"},
        first_signal_networks = {red = true, green = false},
        constant = 0,
        comparator = "<",
        compare_type = "or"
    }

    local index = 0
    for _, r in pairs(recipes) do
        index = index + 1
        local quality = r.quality
        local recipe = prototypes.recipe[r.name]
        local l_min = r.min or minimum_items_desired
        local l_max = r.max or maximum_items_desired
        local l_mult = r.mult or ingredient_stock_multiplier

        local recipe_signal = {type = "recipe", name = recipe.name, quality = quality}
        combinator.add_output({signal = recipe_signal, constant = -index, copy_count_from_input = false})
        combinator.add_else_output({signal = recipe_signal, constant = -index, copy_count_from_input = false})
        combinator.add_condition {
            first_signal = {type = "virtual", name = "signal-everything"},
            first_signal_networks = {green = true, red = false},
            constant = 0,
            comparator = "<",
            compare_type = "or"
        }
        add_recipe_conditions(recipe, combinator, quality, l_min, l_mult, recipe_signal)
        combinator.add_condition {
            first_signal = recipe_signal,
            first_signal_networks = {green = true, red = false},
            constant = 0,
            comparator = ">",
            compare_type = "or"
        }
        add_recipe_conditions(recipe, combinator, quality, l_max, 1, recipe_signal)
    end
    --[[-------------------]]
    combinator.add_output(
        {
            signal = {type = "virtual", name = "signal-each"},
            constant = 10 * index * index,
            copy_count_from_input = false
        }
    )
end

make_everything_combinator(game.player.selected)
