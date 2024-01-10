local d = require "sl-defines"


local u = {} -- export functions


local pairs = pairs


-- We don't need to these put in the globals, since it's fine to recalulate them after game load
local firing_arcs = {}
local firing_range = {}
local DirectionToVector = {}


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

local bufferedRange = d.searchlightRange - (d.searchlightSpotRadius)

u.EndsWith =
function(str, suffix)
  -- A neat trick to see if a string ends with a given suffix
  return str:sub(-#suffix) == suffix
end


-- Instead of using math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2),
-- it's usually faster to just square whatever we're comparing against
u.lensquared =
function(a, b)
  return (a.x - b.x)^2 + (a.y - b.y)^2
end


u.square =
function(a)
  return a*a
end


-- Initially, we'll search for all turrets within a fairly large area,
-- then fine-tune the search with edge-to-edge calculations later.
-- This is useful for finding extra-large turrets of sizes like 5x5.
local boostableArea =
{
  x = d.searchlightMaxNeighborDistance + 10,
  y = d.searchlightMaxNeighborDistance + 10
}


u.GetBoostableAreaFromPosition =
function(position)
  local adjusted = {left_top = {x, y}, right_bottom = {x, y}}
  adjusted.left_top.x     = position.x - boostableArea.x
  adjusted.left_top.y     = position.y - boostableArea.y
  adjusted.right_bottom.x = position.x + boostableArea.x
  adjusted.right_bottom.y = position.y + boostableArea.y

  return adjusted
end


u.WithinRadius =
function(posA, posB, acceptable_radius)
  return u.lensquared(posA, posB) < u.square(acceptable_radius)
end


u.UnpackRectangles =
function(a, b)
  return a.left_top.x, a.left_top.y, a.right_bottom.x, a.right_bottom.y,
         b.left_top.x, b.left_top.y, b.right_bottom.x, b.right_bottom.y
end


u.RectangeDistSquared =
function(aTopLeftx, aTopLefty, aBottomRightx, aBottomRighty,
         bTopLeftx, bTopLefty, bBottomRightx, bBottomRighty)
    left = bBottomRightx < aTopLeftx
    right = aBottomRightx < bTopLeftx
    bottom = bBottomRighty < aTopLefty
    top = aBottomRighty < bTopLefty
    if top and left then
        return u.lensquared({x=aTopLeftx,     y=aBottomRighty}, {x=bBottomRightx, y=bTopLefty})
    elseif left and bottom then
        return u.lensquared({x=aTopLeftx,     y=aTopLefty},     {x=bBottomRightx, y=bBottomRighty})
    elseif bottom and right then
        return u.lensquared({x=aBottomRightx, y=aTopLefty},     {x=bTopLeftx,     y=bBottomRighty})
    elseif right and top then
        return u.lensquared({x=aBottomRightx, y=aBottomRighty}, {x=bTopLeftx,     y=bTopLefty})
    elseif left then
        return u.square(aTopLeftx - bBottomRightx)
    elseif right then
        return u.square(bTopLeftx - aBottomRightx)
    elseif bottom then
        return u.square(aTopLefty - bBottomRighty)
    elseif top then
        return u.square(bTopLefty - aBottomRighty)
    else -- rectangles intersect
        return 0
    end
end


u.ClampCoordToDistance =
function(coord, distance)
  local theta = math.atan2(coord.y, coord.x)
  return u.ScreenOrientationToPosition({x=0, y=0}, theta, distance)
end


-- theta given as 0.0 - 1.0, 0/1 is top middle of screen
u.OrientationToPosition =
function(origin, theta, distance)
  local radTheta = theta * 2 * math.pi

  -- Invert y to fit screen coordinates
  return {x = origin.x + math.sin(radTheta) * distance,
          y = origin.y + math.cos(radTheta) * distance * -1,}
end


-- theta given as radians, assumes screen-coordinates already in use
u.ScreenOrientationToPosition =
function(origin, radTheta, distance)
  return {x = origin.x + math.cos(radTheta) * distance,
          y = origin.y + math.sin(radTheta) * distance,}
end


u.TranslateCoordinate =
function(gestalt, coord)
  local translatedCoord = {x=coord.x, y=coord.y}

  -- Clamp excessive ranges so the turtle doesn't go past the searchlight max radius
  if u.lensquared(coord, {x=0, y=0}) > u.square(bufferedRange) then
    translatedCoord = u.ClampCoordToDistance(translatedCoord, bufferedRange)
  end

  translatedCoord.x = translatedCoord.x + gestalt.light.position.x
  translatedCoord.y = translatedCoord.y + gestalt.light.position.y

  return translatedCoord
end


u.clamp = function(value, min, max, default)
  if not value or value == 0 then
    return default
  else
    if value < min then
      return min
    elseif value > max then
      return max
    end
  end

  return value
end


-- Clamps values to 1 - 360, treating 0 as 360
-- (rendering.draw_arc creates beautiful but glitchy lines
--  when given negative or excessive values)
u.clampDeg = function(value, default, returnZero)
  if not value then
    return default
  end

  if value == 0 or value == 360 then
    if returnZero then
      return 0
    else
      return 360
    end
  elseif value > 0 then
    return value % 360
  else
    -- return 360 - (value % 360)
    -- Believe it or not, but factorio's version of lua acts like the above for negatives
    -- (version 5.4.3 does not, and requires that line above)
    return value % 360
  end
