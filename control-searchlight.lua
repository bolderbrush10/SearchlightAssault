local d = require "sl-defines"
local u = require "sl-util"

require "control-common"
require "control-turtle"

local boostableArea =
{
  x = d.searchlightMaxNeighborDistance*2,
  y = d.searchlightMaxNeighborDistance*2
}

local FoePositionXSlot = 1
local FoePositionYSlot = 2
local WarningSlot = 3
local AlarmSlot = 4

local signalX = {type="virtual", name="signal-X"}
local signalY = {type="virtual", name="signal-Y"}
local signalW = {type="virtual", name="signal-W"}
local signalA = {type="virtual", name="signal-A"}

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
    if u.RectangeDistSquared(u.UnpackRectangles(f.selection_box, sl.selection_box)) < 1 then
      table.insert(candidates, f)
    end
  end

  local turtle = SpawnTurtle(sl, sl.surface, nil)
  maps_addGestalt(sl, SpawnSignalInterface(sl), turtle, candidates)

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
  -- Search for searchlights in vicinity and add self as a boostable
  local searchlights = turret.surface.find_entities_filtered{area=GetBoostableAreaFromPosition(turret.position),
                                                             name={d.searchlightBaseName, d.searchlightAlarmName},
                                                             force=turret.force}

  -- Only allow adjacent searchlights and turrets to make boost partners
  candidates = {}
  for _, sl in pairs(searchlights) do
    if u.RectangeDistSquared(u.UnpackRectangles(sl.selection_box, turret.selection_box)) < 1 then
      table.insert(candidates, sl)
    end
  end

  maps_addTUnion(turret, candidates)
end


function TurretRemoved(turret)
  maps_removeTUnion(turret)
end


function UnboostBlockedTurrets()
  for tuID, tu in pairs(global.tunions) do
    if global.blockList[tu.turret.name:gsub(d.boostSuffix, "")] then
      UnBoost(tu, true)
    end
  end
end


function FoeSuspected(turtle, foe)
  local g = maps_getGestalt(turtle)

  -- Turn off the turtle. We'll turn it back it on after the foe is gone
  turtle.active = false
  g.turtleActive = false

  -- If there's a foe in the spotter's radius after a few moments,
  -- we'll sound the alarm and target it
  local s = SpawnSpotter(g, foe)

  -- If the searchlight hasn't found anything by the given tick, we'll close its circle
  -- (note that it takes quite a few extra ticks for the landmine to do its business,
  --  but we still want to make sure the circle is closed by the time the searchlight
  --  would spawn a new spotter and be 'rearmed')
  OpenWatchCircle(s, nil, game.tick - 10 + d.searchlightSpotTime_ms * 2)
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
--      *.active = tobool((activeAsNum * (sl.energy - d.searchlightCapacitorStartable))
--          + ((-1 * activeAsNum) * (sl.energy + d.searchlightCapacitorCutoff)))
-- We wouldn't need this function if there was an event for when entities run out of power
function CheckElectricNeeds()
  for gID, g in pairs(global.gestalts) do

    if g.base.energy < d.searchlightCapacitorCutoff then
      -- TODO Disable any boosted turrets
      g.turtle.active = false
    elseif g.base.energy > d.searchlightCapacitorStartable and g.turtleActive then
      -- TODO Reenable any boosted turrets
      g.turtle.active = true
    end

  end
end


