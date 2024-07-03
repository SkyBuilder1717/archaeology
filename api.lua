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
    if not minetest.registered_items[name] then
        error("Item doesnt exist.")
    end
    archaeology.registered_sus[name] = def
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
    if meta:get_string("archaeology_in_creative") == "true" then
        local total = 0
        for i, i_guess in ipairs(archaeology.registered_loot) do
            total = total+1
        end
        minetest.remove_node(pos)
        if total == 0 then
            minetest.log("error", "Cant spawn an archaeology loot at "..pos.x.." "..pos.y.." "..pos.z.." ("..node.name..")")
            return
        end
        local def = archaeology.registered_loot[math.random(1, total)]
        if archaeology.random(def.chance) then
            minetest.add_item({x=pos.x, y=pos.y, z=pos.z}, def.name)
        end
    end
end
