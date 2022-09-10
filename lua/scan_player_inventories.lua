/c  

local x=''  

for k,v in pairs(game.players) do    
  if not v.connected then     
    inv = v.get_inventory(defines.inventory.character_main)     
    if inv ~= nil then        
      if inv.count_empty_stacks() ~= #inv then         
        x = x .. ', ' .. v.name  .. ': ' .. inv.count_empty_stacks() .. '/' .. #inv
      end     
    else       
      [[-- ragequit detector (could also be admin horseplay) --]]
      x = x .. ', ' .. v.name .. ': ??/??'     
    end   
  end  
end

game.print(x) 
