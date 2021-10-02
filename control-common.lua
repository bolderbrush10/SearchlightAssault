local d = require "sl-defines"
local u = require "sl-util"


function InitTables()
  -------------------------
  -- Searchlight Gestalt --
  -------------------------
  --[[ Gestalt:
  {
    gID = int (gID),
    base = BaseSearchlight,
    signal = SignalInterface,
    spotter = nil / Spotter,
    turtle = Turtle,
    turtleActive = true/false, -- Used to 'latch' active state during power outages
    turtleCoord = nil / {x, y}
    tunions = Map: tuID -> true
  }
  ]]--

  global.gID = 0

  -- Map: gestalt ID -> Gestalt
  global.gestalts = {}

  -- Map: unit_number -> Gestalt
  -- Currently tracking: baselight, spotter, turtle -> Gestalt
  global.unum_to_g = {}

  ------------------
  -- Turret Union --
  ------------------
  --[[ TUnion:
  {
    tuID = int (tuID),
    turret = base / boosted,
    boosted = true / false,
    lights = Map: gID -> true,
    control = &entity,
  }
  ]]--

  global.tuID = 0

  -- Map: turret union ID -> TUnion
  global.tunions = {}

  -- Map: turret unit_number -> tID
  global.tun_to_tID = {}

  -- Map: boosted turret unit_number -> tID
  global.boosted_to_tuID = {}

  -----------------
  --     Foe     --
  -----------------

  -- Map: foe unit_number -> foe entity
  global.foes = {}

  -- Map: foe unit_number -> Map: gID -> true
  global.fun_to_gIDs = {}

  ------------------
  --    Forces    --
  ------------------

  -- Map: Turtle Force Name -> true
  global.sl_force_init = {}

  ------------------
  -- Watch Circle --
  ------------------

  -- Map: game tick -> Map: gID -> [foes]
  global.watch_circles = {}
end


-------------------------------------------------------------------------------
-- Private
-------------------------------------------------------------------------------


local function newTUID()
  global.tuID = global.tuID + 1
  return global.tuID
end


local function newGID()
  global.gID = global.gID + 1
  return global.gID
end


local function makeGestalt(sl, sigInterface, turtle)
  return {gID = newGID(), base = sl, signal = sigInterface, spotter = nil, turtle = turtle, turtleActive = true, tunions = {}}
end


-- Memoize; don't need to track this in global, save memory by recalculating across save/loads
local boostInfo = {}

