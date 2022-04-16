/c 
-- Count how many ghost solar pannels and ghost accumulators
game.print(#game.player.surface.find_entities_filtered({ghost_type={'solar-panel','accumulator'}}))