-- Checked every tick
-- Probably a good candidate to sign this up for every_n_tick, maybe once a second?
function HandleCircuitConditions()
  for gID, g in pairs(global.gestalts) do

    local i = g.signal

    if g.base.name == d.searchlightBaseName then
      -- Set the warning signal to 0 if the turtle is active (no foes suspected right now)
      -- or to 1 if the turtle is inactive (we suspected we spotted a foe so we deactivated the turtle)
      i.get_control_behavior().set_signal(WarningSlot, {signal = signalW,
                                                        count = (g.turtleActive and 0 or 1)})
      i.get_control_behavior().set_signal(FoePositionXSlot, {signal = signalX, count = 0})
      i.get_control_behavior().set_signal(FoePositionYSlot, {signal = signalY, count = 0})
      i.get_control_behavior().set_signal(AlarmSlot, {signal = signalA, count = 0})

      local x = i.get_merged_signal({type="virtual", name="signal-X"})
      local y = i.get_merged_signal({type="virtual", name="signal-Y"})

      if x ~= 0 or y ~= 0 then
        local pos = {x=x, y=y}
        ManualTurtleMove(g, pos)
      else
        g.turtleCoord = nil
      end
    elseif g.base.shooting_target and g.base.shooting_target.valid then
      local pos = g.base.shooting_target.position
      i.get_control_behavior().set_signal(FoePositionXSlot, {signal = signalX, count = pos.x})
      i.get_control_behavior().set_signal(FoePositionYSlot, {signal = signalY, count = pos.y})
      i.get_control_behavior().set_signal(WarningSlot, {signal = signalW, count = 0})
      i.get_control_behavior().set_signal(AlarmSlot, {signal = signalA, count = 1})
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


--------------------
--  Helper Funcs  --
--------------------


function OpenWatchCircle(spotter, foe, tickToClose)
  local gID = global.unum_to_g[spotter.unit_number].gID

  if global.watch_circles[tickToClose] == nil then
    global.watch_circles[tickToClose] = {}
  end

  if global.watch_circles[tickToClose][gID] == nil then
    global.watch_circles[tickToClose][gID] = {}
  end

  table.insert(global.watch_circles[tickToClose][gID], foe)
end


-- Not called every tick, just rarely at a set time after a foe is spotted
function CloseWatchCircle(gIDFoeMap)

  for gID, foeList in pairs(gIDFoeMap) do
    -- Make sure our searchlight wasn't destroyed since last tick
    if not global.gestalts[gID] then
      -- The spotter should already have been destroyed whenever this gestalt was wiped out
      goto continue
    end


    local g = global.gestalts[gID]
    maps_removeSpotter(g)

    -- Make sure none of our foes have died since last tick
    for index, foe in pairs(foeList) do
      if not foe.valid then
        foeList[index] = nil
      end
    end

    local tPos = g.turtle.position
    local foe = u.GetNearestShootableEntFromList(tPos, foeList)

    if foe then
      -- Case: Foe spotted successfully
      maps_addFoe(foe, g)

      RaiseAlarmLight(g)

      g.base.shooting_target = foe
      BoostFriends(g, foe)
    elseif g.base.shooting_target == g.turtle then
      -- Case: Watch circle closed but no foe spotted
      g.turtle.active = true
      g.turtleActive = true
    end
    -- else
      -- Case: Foe previously spotted


    ::continue::
  end

end


function ResumeTargetingTurtle(foePosition, gestalt)
  ResumeTurtleDuty(gestalt, foePosition)

  ClearAlarmLight(gestalt)
  gestalt.base.shooting_target = gestalt.turtle
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
  if gestalt.base.name == d.searchlightAlarmName then
    return -- Alarm already raised
  end

  local base = gestalt.base
  local raised = base.surface.create_entity{name = d.searchlightAlarmName,
                                            position = base.position,
                                            force = base.force,
                                            fast_replace = true,
                                            create_build_effect_smoke = false}

  u.CopyTurret(base, raised)
  global.unum_to_g[base.unit_number] = nil
  global.unum_to_g[raised.unit_number] = gestalt
  gestalt.base = raised

  base.destroy()
end


function ClearAlarmLight(gestalt)
  if gestalt.base.name == d.searchlightBaseName then
    return -- Alarm already raised
  end

  local base = gestalt.base
  local cleared = base.surface.create_entity{name = d.searchlightBaseName,
                                             position = base.position,
                                             force = base.force,
                                             fast_replace = true,
                                             create_build_effect_smoke = false}

  u.CopyTurret(base, cleared)
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
  if tunion.boosted or global.blockList[tunion.turret.name] then
    return
  end

  local turret = tunion.turret

  if not u.IsPositionWithinTurretArc(foe.position, turret) then
    return
  end

  local newT = turret.surface.create_entity{name = turret.name .. d.boostSuffix,
                                            position = turret.position,
                                            force = turret.force,
                                            direction = turret.direction,
                                            fast_replace = true,
                                            create_build_effect_smoke = false}

  u.CopyTurret(turret, newT)
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


