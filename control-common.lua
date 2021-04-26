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

  -- Map: attackLight unit_number -> Turtle
  global.attackSL_to_turtle = {}

  -----------------
  --   Turtle    --
  -----------------

  -- Map: turtle unit_number -> Turtle
  global.turtles = {}

  -- Map: turtle unit_number -> Searchlight
  global.turtle_to_baseSL = {}

  -----------------
  --     Foe     --
  -----------------

  -- Map: foe unit_number -> foe
  global.foes = {}

  -- Map: foe unit_number -> Attacklight
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


function maps_addSearchlight(sl, attackLight, turtle)
  global.base_searchlights[sl.unit_number] = sl
  global.baseSL_to_attackSL[sl.unit_number] = attackLight
  global.baseSL_to_turtle[sl.unit_number] = turtle


  global.attackSL_to_turtle[attackLight.unit_number] = turtle


  global.turtles[turtle.unit_number] = turtle
  global.turtle_to_baseSL[turtle.unit_number] = sl


  -- TODO boostables
end


function maps_removeSearchlight(sl)
  global.base_searchlights[sl.unit_number] = nil

  attackLight = global.baseSL_to_attackSL[sl.unit_number]
  global.baseSL_to_attackSL[sl.unit_number] = nil

  turtle = global.baseSL_to_turtle[sl.unit_number]
  global.baseSL_to_turtle[sl.unit_number] = nil


  global.attackSL_to_turtle[attackLight.unit_number] = nil
  maps_removeFoeSL(attackLight)
  attackLight.destroy()


  global.turtles[turtle.unit_number] = nil
  global.turtle_to_baseSL[turtle.unit_number] = nil
  turtle.destroy()


  -- TODO remove boostables
end


function maps_updateTurtle(old, new)
  sl = global.turtle_to_baseSL[old.unit_number]
  attackLight = global.baseSL_to_attackSL[sl.unit_number]

  global.baseSL_to_turtle[sl.unit_number] = new
  global.attackSL_to_turtle[attackLight.unit_number] = new

  global.turtles[old.unit_number] = nil
  global.turtle_to_baseSL[old.unit_number] = nil

  global.turtles[new.unit_number] = new
  global.turtle_to_baseSL[new.unit_number] = sl
end


function maps_removeFoeByUnitNum(foe_unit_number)

  global.foes[foe_unit_number] = nil
  global.foe_to_attackSL[foe_unit_number] = nil
  -- garbage collector should clear out the sub-table

end


function maps_addFoeSL(foe, base_sl)

  global.foes[foe.unit_number] = foe

  -- nb, a foe may be tracked by multiple searchlights at the same time
  if not global.foe_to_attackSL[foe.unit_number] then
    global.foe_to_attackSL[foe.unit_number] = {}
  end
  table.insert(global.foe_to_attackSL[foe.unit_number], base_sl)

end


-- semi-duplicated in control-searchlight:TrackSpottedFoes for performance reasons
function maps_removeFoeSL(attackLight)
  local copyfoe_to_baseSL = global.foe_to_attackSL

  for foe_unit_number, slList in pairs(copyfoe_to_baseSL) do
    for index, light in pairs(slList) do
      if light.unit_number == attackLight.unit_number then
        table.remove(global.foe_to_attackSL[foe_unit_number], index)
      end
    end

    if next(global.foe_to_attackSL[foe_unit_number]) == nil then
      maps_removeFoeByUnitNum(foe_unit_number)
    end
  end
end
