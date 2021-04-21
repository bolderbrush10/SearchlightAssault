require "sl-defines"
require "sl-util"


-- TODO Should more of these maps be indexed by unit number
--      instead of entity-reference?
function InitTables()
  ----------------------
  -- Base-Searchlight --
  ----------------------

  -- Map: searchlight unit_number -> Searchlight
  global.base_searchlights = {}

  -- Map: searchlight unit_number -> Attacklight
  global.baseSL_to_attackSL = {}

  -- Map: searchlight unit_number -> Turtle
  global.baseSL_to_turtle = {}

  -- Map: eitherlight unit_number -> List: [Neighbor Turrets]
  global.baseSL_to_boostable = {}

  -- Map: searchlight unit_number -> remaining ticks
  global.baseSL_to_unboost_timers = {}

  ------------------------
  -- Attack-Searchlight --
  ------------------------

  -- Map: attacklight unit_number -> Turtle
  global.attackSL_to_turtle = {}

  -----------------
  --   Turtle    --
  -----------------

  -- Map: turtle unit_number -> Turtle
  global.turtles = {}

  -- Map: turtle unit_number -> Searchlight
  global.turtle_to_baseSL = {}

  -- Map: turtle -> Position: [x,y]
  -- TODO Do I need this?
  global.turtle_to_waypoint = {}

  -----------------
  --     Foe     --
  -----------------

  -- Map: foe -> Attacklight
  global.foe_to_attackSL = {}

  -----------------
  --    Grids    --
  -----------------

  -- Force.index -> "x,y" -> Grid
  -- TODO Do we have to care about other forces, or does the engine hide that for us?
  global.forceToPositionToGrid = {}

  -- Grid -> Grid
  global.gridsWithFoes = {}

end


-- TODO missing a bunch of stuff
function maps_addSearchlight(sl, attackLight, turtle)
  global.base_searchlights[sl.unit_number] = sl
  global.baseSL_to_attackSL[sl.unit_number] = attackLight
  global.baseSL_to_turtle[sl.unit_number] = turtle

  global.attackSL_to_turtle[attackLight.unit_number] = turtle

  global.turtles[turtle.unit_number] = turtle
  global.turtle_to_baseSL[turtle.unit_number] = sl
end


-- TODO missing a bunch of stuff
function maps_removeSearchlight(sl)
  global.base_searchlights[sl.unit_number] = nil
  global.baseSL_to_attackSL[sl.unit_number].destroy()
  global.baseSL_to_attackSL[sl.unit_number] = nil
  turtle = global.baseSL_to_turtle[sl.unit_number]
  global.baseSL_to_turtle[sl.unit_number] = nil


  global.turtles[turtle.unit_number] = nil
  global.turtle_to_waypoint[turtle.unit_number] = nil
  turtle.destroy()

  -- TODO remove boostables
end


function maps_removeFoe(foe)

  global.foe_to_attackSL[foe] = nil

end


function maps_addFoeSL(foe, base_sl)

  -- nb, a foe may be tracked by multiple searchlights at the same time
  if not global.foe_to_attackSL[foe] then
    global.foe_to_attackSL[foe] = {}
  end
  table.insert(global.foe_to_attackSL[foe], base_sl)

end


-- not implemented since performance-critical logic lives in control-searchlight:TrackSpottedFoes
-- function maps_removeFoeSL(foe, sl_index)
