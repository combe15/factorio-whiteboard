/c 
count = game.player.force.current_research.research_unit_count
prog = math.floor(game.player.force.research_progress * count)
game.player.print(prog .. ' / ' .. count)
