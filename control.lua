require "searchlight-defines"
require "searchlight-render"

local searchLights = {}
local real_sl_to_lsp = {} -- lsp == last shooting position
local dummy_to_turtle = {}
local turtle_to_waypoint = {}
local firing_arcs = {}

script.on_event(defines.events.on_tick, function(event)
    InitForces()

    for surfaceName, surface in pairs(game.surfaces) do
        searchLights = surface.find_entities_filtered{name = {"searchlight",
                                                              "searchlight-dummy"}}

        -- 'sl' for 'SearchLight'
        for index, sl in pairs(searchLights) do
            BoostFriends(sl, surface)

            if sl.name == "searchlight" then
                ConsiderFoes(sl, surface)
            else
                ConsiderTurtles(sl, surface)
            end
        end
    end
end)


function ConsiderFoes(sl, surface)
    if sl.shooting_target == nil then
        local pos = real_sl_to_lsp[sl.unit_number]
        real_sl_to_lsp[sl.unit_number] = nil
        CreateDummyLight(sl, surface, pos)
    else
        real_sl_to_lsp[sl.unit_number] = sl.shooting_target.position
    end
end


function ConsiderTurtles(sl, surface)
    -- If the worst happened somehow, and our turtle is no more, make a new one
    if dummy_to_turtle[sl.unit_number] == nil then
        SpawnTurtle(sl, surface)
    end

    local turtle = dummy_to_turtle[sl.unit_number]

    -- If a foe is close to the turret, auto spot it
    -- (find_nearest_enemy(force=) means "which force's enemies to seek")
    local foe = surface.find_nearest_enemy{position = sl.position,
                                           max_distance = searchlightInnerRange,
                                           force = "player"}

    if foe ~= nil then
        RushTurtle(turtle, foe.position)
    end

    -- If a foe is within the radius of the beam, spot it
    foe = surface.find_nearest_enemy{position = turtle.position,
                                     max_distance = searchlightSpotRadius,
                                     force = "player"}

    if foe ~= nil then
        CreateRealLight(sl, surface, foe)
        return
    end

    -- If nothing needs done with foes, we're free to fully contemplate our turtle
    WanderTurtle(turtle, sl)
end


-- location is expected to be the real spotlight's last shooting target,
-- if it was targeting something.
function SpawnTurtle(sl, surface, location)
    if location == nil then
        game.print(sl.orientation)
        -- Start somewhere close to the turret's base & orientation
        location = OrientationToPosition(sl.position, sl.orientation, 2)
    end

    local turtle = surface.create_entity{name = "searchlight-turtle",
                                         position = location,
                                         force = searchlightFoe,
                                         fast_replace = true,
                                         create_build_effect_smoke = false}

    turtle.destructible = false
    new_sl.shooting_target = turtle
    dummy_to_turtle[new_sl.unit_number] = turtle

    local windupWaypoint = OrientationToPosition(sl.position,
                                                 sl.orientation,
                                                 math.random(searchlightInnerRange/2,
                                                             searchlightOuterRange - 2))
    WanderTurtle(turtle, sl, windupWaypoint)

    return turtle
end


function CreateDummyLight(old_sl, surface, last_shooting_position)
    new_sl = surface.create_entity{name = "searchlight-dummy",
                                   position = old_sl.position,
                                   force = searchlightFriend,
                                   fast_replace = true,
                                   create_build_effect_smoke = false}

    -- TODO delay this until the unpacking animation is finished,
    --      or have an instant unpack, or something.
    --      Because our orientation is apparently always zero while that's running.
    SpawnTurtle(new_sl, surface, last_shooting_position)

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


function WanderTurtle(turtle, sl, waypoint)
    if turtle_to_waypoint[turtle.unit_number] == nil
       or len(turtle.position, turtle_to_waypoint[turtle.unit_number])
          < searchlightSpotRadius then

        if waypoint == nil then
            waypoint = MakeWanderWaypoint(sl.position)
        end

        turtle_to_waypoint[turtle.unit_number] = waypoint
        turtle.speed = searchlightWanderSpeed

        turtle.set_command({type = defines.command.go_to_location,
                            distraction = defines.distraction.none,
                            destination = waypoint,
                            pathfind_flags = {low_priority = true},
                            radius = 1
                           })
    end
end


function RushTurtle(turtle, waypoint)
    if turtle_to_waypoint[turtle.unit_number] == nil
       or turtle_to_waypoint[turtle.unit_number] ~= waypoint then

        turtle_to_waypoint[turtle.unit_number] = waypoint
        turtle.speed = searchlightTrackSpeed

        turtle.set_command({type = defines.command.go_to_location,
                            distraction = defines.distraction.none,
                            destination = waypoint,
                            radius = 1
                           })
    end
end


function MakeWanderWaypoint(origin)
    local bufferedRange = searchlightOuterRange - 2
     -- 0 - 1 inclusive. If you supply arguments, math.random will return ints not floats.
    local angle = math.random()
    local distance = math.random(searchlightInnerRange/2, bufferedRange)

    return OrientationToPosition(origin, angle, distance)
end


-- theta given as 0.0 - 1.0, 0/1 is top middle of screen
function OrientationToPosition(origin, theta, distance)
    local radTheta = theta * 2 * math.pi

    return {x = origin.x + math.sin(radTheta) * distance,
            y = origin.y + math.cos(radTheta) * distance,}
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
    -- since we can't discover this at runtime.
    -- (It's just as well, foes any closer probably don't merit any boosting)
    if foeLen <= 12 then
        return nil

    elseif oldT.type == "electric-turret" and foeLen >= elecBoost then
        return nil

    elseif oldT.type == "ammo-turret" and foeLen >= ammoBoost then
        return nil

    -- TODO Also calculate firing arc, somehow
    elseif foeLen >= fluidBoost then

        -- turn_range = 1.0 / 3.0 for flame turrets...
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
        CopyItems(oldT.get_output_inventory(), newT.get_output_inventory())
    end

    if oldT.get_module_inventory() ~= nil then
        CopyItems(oldT.get_module_inventory(), newT.get_module_inventory())
    end

    if oldT.get_fuel_inventory() ~= nil then
        CopyItems(oldT.get_fuel_inventory(), newT.get_fuel_inventory())
    end

    if oldT.get_burnt_result_inventory() ~= nil then
        CopyItems(oldT.get_burnt_result_inventory(), newT.get_burnt_result_inventory())
    end

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


function CopyItems(oldTinv, newTinv)

    for boxindex = 1, #oldTinv do
        local oldStack = oldTinv[boxindex]
        local newStack = newTinv[boxindex]

        newStack = oldStack
        newTinv.insert(newStack)
    end

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


function LookupArc()
    for E in pairs(game.entity_prototypes) do
        if E.attack_parameters
           and E.attack_parameters.turn_range then
            firing_arcs[E.name] = E.attack_parameters.turn_range
        end
    end

    game.print(serpent.block(firing_arcs))
end