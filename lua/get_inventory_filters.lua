/silent-command
--[[
  Saves what invtory filters you have and exports them into a txt file named "inventory_get_filter.txt"
]]
local a="/silent-command\n"; 
local inventory = game.player.get_main_inventory();
for k = 1, #inventory do
	if inventory.get_filter(k)~=nil then
		a=a ..string.format("game.player.get_main_inventory().set_filter(%d, \"%s\");\n", k, inventory.get_filter(k) );
	end;
end;
game.write_file("inventory_get_filter.txt",a)
