require "control-common"
require "control-turtle"
require "sl-defines"
require "sl-util"

require "util" -- for table.deepcopy


local boostableArea =
{
  x = searchlightBoostEffectRange,
  y = searchlightBoostEffectRange
}

------------------------
--  Aperiodic Events  --
------------------------


function SearchlightAdded(sl)
  turtle = SpawnSLHiddenEntities(sl)

  friends = sl.surface.find_entities_filtered{area=GetBoostableAreaFromPosition(sl.position),
                                              type={"turret", "electric-turret", "ammo-turret"},
                                              force=sl.force}

  maps_addGestalt(sl, turtle, friends)

  sl.shooting_target = turtle
end


function SearchlightRemoved(sl)
  local g = maps_getGestalt(sl)
  local tunions = g.tunions

  maps_removeGestaltAndDestroyHiddenEnts(g)

  -- If any of these turrets no longer have a nearby searchlight,
  -- or no nearby searchlight targeting their foe,
  -- unboost them
  for tuid, _ in pairs(tunions) do
    tunion = global.tunions[tuid]
    if next(tunion.lights) == nil then
      UnBoost(tunion)
      -- We can also entirely stop tracking turrets
      -- that no longer have a nearby searchlight
      maps_removeTUnion(tunion.turret)
    elseif HasNoSharedTarget(tunion) then
      UnBoost(tunion)
    end
  end
end


function TurretAdded(turret)
  -- Search for spotlights in vicinity and add self as a boostable
  searchlights = turret.surface.find_entities_filtered{area=GetBoostableAreaFromPosition(turret.position),
                                                       name=searchlightBaseName,
                                                       force=turret.force}

  maps_addTUnion(turret, searchlights)
end


function TurretRemoved(turret)
  maps_removeTUnion(turret)
end


function FoeSpotted(turtle, foe)
  local g = maps_getGestalt(turtle)

  g.base.shooting_target = foe

  -- Start tracking this foe so we can detect when it dies / leaves range
  maps_addFoe(foe, g)

  -- Turn off the turtle. We'll turn it back it on after the foe is gone
  turtle.active = false

  BoostFriends(g, foe)
end


function FoeDied(foe)
  -- assert: global.foes[foe.unit_number] (Checked in control.lua)

  for gID, gIDval in pairs(global.fun_to_gIDs[foe.unit_number]) do
    ResumeTargetingTurtle(foe.position, global.gestalts[gID])
  end

  maps_removeFoeByUnitNum(foe.unit_number)
end


----------------------
--  On Tick Events  --
----------------------


-- Checked every tick, but only while there's a foe spotted,
-- so not too performance-impacting
function TrackSpottedFoes(tick)

  -- Skip function if tables empty (which should be the case most of the time)
  -- TODO How much faster would it be to maintain table size variables?
  if next(global.fun_to_gIDs) == nil and next(global.boosted_to_tuID) == nil then
    return
  end

  for foe_unit_number, gestaltMap in pairs(global.fun_to_gIDs) do
    for gID, gIDval in pairs(gestaltMap) do
      local g = global.gestalts[gID]

      if g.base.shooting_target == nil or g.base.shooting_target.unit_number ~= foe_unit_number then
        -- This should trigger infrequently,
        -- so it's ok to be a little slow inside this branch
        ResumeTargetingTurtle(global.foes[foe_unit_number].position, g)
        -- It's apparently safe to remove from a table while iterating in lua
        -- (But definitely not safe to add)
        global.fun_to_gIDs[foe_unit_number][gID] = nil
      else
        -- If a searchlight has any turrets that aren't busy,
        -- try boosting them again
        BoostFriends(g, global.foes[foe_unit_number])
      end
    end
  end

  -- If any boosted turrets aren't targeting a foe in our foe list, then unboost them
  for boosted_unit_number, tuID in pairs(global.boosted_to_tuID) do
    local tunion = global.tunions[tuID]
    local target = tunion.turret.shooting_target
    if not target or not global.fun_to_gIDs[target.unit_number] then
      UnBoost(tunion)
    end
  end
end


--------------------
--  Helper Funcs  --
--------------------


function SpawnSLHiddenEntities(sl)
  turtle = SpawnTurtle(sl, sl.surface, nil)

  return turtle
end


function ResumeTargetingTurtle(foePosition, gestalt)
  local turtle = gestalt.turtle
  turtle.active = true
  Turtleport(turtle, foePosition, gestalt.base.position)
  WanderTurtle(turtle, gestalt.base.position)

  gestalt.base.shooting_target = turtle
end


function GetBoostableAreaFromPosition(position)
  local adjusted = {left_top = {x, y}, right_bottom = {x, y}}
  adjusted.left_top.x     = position.x - boostableArea.x
  adjusted.left_top.y     = position.y - boostableArea.y
  adjusted.right_bottom.x = position.x + boostableArea.x
  adjusted.right_bottom.y = position.y + boostableArea.y

  return adjusted
end


function BoostFriends(gestalt, foe)
  -- nothing to boost
  if next(gestalt.tunions) == nil then
    return
  end

  for tuID, _ in pairs(gestalt.tunions) do
    tunion = global.tunions[tuID]
    if not tunion.turret.shooting_target then
      Boost(tunion, foe)
    end
  end
end


function Boost(tunion, foe)
  if tunion.boosted then
    return tunion.turret
  end

  local turret = tunion.turret
  local newT = turret.surface.create_entity{name = turret.name .. boostSuffix,
                                            position = turret.position,
                                            force = turret.force,
                                            fast_replace = true,
                                            create_build_effect_smoke = false}

  CopyTurret(turret, newT)
  maps_boostTurret(turret, newT)
  turret.destroy()
  -- Don't raise script_raised_destroy since we're trying to do a swap-in-place,
  -- not actually "destroy" the entity (We'll put the original back soon
  -- (albiet with a new unit_number...))
  -- On the other hand, what if the other mod has its own hidden entities
  -- mapped to what we're destroying? We're messing up their unit_number too...
  -- Would we be better off just setting active=false on the original entity
  -- and somehow hiding it / synchronizing its movement & firing animations?
  -- (I don't think doubling lighting / glow effects would be a bad thing,
  --  if anything it'd be a bonus)

  newT.shooting_target = foe

 return newT
end


function UnBoost(tunion)
  if not tunion.boosted then
    return tunion.turret
  end

  -- Before unboosting, see if there's another searchlight with a target for us
  for gID, _ in pairs(tunion.lights) do
    local g = global.gestalts[gID]
    if g.shooting_target and global.foes[g.shooting_target.unit_number] then
      tunion.turret.shooting_target = g.shooting_target
      return tunion.turret
    end
  end

  local turret = tunion.turret
  local newT = turret.surface.create_entity{name = turret.name:gsub(boostSuffix, ""),
                                            position = turret.position,
                                            force = turret.force,
                                            fast_replace = true,
                                            create_build_effect_smoke = false}

  CopyTurret(turret, newT)
  maps_unboostTurret(newT, turret)
  turret.destroy()
  -- As with Boost(), don't raise script_raised_destroy

  return newT
end


-- Check if the tunion is boosted and firing at the same target as some searchlight
function HasNoSharedTarget(tunion)
  if not tunion.boosted
  or not tunion.turret.valid
  or not tunion.turret.shooting_target then
    return true
  end

  for gID, gIDval in pairs(tunion.lights) do
    if global.gestalts[gID].base.shooting_target == tunion.turret.shooting_target then
      return false
    end
  end

  return true
end