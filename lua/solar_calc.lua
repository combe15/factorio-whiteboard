/silent-command
--[[ 
  Calculates how many solar pannels are needed to transition away from nuke power. 
]]
local stats = (game.player.selected 
  or game.player.surface.find_entities_filtered{type="electric-pole",limit=1,position=game.player.position,radius=32}[1] 
  or error("Script needs mouseover of electric pole.", 0)).electric_network_statistics 
local function printf(...) game.print(string.format(...)) end 
local function flow_count(name) 
  return stats.get_flow_count{name=name, input=false, precision_index=defines.flow_precision_index.ten_minutes, count=true} 
end 
local function go(args) 
  local accumulators, panels, turbines = flow_count("accumulator"), flow_count("solar-panel"), flow_count("steam-turbine") 
  local solar_ratio = accumulators / panels 
  local excess_accumulators = accumulators - math.ceil(panels * 21 / 25) 
  printf("%d [img=item.accumulator] / %d [img=item.solar-panel] = %.4g    (%+d accumulators vs. ideal ratio)", accumulators, panels, solar_ratio, excess_accumulators) 
  local usable_panels = math.min(panels, math.floor(accumulators * 25 / 21)) 
  local solarGW = usable_panels * 42 / 1000000 
  local total = 0 
  for i,_ in pairs(stats.input_counts) do 
    if game.entity_prototypes[i].type ~= 'accumulator' then 
      total = total + stats.get_flow_count{name=i, input=true, precision_index=defines.flow_precision_index.ten_minutes} 
    end 
  end 
  local totalGW = total * 60 / 1000000000 
  printf("%d usable panels = %.2f GW usable power (total)", usable_panels, solarGW) 
  printf("Required power (10 min. av.) = %.2f GW", totalGW) 
  if turbines > 0 then 
    local nuke_builds = turbines / args.nuke_bp_turbines 
    local nukeGW = nuke_builds * args.nuke_bp_gw 
    printf("%.4g nuke builds = %.2f GW", nuke_builds, nukeGW) 
    if not args.goalGW then 
      args.goalGW = totalGW 
    end 
    local nukeGW_needed_for_goal = math.max(0, args.goalGW - solarGW) 
    local needed_nukes = math.ceil(nukeGW_needed_for_goal / args.nuke_bp_gw) 
    local lacking_nukes = needed_nukes - nuke_builds 
    printf("... need %d nuke builds (%+.4g vs. current) for goal %.2f GW", needed_nukes, lacking_nukes, args.goalGW) 
  end 
end 
go{nuke_bp_turbines=224, nuke_bp_gw=1.12, goalGW=nil}