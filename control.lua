require "searchlight-defines"
require "searchlight-render"

global.searchLights = {}
global.real_sl_to_lsp = {} -- lsp == last shooting position
global.dummy_to_turtle = {}
global.turtle_to_waypoint = {}
global.firing_arcs = {}
global.firing_range = {}
global.unboost_timers = {}

-- These we don't need to put in the globals, since it's fine to recalulate them on game load
-- (We'll do that at the bottom of the file, here)
local DirectionToVector = {}


script.on_init(
function(event)
    InitForces()
end)

script.on_load(
function(event)
    InitTables()
end)

script.on_event(defines.events.on_tick,
function(event)
     -- TODO move to mod init
    HandleSearchlights()
end)

script.on_event(defines.events.on_built_entity,
function(event)

    -- event.created_entity.dosomething

end,
{{filter="type", type = "turret"},
 {filter="name", name = "searchlight"}})

script.on_event(defines.events.on_entity_died,
function(event)

    if event.entity.name == "searchlight-turtle" then
        game.print("dead turtle")
    end

end,
{{filter="type", type = "turret"},
 {filter="type", type = "unit"},
 {filter="name", name = "searchlight"},
 {filter="name", name = "searchlight-dummy"},
 {filter="name", name = "searchlight-turtle"}})

script.on_event(defines.events.on_pre_player_mined_item,
function(event)

end,
{{filter="type", type = "turret"},
 {filter="name", name = "searchlight"},
 {filter="name", name = "searchlight-dummy"}})

function HandleSearchlights()
    for surfaceName, surface in pairs(game.surfaces) do
        global.searchLights = surface.find_entities_filtered{name = {"searchlight",
                                                              "searchlight-dummy"}}

        -- 'sl' for 'SearchLight'
        for index, sl in pairs(global.searchLights) do
            BoostFriends(sl, surface)

            if sl.name == "searchlight" then
                ConsiderFoes(sl, surface)
            else
                ConsiderTurtles(sl, surface)
            end
        end
    end
end


function ConsiderFoes(sl, surface)
    if sl.shooting_target == nil then
        if BoostTimerComplete(sl) then
            local pos = global.real_sl_to_lsp[sl.unit_number]
            global.real_sl_to_lsp[sl.unit_number] = nil
            CreateDummyLight(sl, surface, pos)
        end
    else
        global.real_sl_to_lsp[sl.unit_number] = sl.shooting_target.position
    end
end


function ConsiderTurtles(sl, surface)
    -- If a foe is close to the turret, auto spot it
    -- (find_nearest_enemy(force=) means "which force's enemies to seek")
    local foe = surface.find_nearest_enemy{position = sl.position,
                                           max_distance = searchlightInnerRange,
                                           force = "player"}

    -- If the worst happened somehow, and our turtle is no more, make a new one
    if global.dummy_to_turtle[sl.unit_number] == nil then
        SpawnTurtle(sl, surface)
    end

    local turtle = global.dummy_to_turtle[sl.unit_number]

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
        -- Start in front of the turret's base, wrt orientation
        location = OrientationToPosition(sl.position, sl.orientation, 3)
    end

    local turtle = surface.create_entity{name = "searchlight-turtle",
                                         position = location,
                                         force = searchlightFoe,
                                         fast_replace = true,
                                         create_build_effect_smoke = false}

    turtle.destructible = false
    new_sl.shooting_target = turtle
    global.dummy_to_turtle[new_sl.unit_number] = turtle


    local windupWaypoint = OrientationToPosition(sl.position,
                                                 sl.orientation,
                                                 math.random(searchlightInnerRange / 2,
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

    CopyTurret(old_sl, new_sl)

    SpawnTurtle(new_sl, surface, last_shooting_position)

    old_sl.destroy()
end


function CreateRealLight(old_sl, surface, foe)
    new_sl = surface.create_entity{name = "searchlight",
                                   position = old_sl.position,
                                   force = "player",
                                   fast_replace = true,
                                   create_build_effect_smoke = false}

    if global.dummy_to_turtle[old_sl.unit_number] ~= nil then
        global.dummy_to_turtle[old_sl.unit_number].destroy()
        global.dummy_to_turtle[old_sl.unit_number] = nil
    end

    CopyTurret(old_sl, new_sl)

    old_sl.destroy()

    global.unboost_timers[new_sl.unit_number] = boostDelay

    if foe then
        new_sl.shooting_target = foe
    end
end


function WanderTurtle(turtle, sl, waypoint)
    if not turtle.has_command()
       or global.turtle_to_waypoint[turtle.unit_number] == nil
       or len(turtle.position, global.turtle_to_waypoint[turtle.unit_number])
          < searchlightSpotRadius then

        if waypoint == nil then
            waypoint = MakeWanderWaypoint(sl.position)
        end

        global.turtle_to_waypoint[turtle.unit_number] = waypoint
        turtle.speed = searchlightWanderSpeed

        turtle.set_command({type = defines.command.go_to_location,
                            distraction = defines.distraction.none,
                            destination = waypoint,
                            pathfind_flags = {low_priority = true, cache = true,
                                              allow_destroy_friendly_entities = true,
                                              allow_paths_through_own_entities = true},
                            radius = 1
                           })
    end
end


function RushTurtle(turtle, waypoint)
    if global.turtle_to_waypoint[turtle.unit_number] == nil
       or global.turtle_to_waypoint[turtle.unit_number] ~= waypoint then

        global.turtle_to_waypoint[turtle.unit_number] = waypoint
        turtle.speed = searchlightTrackSpeed

        turtle.set_command({type = defines.command.go_to_location,
                            distraction = defines.distraction.none,
                            destination = waypoint,
                            pathfind_flags = {prefer_straight_paths = true, no_break = true,
                                              allow_destroy_friendly_entities = true,
                                              allow_paths_through_own_entities = true},
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

    -- Invert y to fit screen coordinates
    return {x = origin.x + math.sin(radTheta) * distance,
            y = origin.y + math.cos(radTheta) * distance * -1,}
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

    if not BoostTimerComplete(oldT) then
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
    if game.entity_prototypes[oldT.name .. boostSuffix] == nil then
        return nil
    end

    local foeLen = len(foe.position, oldT.position)

    -- Foes any closer probably don't merit any boosting
    if foeLen <= 12 then
        return nil

    elseif foeLen <= LookupRange(oldT) and oldT.shooting_target ~= nil then
        return nil

    elseif oldT.type == "electric-turret" and foeLen >= elecBoost then
        return nil

    elseif oldT.type == "ammo-turret" and foeLen >= ammoBoost then
        return nil

    elseif foeLen >= fluidBoost then
        return nil

    elseif not IsPositionWithinTurretArc(foe.position, oldT) then
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

    global.unboost_timers[newT.unit_number] = boostDelay

   return newT
end


function CopyTurret(oldT, newT)
    newT.copy_settings(oldT)
    newT.kills = oldT.kills
    newT.health = oldT.health
    newT.last_user  = oldT.last_user
    newT.direction = oldT.direction
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


-- "Do note that reading from a LuaFluidBox creates a new table and writing will copy the given fields from the table into the engine's own fluid box structure.
--  Therefore, the correct way to update a fluidbox of an entity is to read it first, modify the table, then write the modified table back.
--  Directly accessing the returned table's attributes won't have the desired effect."
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


-- TODO If multiple searchlights are checking this, then we're going to very rapidly wind down this timer...
--      So, maybe it's time to bite the bullet and implement oncreated/destroyed(searchlight).
--      Then, we can build an index for all the turrets in range of any light, and just iterate through that for Boost / UnBoost, etc
--      (We still need to think about how to figure in for power consumption...)
-- TODO Also, we should re-increment this number if there's a shooting target. Probably in this function.
function BoostTimerComplete(turret)
   if global.unboost_timers[turret.unit_number] and global.unboost_timers[turret.unit_number] > 0 then
        global.unboost_timers[turret.unit_number] = global.unboost_timers[turret.unit_number] - 1
        return false
    else
        global.unboost_timers[turret.unit_number] = nil
        return true
    end
end


function IsPositionWithinTurretArc(pos, turret)
    local arc = LookupArc(turret)

    if arc <= 0 then
        return true
    end

    local arcRad = arc * math.pi

    local vecTurPos = {x = pos.x - turret.position.x,
                       y = pos.y - turret.position.y}
    local vecTurDir = DirectionToVector[turret.direction]

    local tanPos = math.atan2(vecTurPos.y, vecTurPos.x)
    local tanDir = math.atan2(vecTurDir.y, vecTurDir.x)

    local angleL = tanDir - tanPos
    local angLAdjust = angleL
    if angLAdjust < 0 then
        angLAdjust = angLAdjust + (math.pi * 2)
    end

    local angleR = tanPos - tanDir
    local angRAdjust = angleR
    if angRAdjust < 0 then
        angRAdjust = angRAdjust + (math.pi * 2)
    end

    return angLAdjust < arcRad or angRAdjust < arcRad
end


function len(a, b)
    return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2)
end


function LookupArc(turret)
    if global.firing_arcs[turret.name] then
        return global.firing_arcs[turret.name]
    end

    local tPrototype = game.entity_prototypes[turret.name]

    if tPrototype.attack_parameters
       and tPrototype.attack_parameters.turn_range then
        global.firing_arcs[turret.name] = tPrototype.attack_parameters.turn_range
    else
        global.firing_arcs[turret.name] = -1
    end

    return global.firing_arcs[turret.name]
end


function LookupRange(turret)
    if global.firing_range[turret.name] then
        return global.firing_range[turret.name]
    end

    local tPrototype = game.entity_prototypes[turret.name]

    if tPrototype.turret_range then
        global.firing_range[turret.name] = tPrototype.turret_range
    elseif tPrototype.attack_parameters
       and tPrototype.attack_parameters.range then
        global.firing_range[turret.name] = tPrototype.attack_parameters.range
    else
        global.firing_range[turret.name] = -1
    end

    return global.firing_range[turret.name]
end


function InitForces()
    game.create_force(searchlightFoe)
    game.create_force(searchlightFriend)

    for F in pairs(game.forces) do
        game.forces[searchlightFoe].set_cease_fire(F, true)
        game.forces[searchlightFriend].set_cease_fire(F, true)

        game.forces[F].set_cease_fire(searchlightFoe, true)
        game.forces[F].set_cease_fire(searchlightFriend, true)
    end

    game.forces[searchlightFriend].set_friend("player", true)
    game.forces[searchlightFriend].set_cease_fire(searchlightFoe, false)
end


function InitTables()
    -- Directions come as a number between 0 and 8 (as used in defines.direction)
    -- Let's represent them as vectors, as aligned to the screen-coordinate system
    DirectionToVector[defines.direction.north]     = {x =  0, y = -1}
    DirectionToVector[defines.direction.northwest] = {x = -1, y = -1}
    DirectionToVector[defines.direction.west]      = {x = -1, y =  0}
    DirectionToVector[defines.direction.southwest] = {x = -1, y =  1}
    DirectionToVector[defines.direction.south]     = {x =  0, y =  1}
    DirectionToVector[defines.direction.southeast] = {x =  1, y =  1}
    DirectionToVector[defines.direction.east]      = {x =  1, y =  0}
    DirectionToVector[defines.direction.northeast] = {x =  1, y = -1}
end
