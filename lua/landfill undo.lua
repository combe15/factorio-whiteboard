--[[
  Truly undoes landfill. Regenerates the original chunks in a separate surface to see which water/
  shore tiles used to be under the landfill, copies from those tiles, and cleans up afterwards.

  Ends in an unterminated quote, intended to contain map pings.
  Will select a box region around all pings.
  Any number of pings 2+ will work, but it's most intuitive to ping 2 opposing corners, or 4 sides.
  Insert pings into the command line, and then a closing quote " before using.
--]]

/silent-command --[[ undo landfill 2.0 ]]
local function bounding_box_from_gps_tags(s)
  local a,b,c,d,m,M=1/0,1/0,-1/0,-1/0,math.min,math.max
  for x,y in s:gmatch("%[gps=([+-]?%d+),([+-]?%d+)%]")do a=m(a,x+0)b=m(b,y+0)c=M(c,x+0)d=M(d,y+0)end
  return{left_top={x=a,y=b},right_bottom={x=c,y=d}}
end
local function count_in(t, s)
  t[s] = (t[s] or 0) + 1
end
local function go2(gps)
  local surface = game.player.surface
  local s2 = game.create_surface("undo_landfill", surface.map_gen_settings)
  local bb = bounding_box_from_gps_tags(gps)
  local new_water,counts = {},{}
  for _,t in pairs(surface.find_tiles_filtered{area=bb, name="landfill"}) do
    local pos = t.position
    if surface.count_entities_filtered{collision_mask={"ghost-layer","object-layer","player-layer"}, area={left_top=pos, right_bottom={pos.x+1,pos.y+1}}} > 0 then
      count_in(counts, "skipped")
    else
      new_water[#new_water+1] = { position=pos, name="" }
      s2.request_to_generate_chunks(pos, 0)
    end
  end
  s2.force_generate_chunk_requests()
  for _,nw in pairs(new_water) do
    nw.name = s2.get_tile(nw.position.x, nw.position.y).name
    count_in(counts, nw.name)
  end
  surface.set_tiles(new_water)
  game.player.print("undo landfill:")
  for name,count in pairs(counts) do
    game.player.print("    "..name..": "..count)
  end
end
local function go(...)
  local ok, result = pcall(go2, ...)
  if not ok then game.player.print(result) end
  if game.get_surface("undo_landfill") then game.delete_surface("undo_landfill") end
end
go "
