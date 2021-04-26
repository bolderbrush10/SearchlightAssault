require "control-common"
require "control-grid"
require "control-turtle"
require "sl-defines"
require "sl-util"

require "util"


------------------------
--  Aperiodic Events  --
------------------------


function SearchlightAdded(sl)
  attackLight, turtle = SpawnSLHiddenEntities(sl)
  maps_addSearchlight(sl, attackLight, turtle)

  -- We'll check the power state and let it enable next tick,
  -- just in case someone builds a spotlight right on top of
  -- a bunch of enemies where there's no power
  AttacklightDisabled(attackLight)

  Grid_AddSpotlight(sl)

  -- TODO search for boostables and add

end


function SearchlightRemoved(sl)
  Grid_RemoveSpotlight(sl)
  maps_removeSearchlight(sl)
end


function TurretAdded(turret)

  -- TODO search for spotlights in vicinity and add self as a boostable

  game.print("turret added!")

end


function TurretRemoved(turret)

  -- TODO search for spotlights in vicinity and remove self as a boostable

  game.print("turret removed!")
end


function FoeSpotted(turtle, foe)
  baseSL = global.turtle_to_baseSL[turtle.unit_number]

  -- Move the attack light to the player force so that its alert_when_firing will show up
  attackLight = global.baseSL_to_attackSL[baseSL.unit_number]
  attackLight.force = baseSL.force
  attackLight.shooting_target = foe

  -- Start tracking this foe so we can detect when it dies / leaves range
  maps_addFoeSL(foe, attackLight)

  -- Turn off the turtle. We'll turn it back it on after the foe is gone
  turtle.active = false
end


function FoeDied(foe)
  if not global.foes[foe.unit_number] then
    return
  end

  for index, attackLight in pairs(global.foe_to_attackSL[foe.unit_number]) do
    ResumeTargetingTurtle(foe.position, attackLight)
  end

  maps_removeFoeByUnitNum(foe.unit_number)
end


----------------------
--  On Tick Events  --
----------------------


-- Checked every tick, but only while there's a foe spotted,
-- so not too performance-impacting
function TrackSpottedFoes(tick)
  -- Skip function if table empty (which should be the case most of the time)
  -- TODO would it be faster to maintain a table size variable?
  if next(global.foe_to_attackSL) == nil then
    return
  end

  -- TODO How expensive is doing a deep copy every tick?
  --      Would it be better to just flatout maintain two copies?
  --      On the other hand, it's not like this list will usually be long...
  -- Copy table to simplify removal while iterating
  local copyfoe_to_baseSL = table.deepcopy(global.foe_to_attackSL)

  for foe_unit_number, slList in pairs(copyfoe_to_baseSL) do

    local foe = global.foes[foe_unit_number]
    for index, attackLight in pairs(slList) do

      if attackLight.shooting_target ~= foe then
        --  This should trigger infrequently,
        --  so it's ok to be a little slow inside this branch
        ResumeTargetingTurtle(foe.position, attackLight)
        table.remove(global.foe_to_attackSL[foe.unit_number], index)
      end

    end

    if next(global.foe_to_attackSL[foe.unit_number]) == nil then
      maps_removeFoeByUnitNum(foe.unit_number)
    end

  end
end


-- TODO This onTick() function is a good candidate to convert to branchless instructions.
--      Could speed up execution a minor amount, depending on what's bottlenecked.
--      (Embedding some C code directly into lua could also help, see:
--       https://www.cs.usfca.edu/~galles/cs420/lecture/LuaLectures/LuaAndC.html )
--      Would look something like:
--      local activeAsNum = bit32.band(attackLight.active, 1)
--      attackLight.active = tobool((activeAsNum * (sl.energy - searchlightCapacitorStartable))
--          + ((-1 * activeAsNum) * (sl.energy + searchlightCapacitorCutoff)))
-- We wouldn't need this function if there was a way
-- to directly transfer / mirror electricity between units on different forces
function CheckElectricNeeds(tick)
  for unit_num, sl in pairs(global.base_searchlights) do

    attackLight = global.baseSL_to_attackSL[unit_num]

    if attackLight.active and sl.energy < searchlightCapacitorCutoff then
      AttacklightDisabled(attackLight)
    elseif not attackLight.active and sl.energy > searchlightCapacitorStartable then
      AttacklightEnabled(attackLight)
    end

  end
end


function DecrementBoostTimers(tick)

  -- decrement those timers

end


--------------------
--  Helper Funcs  --
--------------------


function SpawnSLHiddenEntities(sl)
  attackLight = sl.surface.create_entity{name=searchlightAttackName,
                                         position=sl.position,
                                         direction=sl.direction,
                                         force=searchlightFriend,
                                         fast_replace = true,
                                         create_build_effect_smoke = false}
  attackLight.destructible = false

  turtle = SpawnTurtle(sl, attackLight, sl.surface, nil)

  return attackLight, turtle
end


function SwapTurret(old, new)
    -- copy settings
    CopyTurret(old, new)

    -- copy over global entries, placement in, etc
    -- TODO
end


function AttacklightEnabled(attackLight)
  -- TODO re-boost any friends
  attackLight.active = true
  global.attackSL_to_turtle[attackLight.unit_number].active = true
end


function AttacklightDisabled(attackLight)
  -- TODO un-boost any friends
  attackLight.active = false
  global.attackSL_to_turtle[attackLight.unit_number].active = false
end


function ResumeTargetingTurtle(foePosition, attackLight)
  local turtle = global.attackSL_to_turtle[attackLight.unit_number]
  turtle.active = true
  Turtleport(turtle, foePosition, attackLight.position)
  WanderTurtle(turtle, attackLight.position)

  attackLight.force = searchlightFriend
  attackLight.shooting_target = turtle
end


-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------

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
