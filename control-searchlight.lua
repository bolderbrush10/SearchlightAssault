require "control-common"
require "control-turtle"
require "sl-defines"
require "sl-util"

require "util" -- for table.deepcopy


local boostableArea =
{
  x = searchlightBoostEffectRange*2,
  y = searchlightBoostEffectRange*2
}

------------------------
--  Aperiodic Events  --
------------------------


function SearchlightAdded(sl)
  local friends = sl.surface.find_entities_filtered{area=GetBoostableAreaFromPosition(sl.position),
                                                    type={"fluid-turret", "electric-turret", "ammo-turret"},
                                                    force=sl.force}

  -- Only allow adjacent searchlights and turrets to make boost partners
  candidates = {}
  for _, f in pairs(friends) do
    if rectangeDistSquared(unpackRectangles(f.selection_box, sl.selection_box)) < 1 then
      table.insert(candidates, f)
    end
  end

  local turtle = SpawnTurtle(sl, sl.surface, nil)
  maps_addGestalt(sl, SpawnSignalBox(sl), turtle, candidates)

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
  local searchlights = turret.surface.find_entities_filtered{area=GetBoostableAreaFromPosition(turret.position),
                                                             name={searchlightBaseName, searchlightAlarmName},
                                                             force=turret.force}

  -- Only allow adjacent searchlights and turrets to make boost partners
  candidates = {}
  for _, sl in pairs(searchlights) do
    if rectangeDistSquared(unpackRectangles(sl.selection_box, turret.selection_box)) < 1 then
      table.insert(candidates, sl)
    end
  end

  maps_addTUnion(turret, candidates)
end


function TurretRemoved(turret)
  maps_removeTUnion(turret)
end


function FoeSpotted(turtle, foe)
  local g = maps_getGestalt(turtle)

  -- Turn off the turtle. We'll turn it back it on after the foe is gone
  turtle.active = false
  g.turtleActive = false

  -- If there's a foe in the watch circle after a few moments,
  -- we'll sound the alarm and target it
  OpenWatchCircle(g)
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