local function boostTruth(turret)
  local info = boostInfo[turret]
  if info then
    if info == "nil" then
      return nil
    else
      return info
    end
  end

  if game.entity_prototypes[turret.name .. d.boostSuffix] then
    boostInfo[turret] = false
    return false
  -- A neat trick to see if a string ends with a given suffix
  elseif turret.name:sub(-#d.boostSuffix) == d.boostSuffix then
    boostInfo[turret] = true
    return true
  else
    boostInfo[turret] = "nil"
    return nil -- Not a boostable / boosted turret, ignore it
  end
end


local function updateTUnionSL(tunion, gIDs)
  if not gIDs then
    return
  end

  for i, gID in pairs(gIDs) do
    tunion.lights[gID] = true
    global.gestalts[gID].tunions[tunion.tuID] = true
  end
end


-- May return nil if turret is not boosted / boostable
local function makeTUnionFromTurret(turret, gIDs)
  local boosted = boostTruth(turret)

  if boosted == nil then
    return nil
  end

  tunion = {tuID = newTUID(), turret = turret, boosted = boosted, lights = {}, control = nil}

  global.tunions[tunion.tuID] = tunion
  global.tun_to_tID[turret.unit_number] = tunion

  updateTUnionSL(tunion, gIDs)

  return tunion
end


local function removeGestaltfromTUnions(gID)
  for tuID, tunion in pairs(global.tunions) do
    tunion.lights[gID] = nil
  end
end


local function removeGestaltfromFoes(gID)
  for foe_unit_number, gMap in pairs(global.fun_to_gIDs) do

    gMap[gID] = nil

    -- If no other searchlights were tracking this foe, clear it
    if next(gMap) == nil then
      global.foes[foe_unit_number] = nil
      global.fun_to_gIDs[foe_unit_number] = nil
    end

  end
end

-------------------------------------------------------------------------------
-- Public
-------------------------------------------------------------------------------

function maps_addGestalt(sl, sigInterface, turtle, turretList)
  local g = makeGestalt(sl, sigInterface, turtle)

  global.gestalts[g.gID] = g
  global.unum_to_g[sl.unit_number] = g
  global.unum_to_g[turtle.unit_number] = g

  for i, t in pairs(turretList) do
    maps_getTUnion(t, {g.gID}) -- creates TUnions if necessary and updates our lights member
  end

  return g
end


function maps_getGestalt(unit)
  if unit.unit_number then
    return global.unum_to_g[unit.unit_number]
  end

  return nil
end


function maps_removeGestaltAndDestroyHiddenEnts(g)
  removeGestaltfromFoes(g.gID)
  removeGestaltfromTUnions(g.gID)

  global.gestalts[g.gID] = nil
  global.unum_to_g[g.base.unit_number] = nil
  global.unum_to_g[g.turtle.unit_number] = nil
  maps_removeSpotter(g)

  g.signal.destroy()
  g.turtle.destroy()
end


function maps_updateTurtle(old, new)
  global.unum_to_g[old.unit_number].turtle = new
  global.unum_to_g[new.unit_number] = global.unum_to_g[old.unit_number]
  global.unum_to_g[old.unit_number] = nil
end


function maps_addTUnion(turret, searchlights)
  if #searchlights == 0 then
    return -- No point in tracking turrets without a searchlight
  end

  if boostTruth(turret) == nil then
    return -- No point in tracking turrets we can't boost
  end

  local gIDs = {}

  for i, sl in pairs(searchlights) do
    table.insert(gIDs, global.unum_to_g[sl.unit_number].gID)
  end

  makeTUnionFromTurret(turret, gIDs)
end


-- May pass in nil for gIDs
-- May return nil if turret is not boosted / boostable
function maps_getTUnion(turret, gIDs)
  if not global.tun_to_tID[turret.unit_number] then
    makeTUnionFromTurret(turret, gIDs)
  else
    updateTUnionSL(global.tun_to_tID[turret.unit_number], gIDs)
  end

  return global.tun_to_tID[turret.unit_number]
end


function maps_removeTUnion(turret)
  local tu = global.tun_to_tID[turret.unit_number]
  if tu == nil then
    return
  end

  for gID, gIDval in pairs(tu.lights) do
    global.gestalts[gID].tunions[tu.tuID] = nil
  end

  if tu.control then
    tu.control.destroy()
    tu.control = nil
  end

  global.tunions[tu.tuID] = nil
  global.boosted_to_tuID[turret.unit_number] = nil
  global.tun_to_tID[turret.unit_number] = nil
end


function maps_boostTurret(base, boosted, control_unit)
  local tu = global.tun_to_tID[base.unit_number]
  global.tun_to_tID[base.unit_number] = nil
  global.tun_to_tID[boosted.unit_number] = tu
  global.boosted_to_tuID[boosted.unit_number] = tu.tuID

  tu.turret = boosted
  tu.boosted = true
  tu.control = control_unit
end


function maps_unboostTurret(base, boosted)
  local tu = global.tun_to_tID[boosted.unit_number]
  global.tun_to_tID[boosted.unit_number] = nil
  global.tun_to_tID[base.unit_number] = tu
  global.boosted_to_tuID[boosted.unit_number] = nil

  tu.turret = base
  tu.boosted = false
  tu.control.destroy()
  tu.control = nil
end


function maps_addSpotter(spotter, gestalt)
  global.unum_to_g[spotter.unit_number] = gestalt
  gestalt.spotter = spotter
end


function maps_removeSpotter(g)
  if not g.spotter then
    return
  end

  global.unum_to_g[g.spotter.unit_number] = nil
  g.spotter.destroy()
  g.spotter = nil
end


function maps_addFoe(foe, gestalt)
  global.foes[foe.unit_number] = foe

  if not global.fun_to_gIDs[foe.unit_number] then
    global.fun_to_gIDs[foe.unit_number] = {}
  end

  global.fun_to_gIDs[foe.unit_number][gestalt.gID] = true
end


function maps_removeFoeByUnitNum(foe_unit_number)
  global.foes[foe_unit_number] = nil
  global.fun_to_gIDs[foe_unit_number] = nil
  -- garbage collector should clear out the sub-table
end
