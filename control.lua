require "searchlight-defines"
require "searchlight-render"

local searchLights = {}
local hiddenSL_to_dummy = {}
local hiddenSL_to_sl = {}
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
        searchLights = surface.find_entities_filtered{name = "searchlight_dummy"}

        for index, sl in pairs(searchLights) do
            ConsiderFoes(sl, surface)
        end
    end
end)

function ConsiderFriendsAndTurtles(sl, surface)
    local foe = sl.shooting_target

    if foe == nil then
        CreateDummyLight(sl.position, surface)
        sl.destroy()
    else
        local friends = surface.find_entities_filtered{force = sl.force,
                                                       type = "electric-turret",
                                                       max_distance = searchlightFriendRadius}
        for index, F in pairs(friends) do
            if BoostableElectric(F) then
                -- TODO clone or teleport original object somwhere safe??
                -- Then swap boosted version in, and swap it back out when its done
                -- (And remember to increment kill count + damage done somehow, preserve health changes, etc)
                -- TODO also need to handle construction ghosts, etc
                F.shooting_target = foe
            end
        end
    end
end

function ConsiderFoes(sl, surface)
    -- If a foe is close to the turret, auto spot it
    -- (find_nearest_enemy argument 'force' means "which force's enemies to seek")
    local foe = surface.find_nearest_enemy{position = sl.position,
                                           max_distance = searchlightInnerRange,
                                           force = searchlightFriend}

    if foe ~= nil then
        CreateRealLight(sl, surface)
        return
    end

    -- If a foe is within the radius of the beam, spot it
    if dummy_to_turtle[sl.unit_number] ~= nil then
        local turtle = dummy_to_turtle[sl.unit_number]
        foe = surface.find_nearest_enemy{position = turtle.position,
                                         max_distance = searchlightSpotRadius,
                                         force = searchlightFriend}

        if foe ~= nil then
            local newLight = CreateRealLight(sl, surface)
            newLight.shooting_target = foe
        end
    end
end

function SpawnTurtle(position, surface)
    game.print("SpawnTurtle")

    -- local newPos = makeWanderWaypoint(position)
    local newPos = {position.x, position.y - 50}

    return surface.create_entity{name = "searchlight_turtle",
                                 position = newPos,
                                 force = searchlightFoe}
end

function CreateDummyLight(position, surface)
    game.print("CreateDummyLight")
    sl = surface.create_entity{name = "searchlight_dummy",
                               position = position,
                               force = "player"}

    dummy_to_turtle[sl.unit_number] = SpawnTurtle(sl.position, surface)
    sl.shooting_target = dummy_to_turtle[sl.unit_number]
    return sl
end

function CreateRealLight(sl, surface)
    game.print("CreateRealLight")
    new_sl = surface.create_entity{name = "searchlight",
                                   position = sl.position,
                                   force = "player"}

    if dummy_to_turtle[sl.unit_number] ~= nil then
        game.print("DestroyTurtle")
        dummy_to_turtle[sl.unit_number].destroy()
        dummy_to_turtle[sl.unit_number] = nil
    else
        game.print("d to t was nil")
    end

    sl.destroy()

    return new_sl
end

function makeWanderWaypoint(origin)
    local bufferedRange = searchlightOuterRange - 5
    return {x = origin.x + math.random(-bufferedRange, bufferedRange),
            y = origin.y + math.random(-bufferedRange, bufferedRange)}
end

function BoostableElectric(F)
    if F.shooting_target == nil and len (foe, F) < elecBoost then
        return true
    end

    return false
end


function InitForces()
        for F in pairs(game.forces) do
            game.forces[searchlightFoe].set_cease_fire(F, true)
            game.forces[F].set_cease_fire(searchlightFoe, true)
        end

        game.forces["player"].set_cease_fire(searchlightFoe, false)
        game.forces[searchlightFriend].set_cease_fire(searchlightFoe, true)
end