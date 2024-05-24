local modpath = minetest.get_modpath("archaeology")
archaeology = {
    S = minetest.get_translator("archaeology"),
    registered_loot = {}
}
Sdef = minetest.get_translator("default"),
dofile(modpath .."/api.lua")

if minetest.settings:get_bool("archaeology_default_loot", true) then
    archaeology.register_loot({name="default:stick", chance=75})
    archaeology.register_loot({name="default:flint", chance=70})
    archaeology.register_loot({name="default:diamond", chance=25})
    archaeology.register_loot({name="default:dirt", chance=80})
    archaeology.register_loot({name="default:mese_crystal", chance=15})
    archaeology.register_loot({name="default:cactus", chance=75})
    archaeology.register_loot({name="default:steel_ingot", chance=45})
    archaeology.register_loot({name="default:gold_ingot", chance=20})
    archaeology.register_loot({name="default:coal_lump", chance=65})
    archaeology.register_loot({name="farming:string", chance=67})
end

minetest.register_node("archaeology:sand", {
	description = archaeology.S("Suspicous").." "..Sdef("Sand"),
	tiles = {"default_sand.png^archaeology_suspicious.png"},
	groups = {crumbly = 3, falling_node = 1},
	sounds = default.node_sound_sand_defaults(),
    drop = {
		items = {
			{items = {""}}
		}
	},
})

minetest.register_node("archaeology:gravel", {
	description = archaeology.S("Suspicous").." "..Sdef("Gravel"),
	tiles = {"default_gravel.png^archaeology_suspicious.png"},
	groups = {crumbly = 2, falling_node = 1},
	sounds = default.node_sound_gravel_defaults(),
	drop = {
		items = {
			{items = {""}}
		}
	},
})

minetest.register_craft({
	output = "archaeology:brush",
	recipe = {
		{"farming:string", "farming:string", "farming:string"},
		{"", "default:bronze_ingot", ""},
		{"", "default:stick", ""},
	}
})

minetest.register_tool("archaeology:brush", {
	description = archaeology.S("Brush"),
	inventory_image = "archaeology_brush.png",
	groups = {tool = 1},
	on_use = function(itemstack, player, pointed_thing)
        local name = player:get_player_name()
        local pos = minetest.get_pointed_thing_position(pointed_thing)
        if (pos == nil) or not (pointed_thing.type == "node") then
            return
        end
        local node = minetest.get_node(pos)
        local meta = minetest.get_meta(pos)
        if node.name == "archaeology:gravel" or node.name == "archaeology:sand" then
            if meta:get_int("archaeology_is_ready") == nil then
                meta:set_int("archaeology_is_ready", 0)
            end
            minetest.sound_play({name = "archaeology_brush_"..math.random(1, 3)}, {to_player = name})
            meta:set_int("archaeology_is_ready", meta:get_int("archaeology_is_ready")+1)
            if meta:get_int("archaeology_is_ready") == 4 then
                archaeology.execute_loot(pos)
                if node.name == "archaeology:gravel" then
                    archaeology.particle_spawn(pos, "gravel", true)
                else
                    archaeology.particle_spawn(pos, "sand", true)
                end
            else
                if node.name == "archaeology:gravel" then
                    archaeology.particle_spawn(pos, "gravel")
                else
                    archaeology.particle_spawn(pos, "sand")
                end
            end
            --minetest.chat_send_player(name, dump(archaeology.registered_loot))
            itemstack:add_wear(180)
            player:set_wielded_item(itemstack)
        end
	end,
})

minetest.register_abm({
    label = "Sussy Gravel Appear",
    nodenames = {"default:gravel"},
    neighbors = {"default:stone"},
    interval = 100,
    chance = 66,
    min_y = -265,
    max_y = -5,
    action = function(pos)
        pos.y = pos.y+1
        minetest.add_node(pos, {name = "archaeology:gravel"})
    end,
})

minetest.register_abm({
    label = "Sussy Amogussy Sandy Spawny",
    nodenames = {"default:sand"},
    neighbors = {"default:stone"},
    interval = 110,
    chance = 95,
    min_y = -100,
    max_y = 10,
    action = function(pos)
        pos.y = pos.y+1
        minetest.add_node(pos, {name = "archaeology:sand"})
    end,
})