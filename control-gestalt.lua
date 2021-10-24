local d  = require "sl-defines"
local r  = require "sl-relation"
local u  = require "sl-util"
local cs = require "control-searchlight"
local ct = require "control-turtle"
local cu = require "control-tunion"


-- Not quite as fast as declaring locally in a function,
-- but our loops should usually be fairly small...
local pairs = pairs
local next  = next


local export = {}


-------------------------
-- Searchlight Gestalt --
-------------------------
--[[
{
  gID       = int (gestalt ID),
  light     = Searchlight / Alarmlight,
  signal    = SignalInterface,
  turtle    = Turtle,
  tState    = WANDER / FOLLOW  / {x, y} (Adjusted signal coords)
  tCoord    = WANDER / &entity / {x, y} (Raw signal coords)
  tOldState = WANDER           / {x, y} (Raw signal coords)
  spotter   = nil / Spotter,
}
]]--


export.InitTables_Gestalt = function()
  global.gID = 0

  -- Map: gID -> Gestalt
  global.gestalts = {}

  -- Map: unit_number -> Gestalt
  -- Currently tracking: baselight/alarmlight, spotter, turtle -> Gestalt
  global.unum_to_g = {}

  -- Map: game tick -> Map: gID -> [potential foes]
  global.watch_circles = {}
end


------------------------
-- Spawner Functions  --
------------------------


local function SpawnAlarmLight(gestalt)
  if gestalt.light.name == d.searchlightAlarmName then
    return -- Alarm already raised
  end

  local base = gestalt.light
  local raised = base.surface.create_entity{name = d.searchlightAlarmName,
                                            position = base.position,
                                            force = base.force,
                                            fast_replace = true,
                                            create_build_effect_smoke = false}

  u.CopyTurret(base, raised)
  global.unum_to_g[base.unit_number] = nil
  global.unum_to_g[raised.unit_number] = gestalt
  gestalt.light = raised

  base.destroy()
end


local function SpawnBaseLight(gestalt)
  if gestalt.light.name == d.searchlightBaseName then
    return -- Alarm already cleared
  end

  local base = gestalt.light
  local cleared = base.surface.create_entity{name = d.searchlightBaseName,
                                             position = base.position,
                                             force = base.force,
                                             fast_replace = true,
                                             create_build_effect_smoke = false}

  u.CopyTurret(base, cleared)
  global.unum_to_g[base.unit_number] = nil
  global.unum_to_g[cleared.unit_number] = gestalt
  gestalt.light = cleared

  base.destroy()
end


local function SpawnSpotter(g, foePos)
  local spotter = g.turtle.surface.create_entity{name = d.spotterName,
                                                 position = foePos,
                                                 force = g.turtle.force,
                                                 create_build_effect_smoke = false}
  spotter.destructible = false

  return spotter
end


------------------------
--  Helper Functions  --
------------------------


local function newGID()
  global.gID = global.gID + 1
  return global.gID
end


local function makeGestalt(sl, sigInterface, turtle)
  local g = {gID = newGID(),
             light = sl,
             signal = sigInterface,
             turtle = turtle}

  global.gestalts[g.gID] = g
  global.unum_to_g[sl.unit_number] = g
  global.unum_to_g[turtle.unit_number] = g

  return g
end


local function BoostFriends(gestalt, spottedFoe)
  local gtRelations = global.GestaltTunionRelations

  for tID, _ in pairs(r.getRelationLHS(gtRelations, gestalt.gID)) do
    local tu = global.tunions[tID]
    if not tu.boosted and tu.turret.shooting_target == nil then
      cu.Boost(tu, spottedFoe)
    end
  end
end


local function ResumeTargetingTurtle(g, turtlePositionToResume)
  ct.ResumeTurtleDuty(g, turtlePositionToResume)
  g.light.shooting_target = g.turtle
end


local function RaiseAlarm(g, spottedFoe)
  SpawnAlarmLight(g)

  r.setRelation(global.FoeGestaltRelations, spottedFoe.unit_number, g.gID, spottedFoe)

  g.light.shooting_target = spottedFoe
  g.turtle.teleport(spottedFoe.position)
  ct.TurtleChase(g, spottedFoe)

  BoostFriends(g, spottedFoe)
end


local function ClearAlarm(g, escapedFoe)
  SpawnBaseLight(g)
  ResumeTargetingTurtle(g, escapedFoe.position)
end


----------------------
--  On Tick Events  --
----------------------


-- Wouldn't need this function if there was an event for when entities run out of power
export.CheckElectricNeeds = function()
  for _, g in pairs(global.gestalts) do
    g.turtle.active = g.light.energy > 0
  end
end


