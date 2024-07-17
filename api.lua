local S = archaeology.translate

function archaeology.random(chance)
    local random2 = math.random(1, 100)
    return random2 <= chance
end

function archaeology.register_loot(def)
    if not minetest.registered_items[def.name] then
        error("Item doesnt exist.")
    end
    table.insert(archaeology.registered_loot, def)
end

function archaeology.register_sus(name, def)
    local def2 = {
        description = S("Suspicous").." "..def.description,
        tiles = {def.archaeology_texture..".png^archaeology_suspicious.png"},
        groups = def.groups,
        sounds = def.sound,
        _ARCH_texture = def.archaeology_texture,
        _ARCH_instrument = def.archaeology_tool,
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
    minetest.register_node(name, def2)
    archaeology.registered_sus[name] = def2
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
    for i, i_guess in ipairs(archaeology.registered_loot) do
        total = total+1
    end
    if total == 0 then
        minetest.log("error", "Cant spawn an archaeology loot at "..pos.x.." "..pos.y.." "..pos.z.." ("..node.name..")")
        return
    end
    local def = archaeology.registered_loot[math.random(1, total)]
    local inc = meta:get("archaeology_placed_player")
    if inc == "false" then
        if archaeology.random(def.chance) then
            minetest.add_item({x=pos.x, y=pos.y, z=pos.z}, def.name)
        end
    end
    minetest.remove_node(pos)
end