function UnBoost(tunion, forceUnboost)
  if not tunion.boosted then
    return
  end

  if not forceUnboost then

    -- Before unboosting, see if there's another searchlight with a target for us
    for gID, _ in pairs(tunion.lights) do
      local g = global.gestalts[gID]
      if g.shooting_target and global.foes[g.shooting_target.unit_number] then
        tunion.turret.shooting_target = g.shooting_target
        return tunion.turret
      end
    end

  end

  local turret = tunion.turret
  local newT = turret.surface.create_entity{name = turret.name:gsub(d.boostSuffix, ""),
                                            position = turret.position,
                                            force = turret.force,
                                            direction = turret.direction,
                                            fast_replace = true,
                                            create_build_effect_smoke = false}

  u.CopyTurret(turret, newT)
  maps_unboostTurret(newT, turret)
  turret.destroy()
  -- As with Boost(), don't raise script_raised_destroy

  return newT
end


function SpawnControl(turret)
  local width = turret.bounding_box.right_bottom.x - turret.bounding_box.left_top.x
  local pos  = turret.bounding_box.right_bottom

  -- Slightly randomizing the position to add visual interest,
  -- staying near the bottom edge of the entity, varying around ~80% of the width.
  -- (math.random(x, y) doesn't return a float, so we'll add our product to math.random() which does)
  -- (math.random(x, y) crashes when given positions too close so check variance before using)
  local xVar = math.abs((0) - (width - 0.2))
  local xRand = 0
  if xVar >= 1 then
    xRand = math.random((0),  (width - 0.2))
  end

  pos.x = pos.x - 0.2 - xRand
  pos.y = pos.y - 0.1 + math.random()/8

  local control = turret.surface.create_entity{name = d.searchlightControllerName,
                                               position = pos,
                                               force = turret.force,
                                               create_build_effect_smoke = true}

  control.destructible = false

  return control
end


function FindSignalInterfaceGhosts(sl)
  local ghosts = sl.surface.find_entities_filtered{position = sl.position,
                                                   ghost_name = d.searchlightSignalInterfaceName,
                                                   force = sl.force,
                                                   limit = 1}

  if ghosts and ghosts[1] and ghosts[1].valid then
    -- The revived entity should be returned as the 2nd return value, or nil if that fails
    return ghosts[1].revive{raise_revive = false}[2]
  end

  return nil
end


function FindSignalInterfacePrebuilt(sl)
  local prebs = sl.surface.find_entities_filtered{position = sl.position,
                                                  name = d.searchlightSignalInterfaceName,
                                                  force = sl.force,
                                                  limit = 1}

  if prebs and prebs[1] and prebs[1].valid then
    return prebs[1]
  end

  return nil
end

function FindSignalInterface(sl)
  -- If there's already a ghost / ghost-built signal interface,
  -- just create / use it instead
  local i = FindSignalInterfaceGhosts(sl)
  if i then
    return i
  end

  i = FindSignalInterfacePrebuilt(sl)
  if i then
    return i
  end

  return sl.surface.create_entity{name = d.searchlightSignalInterfaceName,
                                  position = sl.position,
                                  force = sl.force,
                                  create_build_effect_smoke = false}
end


function SpawnSignalInterface(sl)
  local i = FindSignalInterface(sl)

  i.destructible = false
  i.operable = false
  i.rotatable = false

  i.get_control_behavior().set_signal(FoePositionXSlot, {signal = signalX, count = 0})
  i.get_control_behavior().set_signal(FoePositionYSlot, {signal = signalY, count = 0})
  i.get_control_behavior().set_signal(WarningSlot, {signal = signalW, count = 0})
  i.get_control_behavior().set_signal(AlarmSlot, {signal = signalA, count = 0})

  return i
end


function SpawnSpotter(g, foe)
  local spotter = g.turtle.surface.create_entity{name = d.spotterName,
                                                 position = g.turtle.position,
                                                 force = g.turtle.force,
                                                 create_build_effect_smoke = true} -- TODO disable smoke
  spotter.destructible = false

  maps_addSpotter(spotter, g)

  return spotter
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