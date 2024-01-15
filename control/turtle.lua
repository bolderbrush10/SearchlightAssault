----------------------------------------------------------------
  local d = require "sl-defines"
  local u = require "sl-util"

  -- forward declarations
  local SpawnTurtle
----------------------------------------------------------------
  
-- location is expected to be the searchlight's last shooting target,
-- if it was targeting something.
function SpawnTurtle(sl, turtleForce, location)

  if location == nil then
    -- Start in front of the turret's base, wrt orientation
    location = u.OrientationToPosition(sl.position, sl.orientation, 3)
  end

  local turtle = sl.surface.create_entity{name = d.turtleName,
                                          position = location,
                                          force = turtleForce,
                                          create_build_effect_smoke = false}

  if not turtle then
    log("Searchlight Assault: Failed to spawn turtle!")
    return nil
  end
  
  global.unum_to_g[turtle.unit_number] = g -- TODO
  b.add(g.unum_x_reg, turtle.unit_number, script.register_on_entity_destroyed(turtle), g)

  turtle.destructible = false
  return turtle
end


----------------------------------------------------------------
  local public = {}
  public.SpawnTurtle = SpawnTurtle
  return public
----------------------------------------------------------------
