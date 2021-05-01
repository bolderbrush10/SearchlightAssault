require "sl-defines"
require "sl-util"

require "util" -- for table.deepcopy


function InitTables()
  -------------------------
  -- Searchlight Gestalt --
  -------------------------
  --[[ Gestalt:
  {
    gID = int (gID),
    base = BaseSearchlight,
    al = AttackLight,
    turtle = Turtle,
    tunions = Map: tuID -> true
  }
  ]]--

  global.gID = 0

  -- Map: gestalt ID -> Gestalt
  global.gestalts = {}

  -- Map: unit_number -> gID
  -- Currently tracking: baselight, attack light, turtle -> gID
  global.unum_to_gID = {}

  ------------------
  -- Turret Union --
  ------------------
  --[[ TUnion:
  {
    tuID = int (tuID),
    turret = base / boosted,
    boosted = true / false,
    lights = Map: gID -> true
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

  -- TODO What if the only searchlight gets destroyed before a foe dies?
  --      We'd want to clear the foe map's entry

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


local function makeGestalt(sl, attackLight, turtle)
  return {gID = newGID(), base = sl, al = attackLight, turtle = turtle, tunions = {}}
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

  if game.entity_prototypes[turret.name .. boostSuffix] then
    boostInfo[turret] = false
    return false
  -- A neat trick to see if a string ends with a given suffix
  elseif turret.name:sub(-#boostSuffix) == boostSuffix then
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

  tunion = {tuID = newTUID(), turret = turret, boosted = boosted, lights = {}}

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
  end
end

-------------------------------------------------------------------------------
-- Public
-------------------------------------------------------------------------------

function maps_addGestalt(sl, attackLight, turtle, turretList)
  local g = makeGestalt(sl, attackLight, turtle)

  global.gestalts[g.gID] = g
  global.unum_to_gID[sl.unit_number] = g
  global.unum_to_gID[turtle.unit_number] = g
  global.unum_to_gID[attackLight.unit_number] = g

  for i, t in pairs(turretList) do
    maps_getTUnion(t, {g.gID}) -- creates TUnions if necessary and updates our lights member
  end

  return g
end


function maps_getGestalt(unit)
  return global.unum_to_gID[unit.unit_number]
end


function maps_removeGestaltAndDestroyHiddenEnts(g)
  removeGestaltfromFoes(g.gID)
  removeGestaltfromTUnions(g.gID)

  global.gestalts[g.gID] = nil
  global.unum_to_gID[g.al.unit_number] = nil
  global.unum_to_gID[g.base.unit_number] = nil
  global.unum_to_gID[g.turtle.unit_number] = nil

  g.al.destroy()
  g.turtle.destroy()
end


function maps_updateTurtle(old, new)
  global.unum_to_gID[old.unit_number].turtle = new
  global.unum_to_gID[new.unit_number] = global.unum_to_gID[old.unit_number]
  global.unum_to_gID[old.unit_number] = nil
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
    table.insert(gIDs, global.unum_to_gID[sl.unit_number].gID)
  end

  makeTUnionFromTurret(turret, gIDs)
end


-- May pass in nil for gIDs
-- May return nil if turret is not boosted / boostable
function maps_getTUnion(turret, gIDs)
  if not global.tun_to_tID[turret.unit_number] then
    makeTUnionFromTurret(turret, gIDs)
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

  global.tunions[tu.tuID] = nil
  global.tun_to_tID[turret.unit_number] = nil
end


function maps_boostTurret(base, boosted)
  local tu = global.tun_to_tID[base.unit_number]
  global.tun_to_tID[base.unit_number] = nil
  global.tun_to_tID[boosted.unit_number] = tu
  global.boosted_to_tuID[boosted.unit_number] = tu.tuID

  tu.turret = boosted
  tu.boosted = true
end


function maps_unboostTurret(base, boosted)
  local tu = global.tun_to_tID[boosted.unit_number]
  global.tun_to_tID[boosted.unit_number] = nil
  global.tun_to_tID[base.unit_number] = tu
  global.boosted_to_tuID[boosted.unit_number] = nil

  tu.turret = base
  tu.boosted = false
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
