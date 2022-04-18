/silent-command
a='/silent-command\nlocal p = game.player\nlocal c = p.clear_personal_logistic_slot\nlocal s = p.set_personal_logistic_slot for k = 1, 1000 do c(k) end;\n' 
for i=1, 1000, 1 do 
    slot = game.player.get_personal_logistic_slot(i)
    if slot.name then 
        a = a .. string.format(
            "s( %d, {max = %d, min = %d, name = \"%s\"});\n", 
            i, slot.max, slot.min, slot.name )  
    end
end 
game.write_file("player_logistic_request_slots_command.txt",a)