-- Every tick, check that all spotlights are shooting at sanctioned foes,
-- and check if any unboosted turrets have been freed up & try boosting them.
-- (Heavy logic only runs while a foe is spotted, so not too performance-impacting)
-- (Boosted turrets will seek new gestalt-targets on their own before unboosting)
export.CheckGestaltFoes = function()
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
          ClearAlarm(g, foe)
        else
          ClearAlarm(g, g.turtle)
        end

        -- In lua, it's usually safe to remove from a table while iterating
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


export.FoeDied = function(foe)
  local fgRelations = global.FoeGestaltRelations
  local gestalts = global.gestalts
  local gIDs = r.popRelationLHS(fgRelations, foe.unit_number)

  for gID, _ in pairs(gIDs) do
    ClearAlarm(gestalts[gID], foe)
    cu.FoeGestaltRelationRemoved(gestalts[gID])
  end

end


export.SearchlightAdded = function(sl)
  -- Don't allow building searchlights while uninstallation desired
  if settings.global[d.uninstallMod].value then
    sl.destroy()
    return
  end

  local g = makeGestalt(sl,
                        cs.SpawnSignalInterface(sl),
                        ct.SpawnTurtle(sl, sl.surface, nil))

  sl.shooting_target = g.turtle
  ct.WindupTurtle(g, g.turtle)

  local friends = sl.surface.find_entities_filtered{area=u.GetBoostableAreaFromPosition(sl.position),
                                                    type={"fluid-turret", "electric-turret", "ammo-turret"},
                                                    force=sl.force}

  for _, f in pairs(friends) do
    cu.CreateRelationship(g, f)
  end
end


export.SearchlightRemoved = function(sl)
  local g = global.unum_to_g[sl.unit_number]

  global.unum_to_g[sl.unit_number] = nil
  global.unum_to_g[g.turtle.unit_number] = nil
  if g.spotter then
    global.unum_to_g[g.spotter.unit_number] = nil
  end

  -- global.watch_circles:
  -- We'll just check if our gestalt is still valid when the tick comes,
  -- instead of iterating for a gID that might not even be in it

  g.signal.destroy()
  g.turtle.destroy()
  if g.spotter then
    g.spotter.destroy()
  end

  -- Don't need to do anything fancy if we weren't targeting a foe
  if g.light.name == d.searchlightBaseName then
    r.removeRelationLHS(global.GestaltTunionRelations, g.gID)
  else
    r.removeRelationRHS(global.FoeGestaltRelations, g.gID)
    local tIDs = r.popRelationLHS(global.GestaltTunionRelations, g.gID)
    cu.FoeGestaltRelationRemoved(g, tIDs)
  end

  global.gestalts[g.gID] = nil
end


export.FoeSuspected = function(turtle, foePos)
  local g = global.unum_to_g[turtle.unit_number]

  if g.tState == ct.FOLLOW then
    return
  end

  -- If there's a foe in the spotter's radius after a few moments,
  -- we'll sound the alarm and target it
  g.spotter = SpawnSpotter(g, foePos)
  global.unum_to_g[g.spotter.unit_number] = g

  ct.TurtleChase(g, g.spotter)

  -- If the searchlight hasn't found anything by the given tick, we'll close its circle
  -- (note that it takes quite a few extra ticks for the landmine to do its business,
  --  but we still want to make sure the circle is closed by the time the searchlight
  --  would spawn a new spotter and be 'rearmed')
  -- A new watch circle will be opened if the spotter still has foes in range after arming;
  -- in which case, this watch circle will just silently expire
  export.OpenWatchCircle(g.spotter, nil, game.tick - 10 + d.searchlightSpotTime_ms * 2)
end


-- control.lua will handle freeing our table entries when their tick comes
export.OpenWatchCircle = function(spotter, foe, tickToClose)
  local gID = global.unum_to_g[spotter.unit_number].gID

  if global.watch_circles[tickToClose] == nil then
    global.watch_circles[tickToClose] = {}
  end

  if global.watch_circles[tickToClose][gID] == nil then
    global.watch_circles[tickToClose][gID] = {}
  end

  table.insert(global.watch_circles[tickToClose][gID], foe)
end


export.CloseWatchCircle = function(gIDFoeMap)

  for gID, foeList in pairs(gIDFoeMap) do
    -- Check if our searchlight was destroyed in the ticks since the circle was opened
    if not global.gestalts[gID] then
      goto continue
    end

    local g = global.gestalts[gID]
    if not g.spotter then
      goto continue
    end

    local sPos = g.spotter.position
    global.unum_to_g[g.spotter.unit_number] = nil
    g.spotter.destroy()
    g.spotter = nil

    local foe = u.GetNearestShootableEntFromList(sPos, foeList)

    if foe then
      -- Case: Foe spotted successfully
      RaiseAlarm(g, foe)
    elseif g.light.shooting_target == g.turtle then
      -- Case: Watch circle closed but no foe spotted
      ct.ResumeTurtleDuty(g, nil)
    end
    -- else
      -- Case: Foe previously spotted and alarm raised,
      --       this is just the original, stale watch circle expiring

    ::continue::
  end

end


return export
