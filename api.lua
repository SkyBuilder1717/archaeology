local S = archaeology.translate

function archaeology.random(chance)
    local random2 = math.random(1, 100)
    return random2 <= chance
end

local function check_sus(v)
    if archaeology.registered_sus[v] then
        return true
    end
    return false
end

function archaeology.register_tool(name, def)
    -- Handlers of wrong parameters
    if (not def.uses_to_clear) or (def.uses_to_clear == 0) then def.uses_to_clear = 4 end
    if (not def.wear_per_use) or (def.wear_per_use > 65535) or (0 > def.wear_per_use) then def.wear_per_use = 180 end
    if (not def.per_use) or (def.per_use > 65535) or (0 > def.per_use) then def.per_use = 1 end
    if not def.texture then def.texture = {"archaeology_placeholder.png"} end
    if not def.groups then def.groups = {tool = 1} end
    if not def.tool_sound then def.tool_sound = "archaeology_brush" end

    minetest.register_tool(name, {
        description = def.description,
        inventory_image = def.texture,
        groups = def.groups,
        on_use = function(itemstack, player, pointed_thing)
            local name = player:get_player_name()
            local pos = minetest.get_pointed_thing_position(pointed_thing)
            if (pos == nil) or not (pointed_thing.type == "node") then
                return
            end
            local node = minetest.get_node(pos)
            local meta = minetest.get_meta(pos)
            local iname = itemstack:get_name()
            -- Checks, if the block is sussybaka
            if check_sus(node.name) then
                if not (archaeology.registered_sus[node.name]._ARCHAEOLOGY_instrument == iname) then
                    return
                end
                local is_ready = meta:get_int("archaeology_is_ready")
                if is_ready == nil then
                    meta:set_int("archaeology_is_ready", 0)
                end
                minetest.sound_play({name = def.tool_sound}, {to_player = name})
                meta:set_int("archaeology_is_ready", is_ready+def.per_use)
                if (is_ready == def.uses_to_clear) or (is_ready > def.uses_to_clear) then
                    archaeology.execute_loot(pos)
                    archaeology.particle_spawn(pos, minetest.registered_nodes[node.name]._ARCHAEOLOGY_texture, true)
                else
                    archaeology.particle_spawn(pos, minetest.registered_nodes[node.name]._ARCHAEOLOGY_texture)
                end
                itemstack:add_wear(def.wear_per_use)
                player:set_wielded_item(itemstack)
            end
        end,
    })
    archaeology.registered_tools[name] = def
end

function archaeology.register_loot(def)
    -- Error Handler
    if not minetest.registered_items[def.name] then
        error("Item doesnt exist.")
    end
    table.insert(archaeology.registered_loots, def)
end

function archaeology.register_sus(name, def)
    -- Handlers of wrong parameters
    if not def.archaeology_texture then def.archaeology_texture = {"unknown_node.png"} end
    if not def.groups then def.groups = {falling_node = 1} end
    if not def.archaeology_tool then
        error("Parameter \"archaeology_tool\" cannot be empty!")
    else
        if not minetest.registered_items[def.archaeology_tool] then
            error("Item doesnt exist.")
        end
    end

    local nodedef = {
        description = S("Suspicious").." "..def.description,
        tiles = {def.archaeology_texture..".png^archaeology_suspicious.png"},
        groups = def.groups,
        sounds = def.sound,
        _ARCHAEOLOGY_texture = def.archaeology_texture,
        _ARCHAEOLOGY_instrument = def.archaeology_tool,
        after_place_node = function(pos, placer, stack, pointed_thing)
            local meta = minetest.get_meta(pos)
            if placer:is_player() then
                local name = placer:get_player_name()
                if minetest.is_creative_enabled(name) then
                    meta:set_string("archaeology_in_creative", "true")
                else
                    meta:set_string("archaeology_in_creative", "false")
                end
                meta:set_string("archaeology_placed_player", "true")
                meta:set_string("owner", name)
                return
            end
            meta:set_string("archaeology_placed_player", "false")
        end,
        drop = {
            items = {
                {items = {""}}
            }
        },
    }
    minetest.register_node(name, nodedef)
    archaeology.registered_sus[name] = nodedef
end

function archaeology.particle_spawn(pos, texture, breaky)
    local par = {a = 10, t = 0.025}
    if breaky == true then
        par = {a = 25, t = 0.11}
    end
    minetest.add_particlespawner({
        amount = par.a,
        time = par.t,
        minpos = pos,
        maxpos = pos,
        minvel = {x = 2, y = 3, z = 2},
        maxvel = {x = -2, y = 1, z = -2},
        minacc = {x = 0, y = -10, z = 0},
        maxacc = {x = 0, y = -10, z = 0},
        minexptime = 0.5,
        maxexptime = 1,
        minsize = 1,
        maxsize = 1,
        collisiondetection = true,
        texture = texture..".png",
        vertical = false
    })
end

function archaeology.execute_loot(pos)
    local node = minetest.get_node(pos)
    local meta = minetest.get_meta(pos)
    local total = 0
    for i, i_guess in ipairs(archaeology.registered_loots) do
        total = total+1
    end
    if total == 0 then
        minetest.log("error", "Cant spawn an archaeology loot at "..pos.x.." "..pos.y.." "..pos.z.." ("..node.name..")")
        return
    end
    local def = archaeology.registered_loots[math.random(1, total)]
    local inc = meta:get("archaeology_placed_player")
    if inc == "false" then
        if archaeology.random(def.chance) then
            minetest.add_item({x=pos.x, y=pos.y, z=pos.z}, def.name)
        end
    end
    minetest.remove_node(pos)
end
