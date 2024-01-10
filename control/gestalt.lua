local d  = require "sl-defines"
local r  = require "sl-relation"
local u  = require "sl-util"
local cs = require "control-searchlight"
local ct = require "control-turtle"
local cu = require "control-tunion"
local cgui = require "control-gui"

-- forward declarations
local EnterSafeModeSync
local EnterSafeMode
local EnterWarnMode
local EnterAlarmMode
local ResumeTargetingTurtle
local BoostFriends
local makeGestalt
local newGID
local CheckSync
local SyncReady
local CloseWatch
local OpenWatch
local FoeSuspected
local FoeFound
local SearchlightRemoved
local SearchlightAdded
local FoeDied
local CheckGestaltFoes
local CheckElectricNeeds
local InitTables_Gestalt


-- Tiny optimization, reduces calls to global table
-- Not quite as fast as declaring locally in a function,
-- but our loops should usually be fairly small...
local pairs = pairs
local next  = next

-------------------------
-- Searchlight Gestalt --
-------------------------
--[[
{
  gID           = int (gestalt ID),
  light         = Searchlight / Alarmlight,
  signal        = SignalInterface,
  spotter       = Spotter,
  lastSpotted   = nil / tick,
  turtle        = Turtle,
  tState        = WANDER / FOLLOW  / MOVE
  tCoord        = WANDER / &entity / {x, y} (Raw signal coords)
  tOldState     = WANDER / MOVE
  tOldCoord     = WANDER / {x, y} (Raw signal coords)
  tWanderParams = .radius (deg), .rotation (deg), .min, .max (raw values)
  tAdjParams    = .angleStart(rad), .len(rad), .min, .max (bounds-checked)
}
]]--


InitTables_Gestalt = function()
  global.gID = 0

  -- Map: gID -> Gestalt
  global.gestalts = {}

  -- Map: gID -> Gestalt
  global.check_power = {}

  -- Map: unit_number -> Gestalt
  -- Currently tracking: baselight/alarmlight, spotter, turtle -> Gestalt
  global.unum_to_g = {}

  -- Map: game tick -> {gID}
  global.spotter_timeouts = {}

  -- Map: game tick -> {gID}
  global.animation_sync = {}
end



------------------------
--  Helper Functions  --
------------------------


newGID = function()
  global.gID = global.gID + 1
  return global.gID
end


makeGestalt = function(sl, sigInterface, turtle, spotter)
  local g = {gID = newGID(),
             light = sl,
             signal = sigInterface,
             turtle = turtle,
             spotter = spotter,}

  global.gestalts[g.gID] = g
  global.unum_to_g[sl.unit_number] = g
  global.unum_to_g[turtle.unit_number] = g
  global.unum_to_g[sigInterface.unit_number] = g
  global.unum_to_g[spotter.unit_number] = g

  global.check_power[g.gID] = g

  ct.SetDefaultWanderParams(g)

  return g
end


BoostFriends = function(gestalt, spottedFoe)
  local gtRelations = global.GestaltTunionRelations

  for tID, _ in pairs(r.getRelationLHS(gtRelations, gestalt.gID)) do
    local tu = global.tunions[tID]
    if not tu.boosted and tu.turret.shooting_target == nil then
      cu.Boost(tu, spottedFoe)
    end
  end
end


ResumeTargetingTurtle = function(g, turtlePositionToResume)
  ct.ResumeTurtleDuty(g, turtlePositionToResume)
  g.light.shooting_target = g.turtle
end


