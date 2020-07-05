require "searchlight-defines"
require "searchlight-render"

local searchLights = {}
local dummy_to_turtle = {}


script.on_event(defines.events.on_tick, function(event)
    InitForces()

    for surfaceName, surface in pairs(game.surfaces) do
        searchLights = surface.find_entities_filtered{name = {"searchlight",
                                                              "searchlight-dummy"}}

        -- 'sl' for 'SearchLight'
        for index, sl in pairs(searchLights) do
            BoostFriends(sl, surface)

            if sl.name == "searchlight" then
                ConsiderTurtles(sl, surface)
            else
                ConsiderFoes(sl, surface)
            end
        end
    end
end)


-- TODO "walk" light from last shooting position to turtle
function ConsiderTurtles(sl, surface)
    if sl.shooting_target == nil then
        CreateDummyLight(sl, surface)
    end
end


-- TODO "walk" light from turtle to foe
function ConsiderFoes(sl, surface)
    -- If a foe is close to the turret, auto spot it
    -- (find_nearest_enemy(force=) means "which force's enemies to seek")
    local foe = surface.find_nearest_enemy{position = sl.position,
                                           max_distance = searchlightInnerRange,
                                           force = "player"}

    if foe ~= nil then
        CreateRealLight(sl, surface)
        return
    end

    -- If a foe is within the radius of the beam, spot it
    if dummy_to_turtle[sl.unit_number] ~= nil then
        local turtle = dummy_to_turtle[sl.unit_number]
        foe = surface.find_nearest_enemy{position = turtle.position,
                                         max_distance = searchlightSpotRadius,
                                         force = "player"}

        if foe ~= nil then
            CreateRealLight(sl, surface, foe)
        end
    end
end


function SpawnTurtle(position, surface)
    -- local newPos = MakeWanderWaypoint(position)
    local newPos = {position.x, position.y - 50}

    return surface.create_entity{name = "searchlight-turtle",
                                 position = newPos,
                                 force = searchlightFoe,
                                 fast_replace = true,
                                 create_build_effect_smoke = false}
end


function CreateDummyLight(old_sl, surface)
    new_sl = surface.create_entity{name = "searchlight-dummy",
                                   position = old_sl.position,
                                   force = searchlightFriend,
                                   fast_replace = true,
                                   create_build_effect_smoke = false}

    dummy_to_turtle[new_sl.unit_number] = SpawnTurtle(new_sl.position, surface)
    dummy_to_turtle[new_sl.unit_number].destructible = false
    dummy_to_turtle[new_sl.unit_number].speed = searchlightWanderSpeed
    new_sl.shooting_target = dummy_to_turtle[new_sl.unit_number]

    CopyTurret(old_sl, new_sl)

    old_sl.destroy()
end


function CreateRealLight(old_sl, surface, foe)
    new_sl = surface.create_entity{name = "searchlight",
                                   position = old_sl.position,
                                   force = "player",
                                   fast_replace = true,
                                   create_build_effect_smoke = false}

    if dummy_to_turtle[old_sl.unit_number] ~= nil then
        dummy_to_turtle[old_sl.unit_number].destroy()
        dummy_to_turtle[old_sl.unit_number] = nil
    end

    CopyTurret(old_sl, new_sl)

    old_sl.destroy()

    if foe then
        new_sl.shooting_target = foe
    end
end


function BoostFriends(sl, surface, foe)
    local friends = surface.find_entities_filtered{position = sl.position,
                                                   type =
                                                   {
                                                       "electric-turret",
                                                       "ammo-turret",
                                                       "fluid-turret",
                                                   },
                                                   radius = searchlightFriendRadius}

    -- ignore any 'foes' of the dummy seeking searchlight
    local foe = sl.name == "searchlight" and sl.shooting_target

    for index, turret in pairs(friends) do
        if not UnBoost(turret, surface) and foe then
            Boost(turret, surface, foe)
        end
    end
end

