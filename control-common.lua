require "defines"
require "util"

function InitTables()
  ----------------------
  -- Base-Searchlight --
  ----------------------

  -- Map: searchlight unit_number -> Searchlight
  global.base_searchlights = {}

  -- Map: searchlight unit_number -> Last shooting position
  global.baseSL_to_lsp = {}

  -- Map: eitherlight unit_number -> List: [Neighbor Turrets]
  global.baseSL_to_boostable = {}

  -- Map: searchlight unit_number -> remaining ticks
  global.baseSL_to_unboost_timers = {}

  ------------------------
  -- Attack-Searchlight --
  ------------------------

  -- Map: dummylight unit_number -> Attacklight
  global.attack_searchlights = {}

  -- Map: searchlight unit_number -> Attacklight
  global.baseSL_to_attackSL = {}

  -----------------
  --   Turtle    --
  -----------------

  -- Map: turtle unit_number -> Turtle
  global.turtles = {}

  -- Map: turtle unit_number -> Searchlight
  global.tun_to_baseSL = {}

  -- Map: searchlight unit_number -> Turtle
  global.baseSL_to_turtle = {}

  -- Map: Turtle -> Position: [x,y]
  global.turtle_to_waypoint = {}

  -----------------
  --     Foe     --
  -----------------

  -- Map: foe unit_number -> Searchlight
  global.foe_to_baseSL = {}

  -----------------
  --    Grids    --
  -----------------

  -- Force.index -> "x,y" -> Grid
  -- TODO Do we really have to care about other forces?
  global.forceToPositionToGrid = {}

  -- Grid -> Grid
  global.gridsWithFoes = {}

end
