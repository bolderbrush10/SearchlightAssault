require "control-common"
require "control-grid"
require "control-turtle"
require "defines"
require "render" -- TODO remove
require "util"


function AddSearchlight(sl)
  global.base_searchlights[sl.unit_number] = sl

  attackLight = sl.surface.create_entity{name=searchlightAttackName,
                                         position=sl.position,
                                         force=searchlightFriend}

  global.baseSL_to_attackSL[sl.unit_number] = attackLight

  Grid_AddSpotlight(sl)

  -- TODO search for boostables and add

  SpawnTurtle(sl, attackLight, sl.surface, nil)
end


function AddTurret(turret)

  -- TODO search for spotlights in vicinity and add self as a boostable

end


function RemoveTurret(turret)

  -- TODO search for spotlights in vicinity and remove self as a boostable

end


function RemoveSearchlight(sl)

  global.baseSL_to_attackSL[sl.unit_number].destroy()
  global.baseSL_to_attackSL[sl.unit_number] = nil

  global.base_searchlights[sl.unit_number] = nil

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


-- We wouldn't need this function if there was a way
-- to directly transfer / mirror electricity between units on different forces
function CheckElectricNeeds(tick)
  for unit_num, sl in pairs(global.base_searchlights) do

    attacklight = global.baseSL_to_attackSL[unit_num]

    if attacklight.active and sl.energy < searchlightCapacitorCutoff then
      attacklight.active = false
    elseif not attacklight.active and sl.energy > searchlightCapacitorStartable then
      attacklight.active = true
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
  --   if grid.foes then


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
  for index, sl in pairs(global.base_searchlights) do
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
      local pos = global.baseSL_to_lsp[sl.unit_number]
      CreateDummyLight(sl, surface, pos)
    end
  else
    global.baseSL_to_lsp[sl.unit_number] = sl.shooting_target.position
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


function CreateDummyLight(old_sl, surface, last_shooting_position)
  new_sl = surface.create_entity{name = "searchlight-dummy",
                                 position = old_sl.position,
                                 force = searchlightFriend,
                                 fast_replace = true,
                                 create_build_effect_smoke = false}

  CopyTurret(old_sl, new_sl)

  SpawnTurtle(new_sl, surface, last_shooting_position)

  global.base_searchlights[new_sl.unit_number] = new_sl
  global.base_searchlights[old_sl.unit_number] = nil

  global.baseSL_to_lsp[old_sl.unit_number] = nil

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

  global.base_searchlights[new_sl.unit_number] = new_sl
  global.base_searchlights[old_sl.unit_number] = nil

  old_sl.destroy()

  global.baseSL_to_unboost_timers[new_sl.unit_number] = boostDelay

  if foe then
    new_sl.shooting_target = foe
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

  global.baseSL_to_unboost_timers[newT.unit_number] = boostDelay

 return newT
end


-- TODO If multiple searchlights are checking this, then we're going to very rapidly wind down this timer...
--      So, maybe it's time to bite the bullet and implement oncreated/destroyed(searchlight).
--      Then, we can build an index for all the turrets in range of any light, and just iterate through that for Boost / UnBoost, etc
--      (We still need to think about how to figure in for power consumption...)
-- TODO Also, we should re-increment this number if there's a shooting target. Probably in this function.
function BoostTimerComplete(turret)
 if global.baseSL_to_unboost_timers[turret.unit_number] and global.baseSL_to_unboost_timers[turret.unit_number] > 0 then
      global.baseSL_to_unboost_timers[turret.unit_number] = global.baseSL_to_unboost_timers[turret.unit_number] - 1
    return false
  else
    global.baseSL_to_unboost_timers[turret.unit_number] = nil
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
