----------------------------------------------------------------
  local b  = require "bidirmap"
  local r  = require "relation"
  local d  = require "../sl-defines"
  local u  = require "../sl-util"

  -- forward declarations
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
  -- Moods: &entity
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

  ct.SetDefaultWanderParams(g)

  return g
end


----------------------------------------------------------------
  local public = {}
  return public
----------------------------------------------------------------