-- TODO This onTick() function is a good candidate to convert to branchless instructions.
--      Could speed up execution a minor amount, depending on what's bottlenecked.
--      (Embedding some C code directly into lua could also help, see:
--       https://www.cs.usfca.edu/~galles/cs420/lecture/LuaLectures/LuaAndC.html )
--      Would look something like:
--      local activeAsNum = bit32.band(attackLight.active, 1)
--      *.active = tobool((activeAsNum * (sl.energy - searchlightCapacitorStartable))
--          + ((-1 * activeAsNum) * (sl.energy + searchlightCapacitorCutoff)))
-- We wouldn't need this function if there was an event for when entities run out of power
function CheckElectricNeeds()
  for gID, g in pairs(global.gestalts) do

    if g.base.energy < searchlightCapacitorCutoff then
      -- TODO Disable any boosted turrets
      g.turtle.active = false
    elseif g.base.energy > searchlightCapacitorStartable and g.turtleActive then
      -- TODO Reenable any boosted turrets
      g.turtle.active = true
    end

  end
end


-- Checked every tick, but the heavy logic is only while a foe is spotted,
-- so not too performance-impacting
function TrackSpottedFoes()

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


-- Checked every tick
function HandleCircuitConditions()
  for gID, g in pairs(global.gestalts) do

    local x = g.signal.get_merged_signal({type="virtual", name="signal-X"})
    local y = g.signal.get_merged_signal({type="virtual", name="signal-Y"})

    if x ~= 0 or y ~= 0 then
      local pos = {x=x, y=y}
      ManualTurtleMove(g, pos)
    else
      g.turtleCoord = nil
    end
  end
end


--------------------
--  Helper Funcs  --
--------------------


function OpenWatchCircle(g)

  global.watch_circles[game.tick + searchlightSpotTime_ms] = g.gID

  rendering.draw_light{sprite=searchlightWatchLightSpriteName,
                       scale=15,
                       intensity=1,
                       target=g.turtle,
                       surface=g.turtle.surface,
                       time_to_live=searchlightSpotTime_ms}

  rendering.draw_sprite{sprite=searchlightWatchLightSpriteName,
                        target=g.turtle,
                        surface=g.turtle.surface,
                        time_to_live=searchlightSpotTime_ms,
                        render_layer="floor"}

end


-- Not called every tick, just rarely at a set time after a foe is spotted
function CloseWatchCircle(gID)

  if not global.gestalts[gID] then
    return
  end

  local g = global.gestalts[gID]

  local tPos = g.turtle.position
  local foes = g.base.surface.find_entities_filtered{position = tPos,
                                                     radius = searchlightSpotRadius * 1.1,
                                                     force = GetEnemyForces(g.turtle.force)}

  local foe = GetNearestEntFromList(tPos, foes)

  if foe then
    -- Start tracking this foe so we can detect when it dies / leaves range
    maps_addFoe(foe, g)

    RaiseAlarmLight(g)

    g.base.shooting_target = foe
    BoostFriends(g, foe)
  else
    g.turtle.active = true
    g.turtleActive = true
  end

end


function ResumeTargetingTurtle(foePosition, gestalt)
  local turtle = gestalt.turtle
  turtle.active = true
  gestalt.turtleActive = true
  Turtleport(turtle, foePosition, gestalt.base.position)
  WanderTurtle(turtle, gestalt.base.position)

  ClearAlarmLight(gestalt)
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


function RaiseAlarmLight(gestalt)
  if gestalt.base.name == searchlightAlarmName then
    return -- Alarm already raised
  end

  local base = gestalt.base
  local raised = base.surface.create_entity{name = searchlightAlarmName,
                                            position = base.position,
                                            force = base.force,
                                            fast_replace = true,
                                            create_build_effect_smoke = false}

  CopyTurret(base, raised)
  global.unum_to_g[base.unit_number] = nil
  global.unum_to_g[raised.unit_number] = gestalt
  gestalt.base = raised

  base.destroy()
end


function ClearAlarmLight(gestalt)
  if gestalt.base.name == searchlightBaseName then
    return -- Alarm already raised
  end

  local base = gestalt.base
  local cleared = base.surface.create_entity{name = searchlightBaseName,
                                             position = base.position,
                                             force = base.force,
                                             fast_replace = true,
                                             create_build_effect_smoke = false}

  CopyTurret(base, cleared)
  global.unum_to_g[base.unit_number] = nil
  global.unum_to_g[cleared.unit_number] = gestalt
  gestalt.base = cleared

  base.destroy()
end


function BoostFriends(gestalt, foe)
  -- nothing to boost
  if next(gestalt.tunions) == nil then
    return
  end

  for tuID, _ in pairs(gestalt.tunions) do
    Boost(global.tunions[tuID], foe)
  end
end


function Boost(tunion, foe)
  if tunion.boosted then
    return
  end

  local turret = tunion.turret

  if not IsPositionWithinTurretArc(foe.position, turret) then
    return
  end

  local newT = turret.surface.create_entity{name = turret.name .. boostSuffix,
                                            position = turret.position,
                                            force = turret.force,
                                            direction = turret.direction,
                                            fast_replace = true,
                                            create_build_effect_smoke = false}

  CopyTurret(turret, newT)
  maps_boostTurret(turret, newT, SpawnControl(newT))
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
    return
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
                                            direction = turret.direction,
                                            fast_replace = true,
                                            create_build_effect_smoke = false}

  CopyTurret(turret, newT)
  maps_unboostTurret(newT, turret)
  turret.destroy()
  -- As with Boost(), don't raise script_raised_destroy

  return newT
end


function SpawnControl(turret)
  -- TODO Might be more visually interesting if this was a slightly-random position
  pos = turret.selection_box.right_bottom
  pos.x = pos.x - 0.5
  pos.y = pos.y - 0.5

  local control = turret.surface.create_entity{name = searchlightControllerName,
                                               position = pos,
                                               force = turret.force,
                                               create_build_effect_smoke = true}

  control.destructible = false

  return control
end


function SpawnSignalBox(sl)
  pos = sl.position
  pos.y = pos.y + 0.5

  local box = sl.surface.create_entity{name = searchlightSignalBoxName,
                                       position = pos,
                                       force = sl.force,
                                       create_build_effect_smoke = false}

  box.destructible = false

  return box
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