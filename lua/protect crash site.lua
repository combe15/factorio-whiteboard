--[[
  Make the crash site as an indestructible object.

  Since this is probably the first command on the map, make sure to enable commands:
]]
/config set allow-commands admins-only

--[[
  And then the command:
]]

/silent-command --[[ protect crash site ]]
local counts = {}
for _,e in pairs(game.player.surface.find_entities({{-64, -32}, {32, 32}})) do
  if e.name:match("^crash%-site") then
    e.minable = false
    e.destructible = false
    counts[e.name] = (counts[e.name] or 0) + 1
  end
end
game.player.print("protected:")
for name,count in pairs(counts) do
  game.player.print("    "..name..": "..count)
end
