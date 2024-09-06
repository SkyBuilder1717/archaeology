local modpath = minetest.get_modpath("archaeology")
local S = minetest.get_translator("archaeology")
archaeology = {
    translate = S,
    registered_loots = {},
    registered_sus = {},
    registered_tools = {},
    formspace = {
        ["converter"] = {
            ["wait"] = "formspec_version[6]"..
                "size[10.5,11]"..
                "list[current_player;main;0.4,5.9;8,4;0]"..
                "list[context;input;4.8,2.5;1,1;0]"..
                "label[4.8,2.3;"..S("Wait...").."]",
            ["ok"] = "formspec_version[6]"..
                "size[10.5,11]"..
                "list[current_player;main;0.4,5.9;8,4;0]"..
                "list[context;input;4.8,2.5;1,1;0]"..
                "button[3.8,3.9;3,0.8;cook;"..S("Convert").."]",
        },
    },
}
local Sdef = minetest.get_translator("default")
dofile(modpath.."/api.lua")

local function check_sus(v)
    if archaeology.registered_sus[v] then
        return true
    end
    return false
end

if minetest.settings:get_bool("archaeology_default_loot", true) then
    archaeology.register_loot({name="default:stick", chance=75})
    archaeology.register_loot({name="default:flint", chance=65})
    archaeology.register_loot({name="default:diamond", chance=19})
    archaeology.register_loot({name="default:dirt", chance=60})
    archaeology.register_loot({name="default:mese_crystal", chance=15})
    archaeology.register_loot({name="default:cactus", chance=30})
    archaeology.register_loot({name="default:steel_ingot", chance=45})
    archaeology.register_loot({name="default:gold_ingot", chance=28})
    archaeology.register_loot({name="default:coal_lump", chance=65})
    if minetest.get_modpath("farming") then
        archaeology.register_loot({name="farming:string", chance=67})
    end
end

if minetest.settings:get_bool("archaeology_check_sus", false) then
    minetest.register_tool("archaeology:check_sus", {
        description = S("Check Sus Stick").."\n\n"..core.colorize("lightgrey", S("Right-Click to check sussy").."\n"..S("Left-Click to check placed suspocious node by player, or not")),
        inventory_image = "archaeology_check_sus.png",
        stack_max = 1,
        range = 19,
        groups = {tool = 1},
        on_place = function(itemstack, placer, pointed_thing)
            if (not placer:is_player()) or ((pointed_thing.type == "nothing") or (pointed_thing.type == "object")) then
                return
            end
            local pos = minetest.get_pointed_thing_position(pointed_thing)
            local node = minetest.get_node(pos)
            local name = placer:get_player_name()
            local sus = check_sus(node.name)
            local suscheck = check_sus(node.name)
            if sus then
                sus = core.colorize("lime", S("Yes"))
            else
                sus = core.colorize("red", S("No"))
            end
            if not minetest.is_creative_enabled(name) then
                itemstack:add_wear(10000)
                user:set_wielded_item(itemstack)
            end
            if suscheck then
                minetest.chat_send_player(name, S("@1, its a suspicous node. Can be cleared by @2!", sus, dump(archaeology.registered_sus[node.name]._ARCHAEOLOGY_instrument)))
                return
            end
            minetest.chat_send_player(name, S("@1, its not a suspicous node, this is a average node of game.", sus))
        end,
        on_use = function(itemstack, user, pointed_thing)
            if (pointed_thing.type == "nothing") or (pointed_thing.type == "object") then
                return
            end
            local pos = minetest.get_pointed_thing_position(pointed_thing)
            local node = minetest.get_node(pos)
            if not user:is_player() then
                return
            elseif not check_sus(node.name) then
                return
            end
            local meta = minetest.get_meta(pos)
            local name = user:get_player_name()
            local creative = S(meta:get_string("archaeology_in_creative"))
            if creative == "true" then
                creative = core.colorize("red", creative)
            else
                creative = core.colorize("green", creative)
            end
            local placed = meta:get_string("archaeology_placed_player")
            local placed_by = meta:get_string("owner")
            if not minetest.is_creative_enabled(name) then
                itemstack:add_wear(10000)
                user:set_wielded_item(itemstack)
            end
            if placed == "true" then
                minetest.chat_send_player(name, S("That suspicous node has been placed (@1) by player @2.", core.colorize("grey", S("In creative? @1", creative)), core.colorize("lightgrey", placed_by)))
                return
            end
            minetest.chat_send_player(name, core.colorize("lime", S("This suspicous node has been generated by mapgen nearby player!")))
        end,
    })
end

