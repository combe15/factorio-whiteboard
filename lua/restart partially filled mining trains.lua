/c for _,ent in pairs (game.player.force.get_trains()) do      
    if ent.station then          
        local st = ent.schedule.records[ent.schedule.current].station         
        if string.sub(st, 1, 5) == "[Exit" then             
            local loco = ent.locomotives.front_movers[1]             
            ent.go_to_station(1)         
        end     
    end 
end