function UnBoost(oldT, surface)
    if oldT.shooting_target ~= nil
       or not string.match(oldT.name, boostSuffix) then
        return nil
    end

    local newT = surface.create_entity{name = oldT.name:gsub(boostSuffix, ""),
                                       position = oldT.position,
                                       force = oldT.force,
                                       fast_replace = true,
                                       create_build_effect_smoke = false}

    CopyTurret(oldT, newT)
    oldT.destroy()

    return newT
end

function Boost(oldT, surface, foe)
    if oldT.shooting_target ~= nil
       or game.entity_prototypes[oldT.name .. boostSuffix] == nil then
        return nil
    end

    local foeLen = len(foe.position, oldT.position)

    -- Just take a wild guess at minimum range for most turrets,
    -- since we can't discover this at runtime
    if foeLen <= 12 then
        return nil

    elseif oldT.type == "electric-turret" and foeLen >= elecBoost then
        return nil

    elseif oldT.type == "ammo-turret" and foeLen >= ammoBoost then
        return nil

    -- TODO Also calculate firing arc, somehow
    elseif foeLen >= fluidBoost then
        return nil

    end

    local newT = surface.create_entity{name = oldT.name .. boostSuffix,
                                       position = oldT.position,
                                       force = oldT.force,
                                       fast_replace = true,
                                       create_build_effect_smoke = false}

    CopyTurret(oldT, newT)
    oldT.destroy()

    newT.shooting_target = foe

   return newT
end

function CopyTurret(oldT, newT)
    newT.copy_settings(oldT)
    newT.kills = oldT.kills
    newT.health = oldT.health
    newT.last_user  = oldT.last_user
    newT.orientation = oldT.orientation
    newT.damage_dealt = oldT.damage_dealt

    if oldT.energy ~= nil then
        newT.energy = oldT.energy
    end

    if oldT.get_output_inventory() ~= nil then
        CopyItems(oldT, newT)
    end

    -- TODO fuel, module, and burnt_result inventories

    if oldT.fluidbox ~= nil then
        CopyFluids(oldT, newT)
    end
end

-- "Do note that reading from a LuaFluidBox creates a new table and writing will copy the given fields from the table into the engine's own fluid box structure. Therefore, the correct way to update a fluidbox of an entity is to read it first, modify the table, then write the modified table back. Directly accessing the returned table's attributes won't have the desired effect."
-- https://lua-api.factorio.com/latest/LuaFluidBox.html
function CopyFluids(oldT, newT)

    -- Must manually index this part, too.
    for boxindex = 1, #oldT.fluidbox do
        local oldFluid = oldT.fluidbox[boxindex]
        local newFluid = newT.fluidbox[boxindex]

        newFluid = oldFluid
        newT.fluidbox[boxindex] = newFluid
    end

end


-- TODO Yes, it seems to be working... But is it really?
--      Should try to test with like a car or something.
function CopyItems(oldT, newT)

    for boxindex = 1, #oldT.get_output_inventory() do
        local oldStack = oldT.get_output_inventory()[boxindex]
        local newStack = newT.get_output_inventory()[boxindex]

        newStack = oldStack
        newT.get_output_inventory().insert(newStack)
    end

end

function MakeWanderWaypoint(origin)
    local bufferedRange = searchlightOuterRange - 5
    return {x = origin.x + math.random(-bufferedRange, bufferedRange),
            y = origin.y + math.random(-bufferedRange, bufferedRange)}
end


-- TODO Can we trade accuracy for more speed?
function len(a, b)
    return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2)
end


function InitForces()
    -- game.create_force(searchlightFoe)
    -- game.create_force(searchlightFriend)

    for F in pairs(game.forces) do
        game.forces[searchlightFoe].set_cease_fire(F, true)
        game.forces[searchlightFriend].set_cease_fire(F, true)

        game.forces[F].set_cease_fire(searchlightFoe, true)
        game.forces[F].set_cease_fire(searchlightFriend, true)
    end

    game.forces[searchlightFriend].set_friend("player", true)
    game.forces[searchlightFriend].set_cease_fire(searchlightFoe, false)
end