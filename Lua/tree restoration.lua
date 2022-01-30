--[[
  Many players don't understand that mass-clearing trees causes problems at endgame. With the
  script, no one has to get upset if some new player does this without realizing. It's easy to use.

  Ends in an unterminated quote, intended to contain map pings.
  Will select a box region around all pings.
  Any number of pings 2+ will work, but it's most intuitive to ping 2 opposing corners, or 4 sides.
  Insert pings into the command line, and then a closing quote " before using.

  Will actually restore any chunk that touches the region, as the restore feature is chunk-based.
--]]

/sc --[[ HISTORICALLY ACCURATE TREE RESTORATION --]]
local TREES = {}
for tree,_ in pairs(game.get_filtered_entity_prototypes({{filter="type",type="tree"}})) do
  TREES[#TREES+1] = tree
end
local function bounding_box_from_gps_tags(s)
  local x1 = math.huge
  local y1,x2,y2 = x1,-x1,-x1
  for x,y in s:gmatch("%[gps=([+-]?%d+),([+-]?%d+)%]") do
    x1 = math.min(x1, x+0)
    y1 = math.min(y1, y+0)
    x2 = math.max(x2, x+0)
    y2 = math.max(y2, y+0)
  end
  return { left_top = {x=x1,y=y1}, right_bottom = {x=x2,y=y2} }
end
local function chunks_at_least_partly_inside(surface, bb)
  local result = {}
  for c in surface.get_chunks() do
    if c.area.left_top.x <= bb.right_bottom.x and
       c.area.left_top.y <= bb.right_bottom.y and
       c.area.right_bottom.x >= bb.left_top.x and
       c.area.right_bottom.y >= bb.left_top.y
    then
      result[#result+1] = c
    end
  end
  return result
end
local function go(s)
  local surface = game.player.surface
  local chunks = chunks_at_least_partly_inside(surface, bounding_box_from_gps_tags(s))
  if #chunks > 0 then
    surface.regenerate_entity(TREES, chunks)
    game.print("Restored default trees to " .. #chunks .. " chunks.")
  end
end
go "
