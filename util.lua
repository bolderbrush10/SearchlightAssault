require "defines"


-- We don't need to these put in the globals, since it's fine to recalulate them on game load
local DirectionToVector = {}
local firing_arcs = {}
local firing_range = {}


-- Directions come as a number between 0 and 8 (as used in defines.direction)
-- Let's represent them as vectors, as aligned to the screen-coordinate system
DirectionToVector[defines.direction.north]     = {x =  0, y = -1}
DirectionToVector[defines.direction.northwest] = {x = -1, y = -1}
DirectionToVector[defines.direction.west]      = {x = -1, y =  0}
DirectionToVector[defines.direction.southwest] = {x = -1, y =  1}
DirectionToVector[defines.direction.south]     = {x =  0, y =  1}
DirectionToVector[defines.direction.southeast] = {x =  1, y =  1}
DirectionToVector[defines.direction.east]      = {x =  1, y =  0}
DirectionToVector[defines.direction.northeast] = {x =  1, y = -1}


function len(a, b)
  return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2)
end


-- Calculating the square root is usually slower than just squaring whatever you compare to
function lensquared(a, b)
  return (a.x - b.x)^2 + (a.y - b.y)^2
end


function square(a)
  return a*a
end


function doesPositionMatch(posA, posB, acceptable_radius)
  return lensquared(posA, posB) < square(acceptable_radius)
end


-- theta given as 0.0 - 1.0, 0/1 is top middle of screen
function OrientationToPosition(origin, theta, distance)
  local radTheta = theta * 2 * math.pi

  -- Invert y to fit screen coordinates
  return {x = origin.x + math.sin(radTheta) * distance,
          y = origin.y + math.cos(radTheta) * distance * -1,}
end


function IsPositionWithinTurretArc(pos, turret)
  local arc = LookupArc(turret)

  if arc <= 0 then
    return true
  end

  local arcRad = arc * math.pi

  local vecTurPos = {x = pos.x - turret.position.x,
                     y = pos.y - turret.position.y}
  local vecTurDir = DirectionToVector[turret.direction]

  local tanPos = math.atan2(vecTurPos.y, vecTurPos.x)
  local tanDir = math.atan2(vecTurDir.y, vecTurDir.x)

  local angleL = tanDir - tanPos
  local angLAdjust = angleL
  if angLAdjust < 0 then
    angLAdjust = angLAdjust + (math.pi * 2)
  end

  local angleR = tanPos - tanDir
  local angRAdjust = angleR
  if angRAdjust < 0 then
    angRAdjust = angRAdjust + (math.pi * 2)
  end

  return angLAdjust < arcRad or angRAdjust < arcRad
end


function LookupArc(turret)
  if global.firing_arcs[turret.name] then
    return global.firing_arcs[turret.name]
  end

  local tPrototype = game.entity_prototypes[turret.name]

  if tPrototype.attack_parameters
     and tPrototype.attack_parameters.turn_range then
    global.firing_arcs[turret.name] = tPrototype.attack_parameters.turn_range
  else
    global.firing_arcs[turret.name] = -1
  end

  return global.firing_arcs[turret.name]
end


function LookupRange(turret)
  if global.firing_range[turret.name] then
    return global.firing_range[turret.name]
  end

  local tPrototype = game.entity_prototypes[turret.name]

  if tPrototype.turret_range then
    global.firing_range[turret.name] = tPrototype.turret_range
  elseif tPrototype.attack_parameters
     and tPrototype.attack_parameters.range then
    global.firing_range[turret.name] = tPrototype.attack_parameters.range
  else
    global.firing_range[turret.name] = -1
  end

  return global.firing_range[turret.name]
end


-- "Do note that reading from a LuaFluidBox creates a new table and writing will copy the given fields from the table into the engine's own fluid box structure.
--  Therefore, the correct way to update a fluidbox of an entity is to read it first, modify the table, then write the modified table back.
--  Directly accessing the returned table's attributes won't have the desired effect."
-- https://lua-api.factorio.com/latest/LuaFluidBox.html
function CopyFluids(oldT, newT)

  -- Must manually index this part, too.
  for boxindex = 1, #oldT.fluidbox do
    local oldFluid = oldT.fluidbox[boxindex]
    local newFluid = newT.fluidbox[boxindex]

    newFluid = oldFluid
    newT.fluidbox[boxindex] = newFluid
  end

end


function CopyItems(oldTinv, newTinv)

  for boxindex = 1, #oldTinv do
    local oldStack = oldTinv[boxindex]
    local newStack = newTinv[boxindex]

    newStack = oldStack
    newTinv.insert(newStack)
  end

end


function CopyTurret(oldT, newT)
  newT.copy_settings(oldT)
  newT.kills = oldT.kills
  newT.health = oldT.health
  newT.last_user  = oldT.last_user
  newT.direction = oldT.direction
  newT.orientation = oldT.orientation
  newT.damage_dealt = oldT.damage_dealt

  if oldT.energy ~= nil then
    newT.energy = oldT.energy
  end

  if oldT.get_output_inventory() ~= nil then
    CopyItems(oldT.get_output_inventory(), newT.get_output_inventory())
  end

  if oldT.get_module_inventory() ~= nil then
    CopyItems(oldT.get_module_inventory(), newT.get_module_inventory())
  end

  if oldT.get_fuel_inventory() ~= nil then
    CopyItems(oldT.get_fuel_inventory(), newT.get_fuel_inventory())
  end

  if oldT.get_burnt_result_inventory() ~= nil then
    CopyItems(oldT.get_burnt_result_inventory(), newT.get_burnt_result_inventory())
  end

  if oldT.fluidbox ~= nil then
    CopyFluids(oldT, newT)
  end
end