if minetest.settings:get_bool("archaeology_vase", true) then
    minetest.register_node("archaeology:ceramic", {
        tiles = {"archaeology_piece_node.png"},
        walkable = false,
        damage_per_second = 3,
        stack_max = 16,
        paramtype = "light",
        drawtype = "plantlike",
        sounds = default.node_sound_glass_defaults(),
        groups = {crumbly = 3, oddly_breakable_by_hand = 1, attached_node = 1, not_in_creative_inventory = 1},
        on_destruct = function(pos)
            minetest.add_item(pos, "archaeology:piece")
        end,
        drop = {
            items = {
                {items = {""}}
            }
        },
    })
    minetest.register_craftitem("archaeology:piece", {
        description = S("Ceramic Piece"),
        inventory_image = "archaeology_vase_piece.png",
        stack_max = 16,
        on_use = function(itemstack, user, pointed_thing)
            local pos = minetest.get_pointed_thing_position(pointed_thing, pointed_thing.above)
            minetest.set_node(pos, {name="archaeology:ceramic"})
            itemstack:take_item()
            user:set_wielded_item(itemstack)
        end,
    })
    minetest.register_node("archaeology:vase", {
        description = S("Ceramic Vase"),
        tiles = {
            "archaeology_vase_top.png",
            "archaeology_vase_side.png",
            "archaeology_vase_side.png",
            "archaeology_vase_side.png",
            "archaeology_vase_side.png",
            "archaeology_vase_side.png"
        },
        inventory_image = "archaeology_vase_side.png",
        wield_image = "archaeology_vase_side.png",
        is_ground_content = false,
        drawtype = "nodebox",
        paramtype = "light",
        groups = {crumbly = 3, oddly_breakable_by_hand = 3, falling_node = 1, attached_node = 1},
        node_box = {
            type = "fixed",
            fixed = {
                {-0.3125, -0.5, -0.3125, 0.3125, 0.3125, 0.3125},
                {-0.125, 0.25, -0.125, 0.125, 0.4375, 0.125},
                {-0.1875, 0.375, -0.1875, 0.1875, 0.5, 0.1875},
            }
        },
        sounds = default.node_sound_glass_defaults(),
        drop = {
            items = {
                {
                    rarity = 3,
                    items = {"archaeology:piece"}
                },
                {
                    rarity = 3,
                    items = {"archaeology:piece"}
                },
                {
                    rarity = 3,
                    items = {"archaeology:piece"}
                },
                {
                    rarity = 2,
                    items = {"archaeology:piece"}
                }
            }
        },
        on_place = function(itemstack, placer, pointed_thing)
            minetest.item_place(itemstack, placer, pointed_thing)
            local pos = minetest.get_pointed_thing_position(pointed_thing, pointed_thing.above)
            local meta = minetest.get_meta(pos)
            local name = placer:get_player_name()
            meta:set_string("owner", name)
            local owner = meta:get_string("owner")
            meta:set_string('infotext1', S("Ceramic Vase").."\n"..S("Owner: ")..owner)
            meta:set_string('infotext2', S("Ceramic Vase").."\n"..S("Owner: ")..owner.."\n"..S("(Has item)"))
            meta:set_string("itemstring", "")
            local inf = meta:get_string("infotext1")
            meta:set_string('infotext', inf)
        end,
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            local meta = minetest.get_meta(pos)
            local owner = meta:get_string("owner")
            local inf1 = meta:get_string("infotext1")
            local inf2 = meta:get_string("infotext2")
            local name = clicker:get_player_name()
            if owner == name then
                local item = meta:get_string("itemstring") or ""
                if (item == "" not itemstack:is_empty()) then
                    local imeta = itemstack:get_meta()
                    meta:set_string("infotext", inf2)
                    meta:set_string("itemstring", itemstack:to_string())
		    itemstack:clear()
                    clicker:set_wielded_item(itemstack)
                elseif (item and itemstack:is_empty()) then
                    pos.y = pos.y+1
                    minetest.add_item(pos, item)
                    meta:set_string("infotext", inf1)
                    meta:set_string("itemstring", nil)
                end
            end
        end,
        on_dig = function(pos, node, digger)
            local meta = minetest.get_meta(pos)
            local owner = meta:get_string("owner")
            local name = digger:get_player_name()
            local item = meta:get_string("itemstring")
            if owner == name then
                if item == "" then
                    return minetest.node_dig(pos, node, digger)
                end
            end
        end,
    })
    minetest.register_alias("vase", "archaeology:vase")
    minetest.register_craft({
        output = "archaeology:vase",
        recipe = {
            {"", "archaeology:piece", ""},
            {"archaeology:piece", "", "archaeology:piece"},
            {"", "archaeology:piece", ""},
        }
    })
    minetest.register_node("archaeology:converter", {
        description = S("Ceramic Converter"),
        tiles = {"archaeology_ceramic_converter.png"},
        inventory_image = "archaeology_converter_inv.png",
        drawtype = "plantlike",
        groups = {falling_node = 1, cracky = 1, level = 2},
        is_ground_content = false,
        walkable = false,
        sounds = default.node_sound_metal_defaults(),
        on_construct = function(pos)
            local meta = minetest.get_meta(pos)
            local fm = archaeology.formspace["converter"]
	        meta:set_string('infotext', S("Ceramic Converter"))
            meta:set_string("formspec", fm["ok"])
	        local inv = meta:get_inventory()
	        inv:set_size('input', 1)
        end,
        on_dig = function(pos, node, digger)
            local meta = minetest.get_meta(pos)
	        local inv = meta:get_inventory()
            local itemstack = inv:get_stack('input', 1)
            if itemstack:is_empty() then
                return minetest.node_dig(pos, node, digger)
            end
        end,
        on_receive_fields = function(pos, formname, fields, sender)
            if fields["cook"] then
                local meta = minetest.get_meta(pos)
                local inv = meta:get_inventory()
                local itemstack = inv:get_stack('input', 1)
                local timer = minetest.get_node_timer(pos)
                local fm = archaeology.formspace["converter"]
                if itemstack:get_name() == "default:clay"then
                    timer:start(4)
                    meta:set_int("archaeology_converting", 1)
                    meta:set_string("formspec", fm["wait"])
                end
            end
        end,
	    on_timer = function(pos)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            local itemstack = inv:get_stack('input', 1)
            local fm = archaeology.formspace["converter"]
            meta:set_string("formspec", fm["ok"])
            if itemstack:get_name() == "default:clay" then
                meta:set_int("archaeology_converting", 0)
                inv:set_stack("input", 1, "archaeology:piece")
            end
        end,
        allow_metadata_inventory_put = function(pos, list_name, index, itemstack, player)
            if itemstack:get_name() == "default:clay" then
                return 1
            else
                return 0
            end
        end,
        allow_metadata_inventory_take = function(pos, list_name, index, itemstack, player)
            local meta = minetest.get_meta(pos)
            if (itemstack:get_name() == "default:clay" or itemstack:get_name() == "archaeology:piece") and meta:get_int("archaeology_converting") == 0 then
                return 1
            else
                return 0
            end
        end,
    })
    minetest.register_alias("converter", "archaeology:converter")
    minetest.register_alias("ceramic_converter", "archaeology:converter")
    if minetest.settings:get_bool("archaeology_default_loot", true) then
        archaeology.register_loot({name="archaeology:piece", chance=35})
        minetest.register_craft({
            output = "archaeology:converter",
            recipe = {
                {"", "archaeology:piece", ""},
                {"", "default:steel_ingot", ""},
                {"default:tin_ingot", "default:steelblock", "default:tin_ingot"},
            }
        })
    else
        minetest.register_craft({
            output = "archaeology:converter",
            recipe = {
                {"", "default:bronze_ingot", ""},
                {"", "default:steel_ingot", ""},
                {"default:tin_ingot", "default:steelblock", "default:tin_ingot"},
            }
        })
    end
