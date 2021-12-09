/silent-command
local index = #game.player.get_main_inventory()
game.player.get_main_inventory().set_filter(index, "solar-panel-equipment"); index = index - 1;
game.player.get_main_inventory().set_filter(index, "fusion-reactor-equipment"); index = index - 1;
game.player.get_main_inventory().set_filter(index, "battery-mk2-equipment"); index = index - 1;
game.player.get_main_inventory().set_filter(index, "belt-immunity-equipment"); index = index - 1;
game.player.get_main_inventory().set_filter(index, "exoskeleton-equipment"); index = index - 1;
game.player.get_main_inventory().set_filter(index, "personal-roboport-mk2-equipment"); index = index - 1;
game.player.get_main_inventory().set_filter(index, "personal-laser-defense-equipment"); index = index - 1;
game.player.get_main_inventory().set_filter(index, "laser-turret"); index = index - 1;
game.player.get_main_inventory().set_filter(index, "artillery-targeting-remote"); index = index - 1;
game.player.get_main_inventory().set_filter(index, "spidertron"); index = index - 1;
game.player.get_main_inventory().set_filter(index, "spidertron-remote"); index = index - 1;