/silent-command
--[[ 
  Launch or stop trains. Default launches all trains in region.
  Change 'go' to 'stop' at the end of the script to stop trains.
  
  Ends in an unterminated quote, intended to contain map pings.
  Will select a box region around all pings.
  Any number of pings 2+ will work, but it's most intuitive to ping 2 opposing corners, or 4 sides.
  Insert pings into the command line, and then a closing quote " before using.
--]]
local function bounding_box_from_gps_tags(s)
  local a,b,c,d,m,M=1/0,1/0,-1/0,-1/0,math.min,math.max
  for x,y in s:gmatch("%[gps=([+-]?[%d%.]+),([+-]?[%d%.]+)%]")do a=m(a,x+0)b=m(b,y+0)c=M(c,x+0)d=M(d,y+0)end
  return{left_top={x=a,y=b},right_bottom={x=c,y=d}}
end
local function go(gps,stop)
  local surface = game.player.surface
  local bb = bounding_box_from_gps_tags(gps)
  local count = 0
  for _,loco in pairs(surface.find_entities_filtered{type="locomotive",area=bb}) do
    if loco.train.manual_mode and not stop then
      loco.train.manual_mode = false
      count = count + 1
    end
    if stop and not loco.train.manual_mode then
      loco.train.manual_mode = true
      count = count + 1
    end
  end
  if not stop then
    game.player.print("Launched " ..count.. " trains.")
  else
    game.player.print("Stopped " ..count.. " trains.")
  end
end
local function stop(gps) go(gps,true) end
go "
