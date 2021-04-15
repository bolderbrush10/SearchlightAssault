require "searchlight-defines"
require "searchlight-grid"
require "searchlight-render" -- TODO remove
require "searchlight-util"


function InitTables()
  -- Map: searchlight unit_number -> Searchlight
  global.searchLights = {}

  -- Map: searchlight unit_number -> Dummylight
  global.sl_to_dummy = {}

  -- Map: dummylight unit_number -> Dummylight
  global.dummyLights = {}

  -- Map: searchlight unit_number -> Last shooting position
  global.real_sl_to_lsp = {}

  -- Map: eitherlight unit_number -> List: [Neighbor Turrets]
  global.sl_to_boostable = {}

  -- Map: dummylight unit_number -> Turtle
  global.dummy_to_turtle = {}

  -- Map: Turtle -> Position: [x,y]
  global.turtle_to_waypoint = {}

  -- Map: turtle unit_number -> Turtle
  global.tun_to_turtle = {}

  -- Map: searchlight unit_number -> remaining ticks
  global.unboost_timers = {}
end

function AddSearchlight(sl)
  global.sl_to_dummy[sl.unit_number] = sl.surface.create_entity{name="searchlight-dummy", position=sl.position, force=searchlightFriend}

  global.searchLights[sl.unit_number] = sl

  -- search for boostables and add
  -- TODO

  -- add to grid
  Grid_AddSpotlight(sl)

  local newPos = sl.position
  newPos.x = newPos.x + 5

  -- TODO initial turtle spawning logic here
   sl.surface.create_entity{name = "searchlight-turtle",
                                         position = newPos,
                                         force = searchlightFoe,
                                         fast_replace = true,
                                         create_build_effect_smoke = true}
end


function AddTurret(turret)

  -- search for spotlights in vicinity and add self as a boostable

end


function RemoveTurret(turret)

  -- search for spotlights in vicinity and remove self as a boostable

end


function RemoveSearchlight(sl)

  global.sl_to_dummy[sl.unit_number].destroy()
  global.sl_to_dummy[sl.unit_number] = nil

  global.searchLights[sl.unit_number] = nil

  -- remove from grid & foegrid
  Grid_RemoveSpotlight(sl)

  -- remove boostables
  -- TODO
end


function SwapSearchlight(old, new)
    -- copy settings
    -- copy over global entries, placement in, boostables, etc
    SwapTurret(old, new)

    -- TODO copy boostables
end


function SwapTurret(old, new)
    -- copy settings
    -- copy over global entries, placement in, etc
end

function SetAsBoostable(sl, turret)

  -- add to global list

end


function DecrementBoostTimers()

  -- decrement those timers

end


-- We wouldn't need this function if there was a way to transfer electricity between forces
-- !!! WAAIT A SECOND. They have to be able to share the electric network because the dummy was showing up on my electric network!
-- But then, on the other hand, we still need to "mirror" the electric usage & buffer between them....
function CheckElectricNeeds()
  for unit_num, sl in pairs(global.searchLights) do

    dummylight = global.sl_to_dummy[unit_num]

    if dummylight.active and sl.energy < searchlightCapacitorCutoff then
      dummylight.active = false
    elseif not dummylight.active and sl.energy > searchlightCapacitorStartable then
      dummylight.active = true
    end

  end
end


-- TODO Grids which can be skipped:
--  ones with no foes
--  ones with all spotlights engaged with a foe
--  ones with foes that don't move (how pathological can this case get though?)
function CheckForFoesNearSL(tick)
    Grid_UpdateFoeGrids(tick)


    -- for index, grid in pairs(spotlGrids) do
    --     if grid.foes then


          -- Basically what we want to do is check for each foe,
          -- look up all the neighboring grid tiles and check
          -- if there's a turret in the Outer / Inner Range and act accordingly


            -- for slindex, sl in grid.getNeighbors().spotlights do

            --     -- TODO Lights that can be skipped:
            --     --  ones already engaged with a foe

            --     if (sl.shooting_target is not nil) do

            --       -- Check for foes very close to each spotlight in grid
            --       foeList = find_entities_filtered{area=grid.area,
            --       -- Check for foes close to each turtle belonging to spotlight in grid

            --       -- If foe spotted, boost turrets belonging to spotlight

            --     end

            --end
        -- end
    -- end
end

-----------------------------------------------------------------------

function HandleSearchlights()
    -- 'sl' for 'SearchLight'
    for index, sl in pairs(global.searchLights) do
        BoostFriends(sl, sl.surface)

        if sl.name == "searchlight" then
            ConsiderFoes(sl, sl.surface)
        else
            ConsiderTurtles(sl, sl.surface)
        end
    end
end


function ConsiderFoes(sl, surface)
    if sl.shooting_target == nil then
        if BoostTimerComplete(sl) then
            local pos = global.real_sl_to_lsp[sl.unit_number]
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

    global.searchLights[new_sl.unit_number] = new_sl
    global.searchLights[old_sl.unit_number] = nil

    global.real_sl_to_lsp[old_sl.unit_number] = nil

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

    global.searchLights[new_sl.unit_number] = new_sl
    global.searchLights[old_sl.unit_number] = nil

    old_sl.destroy()

    global.unboost_timers[new_sl.unit_number] = boostDelay

    if foe then
        new_sl.shooting_target = foe
    end
end


function WanderTurtle(turtle, sl, waypoint)
    if not turtle.has_command()
       or global.turtle_to_waypoint[turtle.unit_number] == nil
       or lensquared(turtle.position, global.turtle_to_waypoint[turtle.unit_number])
          < square(searchlightSpotRadius) then

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

    local foeLenSq = lensquared(foe.position, oldT.position)

    -- Foes any closer probably don't merit any boosting
    if foeLenSq <= sqaure(12) then
        return nil

    elseif foeLenSq <= sqaure(LookupRange(oldT)) and oldT.shooting_target ~= nil then
        return nil

    elseif oldT.type == "electric-turret" and foeLenSq >= sqaure(elecBoost) then
        return nil

    elseif oldT.type == "ammo-turret" and foeLenSq >= sqaure(ammoBoost) then
        return nil

    elseif foeLenSq >= sqaure(fluidBoost) then
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






-- The idea here is to create two special forces.
-- The 'foe' force exists to create an imaginary target (The 'Turtle') for the spotlights to 'shoot at' while they scan around for enemy units.
-- But we don't want the player's normal turrets to shoot at that imaginary target...
-- ...So we make a 'friend' force, which we'll assign to spotlights while they shoot at the turtle.
function InitForces()

    game.create_force(searchlightFoe)
    game.create_force(searchlightFriend)

    for F in pairs(game.forces) do
      SetCeaseFires(F)
    end

    game.forces[searchlightFriend].set_friend("player", true) -- TODO Is this appropriate in multiplayer?
    game.forces[searchlightFriend].set_cease_fire(searchlightFoe, false)

end


function SetCeaseFires(F)

  game.forces[searchlightFoe].set_cease_fire(F, true)
  game.forces[searchlightFriend].set_cease_fire(F, true)

  game.forces[F].set_cease_fire(searchlightFoe, true)
  game.forces[F].set_cease_fire(searchlightFriend, true)

end
