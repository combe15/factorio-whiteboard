local handler = require("event_handler")
handler.add_lib(require("freeplay"))
handler.add_lib(require("silo-script"))

script.on_event(defines.events.on_entity_damaged, 
    function(event) 
        f = event.entity.surface.spill_item_stack
        g = function(n, a) f(event.entity.position, {name=n, count=a}) end
    
		d = event.final_damage_amount
		
		if d >= 4 then
			g("iron-ore", d/4)
			g("copper-ore", d/4)
		end
		if d >= 8 then
			g("coal", d/8)
			g("stone", d/8)
		end
		if d >= 200 then
			g("uranium-ore", d/200)
			g("crude-oil-barrel", d/200)
		end
    end)

