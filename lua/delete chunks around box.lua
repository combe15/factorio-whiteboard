/c
--[[
  optional but you may want to run it so biters won't be generated after chunks are removed
]]
local player = game.player
local surface = player.surface
surface.clear_pollution()
surface.peaceful_mode = true
game.map_settings.pollution.enabled = false
game.map_settings.enemy_evolution.enabled = false
game.map_settings.enemy_expansion.enabled = false
for c in surface.get_chunks() do
for key, entity in   pairs(surface.find_entities_filtered({area={{c.x * 32, c.y * 32}, {c.x * 32 + 32, c.y * 32 + 32}}, force= "enemy"})) do
   entity.destroy()
end
end

/c
ltx = 227
lty = 278
rbx = 597
rby = 3964
for chunk in game.player.surface.get_chunks() do
  a = chunk.area
  if not (a.left_top.x > ltx and a.right_bottom.x < rbx and
    a.left_top.y > lty and a.right_bottom.y < rby) then
    game.player.surface.delete_chunk({chunk.x, chunk.y})
  end
end