EnterAlarmMode = function(g, spottedFoe)
  SpawnAlarmLight(g)

  -- No need to keep firing the spotter while we're targeting a foe
  -- (in fact, we don't want it to fire and kick us back to warn mode)
  g.spotter.active = false

  r.setRelation(global.FoeGestaltRelations, spottedFoe.unit_number, g.gID, spottedFoe)

  g.light.shooting_target = spottedFoe
  g.turtle.teleport(spottedFoe.position)
  ct.TurtleChase(g, spottedFoe)
  cs.ProcessAlarmRaiseSignals(g)

  BoostFriends(g, spottedFoe)

  cgui.updateOnEntity(g)
end


EnterWarnMode = function(g, escapedFoe)
  if g.light.name == d.searchlightBaseName then
    return -- Alarm already cleared
  end

  -- If we were spinning around in safe mode,
  -- match up our orientation to that spin so
  -- it looks smoother when we retarget the turtle
  local val = nil
  if g.light.shooting_target and g.light.shooting_target == g.spotter then
    val = ((game.tick % d.spinFactor) / d.spinFactor)
  end

  SpawnBaseLight(g)

  if val then
    g.light.orientation = val
  end

  g.spotter.active = true

  -- If the spotter doesn't fire again by this time,
  -- we'll go back to safe mode
  export.OpenWatch(g.gID)

  global.check_power[g.gID] = g

  if escapedFoe then
    ResumeTargetingTurtle(g, escapedFoe.position)
  else
    ResumeTargetingTurtle(g, nil)
  end

  cs.ProcessAlarmClearSignals(g, game.tick)

  cgui.updateOnEntity(g)
end


EnterSafeMode = function(g)
  if g.light.name == d.searchlightSafeName then
    return -- Already in safe mode
  end

  SpawnSafeLight(g)

  g.turtle.active = false
  g.light.shooting_target = g.spotter

  cs.ProcessSafeSignals(g)

  global.check_power[g.gID] = nil

  cgui.updateOnEntity(g)
end


EnterSafeModeSync = function(g)
  g.turtle.active = false
  local light = g.light
  light.shooting_target = g.spotter

  local tickd.turnDelay = game.tick + d.turnDelay
  if not global.animation_sync[tickd.turnDelay] then
    global.animation_sync[tickd.turnDelay] = {}
  end

  table.insert(global.animation_sync[tickd.turnDelay], g.gID)
end


----------------------
--  On Tick Events  --
----------------------


-- Wouldn't need this function if there was an event for when entities run out of power
CheckElectricNeeds = function()
  -- Not happy about having to add this loop,
  -- but too many other mods have been blowing up our turtles somehow,
  -- so we have to do this.
  for _, g in pairs(global.gestalts) do
    if not g.turtle.valid then

      -- Something nuked our mod's turtle, gotta try to respawn it now
      if not ct.RespawnBrokenTurtle(g) then
        -- Somehow the respawn failed, so just blow up the whole searchlight

        g.light.die() -- The on_death() event won't happen until long after this function,
                      -- so clean it up now so we don't iterate over a dead light below

        -- (It should be safe in lua to remove from a table while iterating)
        export.SearchlightRemoved(nil, false, g)
      end
    end
  end

  for _, g in pairs(global.check_power) do
    if g.light.valid and g.signal.valid then
      g.turtle.active = g.light.energy > 0
    else
      -- Something nuked our mod's searchlight, gotta remove it now
      -- (It should be safe in lua to remove from a table while iterating)
      export.SearchlightRemoved(nil, false, g)
    end
  end
end


-- Every tick, check that all spotlights are shooting at sanctioned foes,
-- and check if any unboosted turrets have been freed up & try boosting them.
-- (Heavy logic only runs while a foe is spotted, so not too performance-impacting)
-- (Boosted turrets will seek new gestalt-targets on their own before unboosting)
CheckGestaltFoes = function()
  if r.empty(global.FoeGestaltRelations) then
    return
  end

  local fgRelations = global.FoeGestaltRelations
  for fun, gIDs in pairs(r.getRelationMatrix(fgRelations)) do
    for gID, foe in pairs(gIDs) do
      local g = global.gestalts[gID]

      if     not foe.valid
          or g.light.shooting_target == nil
          or g.light.shooting_target.unit_number ~= fun then

        if foe.valid then
          -- Retarget turtle, teleport turtle to roughly the foe's location
          EnterWarnMode(g, foe)
        else
          EnterWarnMode(g, g.turtle)
        end

        -- In lua, it's usually safe to remove from a table while iterating
        -- (If you're nil'ing entries while using pairs())
        -- (But not safe to add into a table)
        r.removeRelation(fgRelations, fun, gID)
        cu.FoeGestaltRelationRemoved(g)

      else
        BoostFriends(g, foe)
      end
    end
  end

end


------------------------
--  Aperiodic Events  --
------------------------


FoeDied = function(foe)
  local fgRelations = global.FoeGestaltRelations
  local gestalts = global.gestalts
  local gIDs = r.popRelationLHS(fgRelations, foe.unit_number)

  for gID, _ in pairs(gIDs) do
    EnterWarnMode(gestalts[gID], foe)
    cu.FoeGestaltRelationRemoved(gestalts[gID])
  end

end


SearchlightAdded = function(sl)
  -- Don't allow building searchlights while uninstallation desired
  if settings.global[d.uninstallMod].value then
    sl.destroy()
    return
  end

  local turtle = ct.SpawnTurtle(sl, sl.surface, nil)
  local g = makeGestalt(sl,
                        cs.SpawnSignalInterface(sl),
                        turtle,
                        export.SpawnSpotter(sl, turtle.force))

  -- Register our searchlight so if it gets removed by the map editor or another mod,
  -- and thus no on_mined / on_died event is called, we can still destroy our gestalt
  script.register_on_entity_destroyed(sl)

  sl.shooting_target = turtle
  ct.WindupTurtle(g, turtle)

  export.OpenWatch(g.gID)

  local friends = sl.surface.find_entities_filtered{area=u.GetBoostableAreaFromPosition(sl.position),
                                                    type={"fluid-turret", "electric-turret", "ammo-turret"},
                                                    force=sl.force}

  for _, f in pairs(friends) do
    cu.CreateRelationship(g, f)
  end
end


SearchlightRemoved = function(sl_unit_number, killed, g)
  if not g then
    g = global.unum_to_g[sl_unit_number]
  end

  if not g then
    return
  end

  for pIndex, gAndGUI in pairs(global.pIndexToGUI) do
    if gAndGUI[1] == g.gID then
      cgui.CloseSearchlightGUI(pIndex)
    end
  end

  -- Stuff gets a little more complicated because we have to deal
  -- with the map editor / other mods not firing events
  if not sl_unit_number then
    for lhs, rhs in pairs(global.unum_to_g) do
      if rhs.gID == g.gID then
        global.unum_to_g[lhs] = nil
      end
    end
  else
    global.unum_to_g[sl_unit_number] = nil
  end

  -- Above for loop should have cleared out this unum,
  -- if the turtle was somehow invalidated
  if g.turtle.valid then
    global.unum_to_g[g.turtle.unit_number] = nil
  end

  -- Likewise for this valid check
  if g.spotter and g.spotter.valid then
    global.unum_to_g[g.spotter.unit_number] = nil
  end

  if g.spotter then
    g.spotter.destroy()
  end

  if g.signal and g.signal.valid then
    global.unum_to_g[g.signal.unit_number] = nil
  end

  -- Preserve wire connections when killed by leaving a ghost
  if killed then
    g.signal.destructible = true
    g.signal.die()
  else
    g.signal.destroy()
  end

  g.turtle.destroy()


  local tIDs = r.popRelationLHS(global.GestaltTunionRelations, g.gID)

  -- Turtle state should be locked into follow while we're tracking a foe
  if g.tState == ct.FOLLOW then
    r.removeRelationRHS(global.FoeGestaltRelations, g.gID)
    cu.FoeGestaltRelationRemoved(g, tIDs)
  end

  for tID, _ in pairs(tIDs) do
    cu.GestaltRemoved(tID)
  end

  global.gestalts[g.gID] = nil
  global.check_power[g.gID] = nil

  -- global.spotter_timeouts/animation_sync:
  -- Instead of iterating for a gID that might not even be in it
  -- so we can clean up any possible watch circle for this gestalt,
  -- we'll just check if our gestalt is still valid when that tick comes.
end


FoeFound = function(turtle, foe)
  -- If something's in a vehicle, target the driver instead of the vehicle
  local foeOrDriver = u.CheckEntityOrDriver(foe)
  if not foeOrDriver then
    return
  end

  local g = global.unum_to_g[turtle.unit_number]

  EnterAlarmMode(g, foe)
end


FoeSuspected = function(spotter)
  local g = global.unum_to_g[spotter.unit_number]
  if not g then
    return
  end

  g.lastSpotted = game.tick
  export.OpenWatch(g.gID)

  if g.light.energy > 0 then
    -- Leave safe mode, start hunting for foes
    EnterWarnMode(g, nil)
  end
end


OpenWatch = function(gID)
  local tickToClose = game.tick + d.searchlightSafeTime
  -- Align to base_picture rotation so we transition smoothly
  tickToClose = tickToClose + (d.spinFactor - (tickToClose % d.spinFactor))
  tickToClose = tickToClose + (d.spinFactor * 0.25) - d.turnDelay

  if not global.spotter_timeouts[tickToClose] then
    global.spotter_timeouts[tickToClose] = {}
  end

  table.insert(global.spotter_timeouts[tickToClose], gID)
end


-- If our watch has expired with no foes in range, then go back to safe mode
CloseWatch = function(gIDs)
  local tick = game.tick

  for _, gID in pairs(gIDs) do
    local g = global.gestalts[gID]

    -- Check if our searchlight was destroyed in the ticks since the watch was opened
    if g and g.light.name == d.searchlightBaseName then

      if     not g.lastSpotted 
          or (tick - g.lastSpotted) >= d.searchlightSafeTime then
        if g.light.energy > 0 then
          EnterSafeModeSync(g)
        else
          -- If we're out of power, try again later
          export.OpenWatch(gID)
        end
      -- else
        -- Another watch-tick was already opened for whenever the last foe-spotting was
      end
    end
  end
end


SyncReady = function(gIDs)
  for _, gID in pairs(gIDs) do
    local g = global.gestalts[gID]

    if g then
      EnterSafeMode(g)
    end
  end
end


-- If a searchlight has reached the desired orientation,
-- disable the spotlight effect from rendering on the spotter, which looks ugly
CheckSync = function(gIDs)
  for _, gID in pairs(gIDs) do
    local g = global.gestalts[gID]

    if g then
      local light = g.light
      -- The light will be renabled in a few ticks in EnterSafeMode() by the spawn(), don't worry
      if light.orientation > 0.2 and light.orientation < 0.3 then
        light.active = false
      end
    end
  end
end

local public = {}
public.EnterSafeModeSync = EnterSafeModeSync
public.EnterSafeMode = EnterSafeMode
public.EnterWarnMode = EnterWarnMode
public.EnterAlarmMode = EnterAlarmMode
public.ResumeTargetingTurtle = ResumeTargetingTurtle
public.BoostFriends = BoostFriends
public.makeGestalt = makeGestalt
public.newGID = newGID
public.CheckSync = CheckSync
public.SyncReady = SyncReady
public.CloseWatch = CloseWatch
public.OpenWatch = OpenWatch
public.FoeSuspected = FoeSuspected
public.FoeFound = FoeFound
public.SearchlightRemoved = SearchlightRemoved
public.SearchlightAdded = SearchlightAdded
public.FoeDied = FoeDied
public.CheckGestaltFoes = CheckGestaltFoes
public.CheckElectricNeeds = CheckElectricNeeds
public.InitTables_Gestalt = InitTables_Gestalt
return public
