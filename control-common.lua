require "defines"
require "util"

function InitTables()
  -----------------
  -- Base-Searchlight --
  -----------------

  -- Map: searchlight unit_number -> Searchlight
  global.base_searchlights = {}

  -- Map: searchlight unit_number -> Last shooting position
  global.baseSL_to_lsp = {}

  -- Map: eitherlight unit_number -> List: [Neighbor Turrets]
  global.baseSL_to_boostable = {}

  -- Map: searchlight unit_number -> remaining ticks
  global.baseSL_to_unboost_timers = {}

  -----------------
  -- Attack-Searchlight  --
  -----------------

  -- Map: dummylight unit_number -> Attacklight
  global.attack_searchlights = {}

  -- Map: searchlight unit_number -> Attacklight
  global.baseSL_to_attackSL = {}

  -----------------
  --   Turtle    --
  -----------------

  -- Map: turtle unit_number -> Turtle
  global.turtles = {}

  -- Map: searchlight unit_number -> Turtle
  global.baseSL_to_turtle = {}

  -- Map: Turtle -> Position: [x,y]
  global.turtle_to_waypoint = {}
end
