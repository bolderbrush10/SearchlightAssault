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

        for index, sl in pairs(searchLights) do
            ConsiderTurtles(sl, surface)
        end
    end

    for surfaceName, surface in pairs(game.surfaces) do
        searchLights = surface.find_entities_filtered{name = "searchlight_dummy"}

        for index, sl in pairs(searchLights) do
            ConsiderFoes(sl, surface)
        end
    end
end)

-- 'sl' for 'SearchLight'
function ConsiderTurtles(sl, surface)
    local foe = sl.shooting_target

    if foe == nil then
        CreateDummyLight(sl.position, surface)
        sl.destroy()
    end
end

function ConsiderFoes(sl, surface)
    local foe = surface.find_nearest_enemy{position = sl.position,
                                           max_distance = searchlightInnerRange,
                                           force = searchlightFriend}

    if foe ~= nil then
        CreateRealLight(sl.position, surface)

        if dummy_to_turtle[sl.unit_number] ~= nil then
            game.print("DestroyTurtle")
            dummy_to_turtle[sl.unit_number].destroy()
            dummy_to_turtle[sl.unit_number] = nil
        else
            game.print("d to t was nil")
        end

        sl.destroy()
    end
end

function SpawnTurtle(position, surface)
    game.print("SpawnTurtle")

    local newPos = makeWanderWaypoint(position)

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

function CreateRealLight(position, surface)
    game.print("CreateRealLight")
    sl = surface.create_entity{name = "searchlight",
                               position = position,
                               force = "player"}
    return sl
end

function makeWanderWaypoint(origin)
    local bufferedRange = searchlightOuterRange - 5
    return {x = origin.x + math.random(-bufferedRange, bufferedRange),
            y = origin.y + math.random(-bufferedRange, bufferedRange)}
end

function InitForces()
        for F in pairs(game.forces) do
            game.forces[searchlightFoe].set_cease_fire(F, true)
            game.forces[F].set_cease_fire(searchlightFoe, true)
        end

        game.forces["player"].set_cease_fire(searchlightFoe, false)
        game.forces[searchlightFriend].set_cease_fire(searchlightFoe, true)
end