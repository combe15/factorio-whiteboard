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