end


local function LookupArc(turret)
  if firing_arcs[turret.name] then
    return firing_arcs[turret.name]
  end

  local tPrototype = game.entity_prototypes[turret.name]

  if tPrototype.attack_parameters
     and tPrototype.attack_parameters.turn_range then
    firing_arcs[turret.name] = tPrototype.attack_parameters.turn_range
  else
    firing_arcs[turret.name] = -1
  end

  return firing_arcs[turret.name]
end



local function LookupRange(turret)
  if firing_range[turret.name] then
    return firing_range[turret.name]
  end

  local tPrototype = game.entity_prototypes[turret.name]

  if tPrototype.turret_range then
    firing_range[turret.name] = tPrototype.turret_range
  elseif tPrototype.attack_parameters
     and tPrototype.attack_parameters.range then
    firing_range[turret.name] = tPrototype.attack_parameters.range
  else
    firing_range[turret.name] = -1
  end

  return firing_range[turret.name]
end


local function CheckActDelivery(actDelivery, rangeMod, min)
  local val = actDelivery.max_range
  if val and rangeMod then
    val = val * rangeMod
  end

  if val and min and val < min then
    min = val
  elseif val then
    min = val
  end

  return min
end


local function CheckAmmoAction(ammoAction, rangeMod, min)
  if not ammoAction.action_delivery then
    return min
  end

  -- action_delivery can either be a table of ammo_types,
  -- or just the action_delivery entry directly...
  if ammoAction.action_delivery.type then
    min = CheckActDelivery(ammoAction.action_delivery, rangeMod, min)    
  else
    for _, del in pairs(ammoAction.action_delivery) do
      min = CheckActDelivery(del, rangeMod, min)              
    end
  end

  return min
end


local function CheckAmmo(turret)
  local inv = turret.get_inventory(defines.inventory.turret_ammo)
  if not inv then
    return nil
  end

  -- No idea how to tell which slot a multi-slot inventory is spending ammo from,
  -- so just report the worst-case of all of them.
  local min = nil
  for index=1, #inv do
    if inv[index] and inv[index].valid and inv[index].valid_for_read then
      local prototype = game.item_prototypes[inv[index].name]
      if prototype then

        local ammoType = prototype.get_ammo_type("turret")
        if ammoType and ammoType.action then
          local rangeMod = ammoType.range_modifier

          -- action can either be a table of ammo_types,
          -- or just the action entry directly...
          if ammoType.action.type then
            min = CheckAmmoAction(ammoType.action, rangeMod, min)
          else
            for _, a in pairs(ammoType.action) do
              min = CheckAmmoAction(a, rangeMod, min)
            end
          end
        end

      end
    end
  end

  return min
end


u.IsPositionWithinTurretArc =
function(pos, turret, checkAmmoRange)
  if checkAmmoRange then
    local ammoRange = CheckAmmo(turret)

    if ammoRange and not u.WithinRadius(pos, turret.position, ammoRange - 2) then
      return False
    end
  end

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


-- "Do note that reading from a LuaFluidBox creates a new table and writing will copy the given fields from the table into the engine's own fluid box structure.
--  Therefore, the correct way to update a fluidbox of an entity is to read it first, modify the table, then write the modified table back.
--  Directly accessing the returned table's attributes won't have the desired effect."
-- https://lua-api.factorio.com/latest/LuaFluidBox.html
local function CopyFluids(oldT, newT)

  -- Must manually index this part, too.
  for boxindex = 1, #oldT.fluidbox do
    local oldFluid = oldT.fluidbox[boxindex]
    local newFluid = newT.fluidbox[boxindex]

    newFluid = oldFluid
    newT.fluidbox[boxindex] = newFluid
  end

end


local function CopyItems(oldTinv, newTinv)

  for boxindex = 1, #oldTinv do
    local oldStack = oldTinv[boxindex]
    local newStack = newTinv[boxindex]

    newStack = oldStack
    newTinv.insert(newStack)
  end

end


u.CopyTurret =
function(oldT, newT)
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

u.CheckEntityOrDriver =
function(entity)
  -- Checking for existence of energy_per_hit_point is the best way I can figure out to easily
  -- check if we're looking at a vehicle
  if entity and entity.valid and entity.destructible and entity.prototype.energy_per_hit_point then
    local driver = entity.get_driver()
    if driver and driver.valid and driver.is_entity_with_owner and driver.destructible then
      return driver
    end
  elseif entity and entity.valid and entity.is_entity_with_owner and entity.destructible then
    return entity
  else
    return nil
  end

end

u.GetNearestShootableEntFromList =
function(position, entityList)
  if entityList == nil then
    return nil
  end

  local e1 = entityList[1]
  if e1 == nil then
    return nil
  end

  if entityList[2] == nil then
    return u.CheckEntityOrDriver(e1)
  end

  local bestDist = 999999
  local bestE = nil

  for _, e in pairs(entityList) do
    local eCheck = u.CheckEntityOrDriver(e)
    if eCheck then
      local dist = u.lensquared(position, eCheck.position)
      if dist < bestDist then
        bestDist = dist
        bestE = eCheck
      end
    end
  end

  return bestE
end


return u
