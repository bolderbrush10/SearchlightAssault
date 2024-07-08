----------------------------------------------------------------
  local b  = require "bidirmap"
  local f  = require "forces"
  local d  = require "sl-defines"
  local r  = require "relation"
  local u  = require "sl-util"

  local ct = require "turtle"
  local cs = require "searchlight"

  -- forward declarations
  local SearchlightAdded
  local InitTables_Gestalt
----------------------------------------------------------------


-------------------------
-- Searchlight Gestalt --
-------------------------
--[[
{
  gID           = int (gestalt ID),
  light         = Searchlight / Alarmlight / Safelight,
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
  nosleep       = true/false
}
]]--


function InitTables_Gestalt()
  global.gID = 0

  -- Map: gID -> Gestalt
  global.gestalts = {}

  -- Map: gID -> Gestalt
  global.check_power = {}

  -- Map: game tick -> {gID}
  global.spotter_timeouts = {}

  -- Map: Unit Number <--> script.register_on_entity_destroyed() ID
  -- Moods: &Gestalt
  -- Essential gestalt components.
  -- If one of these fires (indestructibles killed by map editor?), 
  -- the gestalt is probably broken. Go ahead and kill the entire gestalt.
  global.unum_x_reg = b.new()

  -- Map: Unit Number <--> script.register_on_entity_destroyed() ID
  -- Moods: &Gestalt
  -- If one of these fires, it means a turtle died. 
  -- Turtles can die for like, no reason. Just respawn the turtle.
  global.turtle_x_reg = b.new()

  -- Map: Foe Unit Number <--> foe script.register_on_entity_destroyed() ID
  -- Moods: true
  global.fun_x_reg = b.new()

  -- Foe Unit Number <--> Gestalt ID
  -- Moods: &FoeEntity
  global.fun_x_gID = b.new()

  -- Turret Union ID <--> Gestalt ID
  -- Moods: &Gestalt
  global.tuID_x_gID = b.new()

  -- Map: game tick -> {gID}
  global.animation_sync = {}
end


function newGID()
  global.gID = global.gID + 1
  return global.gID
end


function makeGestalt(sl, sigInterface, turtle, spotter)
  local g = {gID = newGID(),
             light = sl,
             signal = sigInterface,
             spotter = spotter,
             turtle = turtle,
             nosleep = false}

  global.gestalts[g.gID] = g

  global.check_power[g.gID] = g

  SetDefaultWanderParams(g)

  return g
end


function SearchlightAdded(sl)

  if global.migrated then
    game.print("Migrated")
  else
    game.print("no migrated")
  end


  if global.migratedtwo then
    game.print("Migrated2")
  else
    game.print("no migrated2")
  end

  if global.migratedthree then
    game.print("Migrated3")
  else
    game.print("no migrated3")
  end

  -- Don't allow building searchlights while uninstallation desired
  if settings.global[d.uninstallMod].value then
    sl.destroy()
    return
  end

  local tforce = f.PrepareTurtleForce(sl.force)
  local turtle = ct.SpawnTurtle(sl, tforce, nil)

  local g = makeGestalt(sl,
                        cs.spawnSignalInterface(sl),
                        turtle,
                        cs.spawnSpotter(sl, turtle.force))

  -- TODO is this how we want to do this? Should this live in control-lifecyle or somewhere else?

  -- Register our searchlight so if it gets removed by the map editor or another mod,
  -- and thus no on_mined / on_died event is called, we can still destroy our gestalt
  regLight(g, g.light)

  -- register our turtle and supports
  global.unum_to_g[turtle.unit_number] = g -- TODO
  b.add(global.unum_x_reg, turtle.unit_number, script.register_on_entity_destroyed(turtle), g)

  regSupport(g, g.spotter)
  regSupport(g, g.signal)

  sl.shooting_target = turtle
  ct.WindupTurtle(g, turtle)

  -- TODO 
  -- export.OpenWatch(g.gID)

  -- TODO Move this to lifecycle?
  local friends = sl.surface.find_entities_filtered{area=u.GetBoostableAreaFromPosition(sl.position),
                                                    type={"fluid-turret", "electric-turret", "ammo-turret"},
                                                    force=sl.force}

  for _, f in pairs(friends) do
    cu.CreateRelationship(g, f)
  end
end


function SearchlightRemoved(sl_unit_number, killed, g)
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


function regSupport(g, e)
  global.unum_to_g[e.unit_number] = g
  b.add(g.unum_x_reg, e.unit_number, script.register_on_entity_destroyed(e), g)
end


function regLight(g, sl)
  global.unum_to_g[sl.unit_number] = g
  b.add(g.unum_x_reg, sl.unit_number, script.register_on_entity_destroyed(sl), g)

  g.light = sl
end


function deregLight(g, sl)
  global.unum_to_g[sl.unit_number] = nil
  b.removeLHS(g.unum_x_reg, sl.unit_number)
end


function SetDefaultWanderParams(g)
  g.tWanderParams =
  {
    radius = 0,
    rotation = 0,
    min = 0,
    max = 0
  }
end

----------------------------------------------------------------
  local public = {}
  public.SearchlightAdded = SearchlightAdded
  public.InitTables_Gestalt = InitTables_Gestalt  
  return public
----------------------------------------------------------------