end

archaeology.register_tool("archaeology:brush", {
    description = S("Brush"),
    texture = "archaeology_brush.png",
    groups = {tool = 1},
    tool_sound = "archaeology_brush",
    wear_per_use = 180,

    per_use = 1,
    uses_to_clear = 4,
})

archaeology.register_sus("archaeology:sand", {
    description = Sdef("Sand"),
	groups = {crumbly = 3, falling_node = 1},
	sound = default.node_sound_sand_defaults(),

    archaeology_tool = "archaeology:brush",
    archaeology_texture = "default_sand",
})
archaeology.register_sus("archaeology:gravel", {
    description = Sdef("Gravel"),
	groups = {crumbly = 2, falling_node = 1},
	sound = default.node_sound_gravel_defaults(),

    archaeology_tool = "archaeology:brush",
    archaeology_texture = "default_gravel",
})

minetest.register_craft({
	output = "archaeology:brush",
	recipe = {
		{"farming:string", "farming:string", "farming:string"},
		{"", "default:bronze_ingot", ""},
		{"", "default:stick", ""},
	}
})

minetest.register_abm({
    label = "Sussy Gravel Appear",
    nodenames = {"default:gravel"},
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
    interval = 110,
    chance = 95,
    min_y = -100,
    max_y = 1,
    action = function(pos)
        pos.y = pos.y+1
        minetest.add_node(pos, {name = "archaeology:sand"})
    end,
})

