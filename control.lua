require "searchlight-defines"
require "searchlight-render"

local searchLights = {}
local dummy_to_turtle = {}

script.on_event(defines.events.on_tick, function(event)
    InitForces()

    for surfaceName, surface in pairs(game.surfaces) do
        searchLights = surface.find_entities_filtered{name = "searchlight"}

        -- 'sl' for 'SearchLight'
        for index, sl in pairs(searchLights) do
            ConsiderFriendsAndTurtles(sl, surface)
        end
    end

    for surfaceName, surface in pairs(game.surfaces) do
        searchLights = surface.find_entities_filtered{name = "searchlight-dummy"}

        for index, sl in pairs(searchLights) do
            ConsiderFoes(sl, surface)
        end
    end
end)

function ConsiderFriendsAndTurtles(sl, surface)
    local foe = sl.shooting_target

    if foe == nil then
        CreateDummyLight(sl, surface)
    else
        local electfriends = surface.find_entities_filtered{position = sl.position,
                                                            type = "electric-turret",
                                                            radius = searchlightFriendRadius}
        for index, F in pairs(electfriends) do
            if not UnBoostElectric(F, surface) then
                BoostElectric(F, surface, foe)
            end
        end

        local fluidfriends = surface.find_entities_filtered{position = sl.position,
                                                            type = "fluid-turret",
                                                            radius = searchlightFriendRadius}
        for index, F in pairs(fluidfriends) do
            -- if not UnBoostElectric(F, surface) then
                BoostFluid(F, surface, foe)
            -- end
        end
    end
end

function ConsiderFoes(sl, surface)
    -- If a foe is close to the turret, auto spot it
    -- (find_nearest_enemy argument 'force' means "which force's enemies to seek")
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
            local newLight = CreateRealLight(sl, surface)
            newLight.shooting_target = foe
            return
        end
    end

    local friends = surface.find_entities_filtered{position = sl.position,
                                                   type = "electric-turret",
                                                   radius = searchlightFriendRadius}
    for index, F in pairs(friends) do
        UnBoostElectric(F, surface)
    end
end

-- TODO go back to the drawing board a little
--      make the turtle not a foe of the player
--      make the dummy search light a separate force from the player
--      and do a more thorough copy of it (including entity.color, lastUser, etc)
function SpawnTurtle(position, surface)
    -- local newPos = MakeWanderWaypoint(position)
    local newPos = {position.x, position.y - 50}

    return surface.create_entity{name = "searchlight_turtle",
                                 position = newPos,
                                 force = searchlightFoe,
                                 create_build_effect_smoke = false}
end

function CreateDummyLight(old_sl, surface)
    new_sl = surface.create_entity{name = "searchlight-dummy",
                                   position = old_sl.position,
                                   force = searchlightFriend,
                                   create_build_effect_smoke = false}

    dummy_to_turtle[new_sl.unit_number] = SpawnTurtle(new_sl.position, surface)
    new_sl.shooting_target = dummy_to_turtle[new_sl.unit_number]

    CopySL(old_sl, new_sl)

    old_sl.destroy()

    return new_sl
end

function CreateRealLight(old_sl, surface)
    new_sl = surface.create_entity{name = "searchlight",
                                   position = old_sl.position,
                                   force = "player",
                                   create_build_effect_smoke = false}

    if dummy_to_turtle[old_sl.unit_number] ~= nil then
        dummy_to_turtle[old_sl.unit_number].destroy()
        dummy_to_turtle[old_sl.unit_number] = nil
    end

    CopySL(old_sl, new_sl)

    old_sl.destroy()

    return new_sl
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

function BoostElectric(oldT, surface, foe)
    if oldT.shooting_target ~= nil
       or game.entity_prototypes[oldT.name .. boostSuffix] == nil
       or len (foe.position, oldT.position) > elecBoost then
        return nil
    end

    local newT = surface.create_entity{name = oldT.name .. boostSuffix,
                                       position = oldT.position,
                                       force = oldT.force,
                                       create_build_effect_smoke = false}

    CopyElectT(oldT, newT)
    oldT.destroy()

    newT.shooting_target = foe

   return newT
end

function UnBoostElectric(oldT, surface)
    if oldT.shooting_target ~= nil
       or not string.match(oldT.name, boostSuffix) then
        return nil
    end

    local newT = surface.create_entity{name = oldT.name:gsub(boostSuffix, ""),
                                       position = oldT.position,
                                       force = oldT.force,
                                       create_build_effect_smoke = false}

    CopyElectT(oldT, newT)
    oldT.destroy()

   return newT
end

function BoostFluid(oldT, surface, foe)
    if oldT.shooting_target ~= nil
       or game.entity_prototypes[oldT.name .. boostSuffix] == nil
       or len (foe.position, oldT.position) > fluidBoost then
        return nil
    end

    local newT = surface.create_entity{name = oldT.name .. boostSuffix,
                                       position = oldT.position,
                                       force = oldT.force,
                                       create_build_effect_smoke = false}

    CopyFluidT(oldT, newT)
    oldT.destroy()

    newT.shooting_target = foe

   return newT
end

function CopySL(oldT, newT)
    newT.copy_settings(oldT)
    newT.kills = oldT.kills
    newT.health = oldT.health
    newT.last_user  = oldT.last_user
    newT.orientation = oldT.orientation
    newT.damage_dealt = oldT.damage_dealt

    newT.energy = oldT.energy
end

function CopyElectT(oldT, newT)
    newT.copy_settings(oldT)
    newT.kills = oldT.kills
    newT.health = oldT.health
    newT.last_user  = oldT.last_user
    newT.orientation = oldT.orientation
    newT.damage_dealt = oldT.damage_dealt

    newT.energy = oldT.energy
end

-- TODO Transfer ammo inventory and partial ammo usages for ammo & fluid turrets
-- TODO Copy wire connections

function CopyFluidT(oldT, newT)
    newT.copy_settings(oldT)
    newT.kills = oldT.kills
    newT.health = oldT.health
    newT.last_user  = oldT.last_user
    newT.orientation = oldT.orientation
    newT.damage_dealt = oldT.damage_dealt

    -- TODO
end


function InitForces()
    for F in pairs(game.forces) do
        game.forces[searchlightFoe].set_cease_fire(F, true)
        game.forces[searchlightFriend].set_cease_fire(F, true)

        game.forces[F].set_cease_fire(searchlightFoe, true)
        game.forces[F].set_cease_fire(searchlightFriend, true)
    end

    game.forces[searchlightFriend].set_friend("player", true)
    game.forces[searchlightFriend].set_cease_fire(searchlightFoe, false)
end