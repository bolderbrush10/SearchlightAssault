local d = require "sl-defines"
local r = require "sl-relation"
local u = require "sl-util"


local export = {}


-- boostInfo states
local UNBOOSTED     = 0
local BOOSTED       = 1
local BLOCKED       = 2
local NOT_BOOSTABLE = 3


------------------
-- Turret Union --
------------------
--[[
{
  tuID    = int (tuID),
  turret  = base / boosted,
  boosted = true / false,
  control = entity / nil,
}
]]--

export.InitTables_Turrets = function()

  global.tuID = 0

  -- Map: turret union ID -> TUnion
  global.tunions = {}

  -- Map: turret unit_number -> TUnion
  global.tun_to_tunion = {}

  -- Map: boosted turret unit_number -> TUnion
  global.boosted_to_tunion = {}

  -- Map: turret name -> true
  global.blockList = {}

  -- Map: turret name -> BOOSTED / UNBOOSTED / BLOCKED / NOT_BOOSTABLE
  global.boostInfo = {}

  -- Initialize blockList & boostInfo
  export.UpdateBlockList()
end


------------------------
--  Helper Functions  --
------------------------


local function newTUID()
  global.tuID = global.tuID + 1
  return global.tuID
end


-- May return nil if turret is not boostable / already has tunion
local function makeTUnionFromTurret(turret)
  if global.tun_to_tunion[turret.unit_number] then
    return nil
  end

  local bInfo = global.boostInfo[turret.name]

  if bInfo == NOT_BOOSTABLE then
    return nil
  end

  local tunion = {tuID = newTUID(),
                  turret = turret,
                  boosted = (bInfo == BOOSTED)}

  global.tunions[tunion.tuID] = tunion
  global.tun_to_tunion[turret.unit_number] = tunion

  return tunion
end


local function getTuID(turret)
  if not global.tun_to_tunion[turret.unit_number] then
    return makeTUnionFromTurret(turret).tuID
  end

  return global.tun_to_tunion[turret.unit_number].tuID
end


local function ReassignTurret(turret, tuID)
  local gtRelations = global.GestaltTunionRelations

  for gID, _ in pairs(r.getRelationRHS(gtRelations, tuID)) do
    local g = global.gestalts[gID]
    -- Check light.valid here because this could get called 
    -- while checking if the map editor failed to fire an event
    if g.light.valid then
      local gtarget = g.light.shooting_target
      if  gtarget 
          and gtarget.valid 
          and gtarget.unit_number ~= g.turtle.unit_number
          and u.IsPositionWithinTurretArc(gtarget.position, turret) then

        turret.shooting_target = gtarget
        return true

      end
    end
  end

  return false
end


local function SpawnControl(turret)
  local width = turret.bounding_box.right_bottom.x - turret.bounding_box.left_top.x
  local pos   = turret.bounding_box.right_bottom

  -- Slightly randomizing the position to add visual interest,
  -- staying near the bottom edge of the entity, varying around ~80% of its width.
  -- (math.random(x, y) doesn't return a float, so we'll add our product to math.random() which does)
  -- (math.random(x, y) crashes when given positions too close, so check variance before using)
  local xVar = math.abs((0) - (width - 0.2))
  local xRand = 0
  if xVar >= 1 then
    xRand = math.random((0),  (width - 0.2))
  end

  pos.x = pos.x - 0.2 - xRand
  pos.y = pos.y - 0.1 + math.random()/8

  local control = turret.surface.create_entity{name = d.searchlightControllerName,
                                               position = pos,
                                               force = turret.force,
                                               create_build_effect_smoke = true}

  -- Explosions clean themselves up after they're done playing, so that's nice
  turret.surface.create_entity{name = "rock-damaged-explosion", position = pos}
  turret.surface.create_entity{name = "rock-damaged-explosion", position = pos}

  control.destructible = false

  return control
end


----------------------
--  On Tick Events  --
----------------------


-- Wouldn't need this function if there was an event for when entities run out of power
export.CheckElectricNeeds = function()
  for _, t in pairs(global.boosted_to_tunion) do
    local turret = t.turret
    -- Inactive units don't die, so we need to fix that here
    turret.active = turret.health == 0 or t.control.energy > 0
    
    -- Some mods put a limited range on ammo, so check for that here
    if  not turret.shooting_target 
        or not u.IsPositionWithinTurretArc(turret.shooting_target.position, turret) then
      export.UnBoost(t)
    end
  end
end


------------------------
--  Aperiodic Events  --
------------------------


-- Turret placed
function export.TurretAdded(turret)

  if not global.boostInfo[turret.name]
      or global.boostInfo[turret.name] == NOT_BOOSTABLE then
    return
  end

  local friends = turret.surface.find_entities_filtered{area=u.GetBoostableAreaFromPosition(turret.position),
                                                        name={d.searchlightBaseName, d.searchlightAlarmName},
                                                        force=turret.force}

  for _, f in pairs(friends) do
    export.CreateRelationship(global.unum_to_g[f.unit_number], turret)
  end
end


-- Turret removed
function export.TurretRemoved(turret, tu)
  if turret then
    if not global.tun_to_tunion[turret.unit_number] then
      return -- We weren't tracking this turret, so nothing to do
    end

    local tu = global.tun_to_tunion[turret.unit_number]
    r.removeRelationRHS(global.GestaltTunionRelations, tu.tuID)

    if tu.control then
      tu.control.destroy()
      tu.control = nil
    end

    global.tun_to_tunion[turret.unit_number] = nil
    global.boosted_to_tunion[turret.unit_number] = nil
    global.tunions[tu.tuID] = nil
  else
    -- Some workarounds are necessary here
    -- to deal with the map editor not firing events
    r.removeRelationRHS(global.GestaltTunionRelations, tu.tuID)

    if tu.control then
      tu.control.destroy()
      tu.control = nil
    end

    for lhs, rhs in pairs(global.tun_to_tunion) do
      if rhs.tuID == tu.tuID then
        global.tun_to_tunion[lhs] = nil
      end
    end

    for lhs, rhs in pairs(global.boosted_to_tunion) do
      if rhs.tuID == tu.tuID then
        global.boosted_to_tunion[lhs] = nil
      end
    end

    for lhs, rhs in pairs(global.tunions) do
      if rhs.tuID == tu.tuID then
        global.tunions[lhs] = nil
      end
    end
  end
end


-- Gestalt removed
function export.GestaltRemoved(tuID)
  -- Check if we still have a relationship with anything before removing this tunion
  if next(r.getRelationRHS(global.GestaltTunionRelations, tuID)) then
    return
  end

  local tu = global.tunions[tuID]

  if tu.control then
    tu.control.destroy()
    tu.control = nil
  end

  global.tun_to_tunion[tu.turret.unit_number] = nil
  global.boosted_to_tunion[tu.turret.unit_number] = nil
  global.tunions[tu.tuID] = nil
end


-- Called when a searchlight or turret is created
export.CreateRelationship = function(g, t)
  if      global.boostInfo[t.name] ~= NOT_BOOSTABLE
      and u.RectangeDistSquared(u.UnpackRectangles(t.selection_box, g.light.selection_box)) <= 1 then

    local tuID = getTuID(t)
    r.setRelation(global.GestaltTunionRelations, g.gID, tuID)

  end
end


-- Unboost any turrets shooting at unsactioned foes.
-- We have three conditions upon which we need to check for unboosting:
-- Foe left range (checked in gestalt.CheckGestaltFoes),
-- Foe died (checked in gestalt.FoeDied),
-- Searchlight deconstructed / died while targeting a Foe (checked in gestalt.SearchlightRemoved)
export.FoeGestaltRelationRemoved = function(g, tIDlist)

  if tIDlist == nil then
    tIDlist = r.getRelationLHS(global.GestaltTunionRelations, g.gID)
  end

  for tuID, _ in pairs(tIDlist) do
    local tu = global.tunions[tuID]
    if not ReassignTurret(tu.turret, tuID) then
      export.UnBoost(tu)
    end
  end

end


------------------------
-- Un/Boost Functions --
------------------------


export.Boost = function(tunion, foe)
  if  tunion.boosted
     or global.boostInfo[tunion.turret.name] ~= UNBOOSTED
     or global.boostInfo[tunion.turret.name .. d.boostSuffix] == nil
     or global.boostInfo[tunion.turret.name .. d.boostSuffix] ~= BOOSTED then
    return
  end

  local turret = tunion.turret

  if not (turret.valid and u.IsPositionWithinTurretArc(foe.position, turret)) then
    return
  end

  local newT = turret.surface.create_entity{name = turret.name .. d.boostSuffix,
                                            position = turret.position,
                                            force = turret.force,
                                            direction = turret.direction,
                                            fast_replace = false,
                                            create_build_effect_smoke = false}

  u.CopyTurret(turret, newT)
  tunion.boosted = true
  tunion.control = SpawnControl(newT)
  tunion.turret  = newT
  global.tun_to_tunion[newT.unit_number] = tunion
  global.tun_to_tunion[turret.unit_number] = nil
  global.boosted_to_tunion[newT.unit_number] = tunion
  turret.destroy()
  -- Don't raise script_raised_destroy since we're trying to do a swap-in-place,
  -- not actually "destroy" the entity (We'll put the original back soon
  -- (albeit with a new unit_number...))
  -- On the other hand, what if the other mod has its own hidden entities
  -- mapped to what we're destroying? We're messing up their unit_number too...
  -- Would we be better off just setting active=false on the original entity
  -- and somehow hiding it / synchronizing its movement & firing animations?

  newT.shooting_target = foe

 return newT
end


export.UnBoost = function(tunion)
  if not tunion.boosted then
    return
  end

  local turret = tunion.turret

  if not turret.valid then
    log("SearchlightAssault: Unable to unboost a turret, something else has invalidated it")
    return
  end

  local newT = turret.surface.create_entity{name = turret.name:gsub(d.boostSuffix, ""),
                                            position = turret.position,
                                            force = turret.force,
                                            direction = turret.direction,
                                            fast_replace = false,
                                            create_build_effect_smoke = false}

  u.CopyTurret(turret, newT)
  tunion.boosted = false

  local c = tunion.control
  newT.surface.create_entity{name = "spark-explosion", position = c.position}
  newT.surface.create_entity{name = "spark-explosion", position = c.position}
  c.destroy()

  tunion.control = nil
  tunion.turret  = newT
  global.tun_to_tunion[newT.unit_number] = tunion
  global.tun_to_tunion[turret.unit_number] = nil
  global.boosted_to_tunion[turret.unit_number] = nil
  turret.destroy()
  -- As with Boost(), don't raise script_raised_destroy

  return newT
end


------------------------
--    Mod Settings    --
------------------------


local function concatKeys(table)
  local result = ""

  -- factorio API guarantees deterministic iteration
  for key, value in pairs(table) do
    result = result .. key
  end

  return result
end


-- Breaking out a seperate function like this allows us to easily
-- note changes to the block list and output them to game.print()
local function UpdateBoostInfo(blockList)
  local protos = game.get_filtered_entity_prototypes{{filter = "turret"}}

  for _, turret in pairs(protos) do
    if blockList[turret.name] then
      global.boostInfo[turret.name] = BLOCKED

      if not global.blockList[turret.name] then
        game.print("Searchlight Assault: Now ignoring " .. turret.name)
      end
    elseif game.entity_prototypes[turret.name .. d.boostSuffix] then
      global.boostInfo[turret.name] = UNBOOSTED
    elseif u.EndsWith(turret.name, d.boostSuffix) then
      global.boostInfo[turret.name] = BOOSTED
    else
      global.boostInfo[turret.name] = NOT_BOOSTABLE
    end
  end
end


export.UpdateBlockList = function()
  local settingStr = settings.global[d.ignoreEntriesList].value
  local newBlockList = {}

  -- Tokenize semi-colon delimited strings
  for token in string.gmatch(settingStr, "[^;]+") do
    local trim = token:gsub("%s+", "")

    if game.entity_prototypes[trim] then
      newBlockList[trim] = true
    else
      local result = "Unable to add misspelled or nonexistent turret " ..
                     "name to Searchlight Assault ignore list: " .. token

      game.print(result)
    end
  end

  -- Quick & dirty way to compare table equality for our use case
  if next(global.blockList) and concatKeys(global.blockList) == concatKeys(newBlockList) then
    game.print("Searchlight Assault: No turrets affected by settings change")

    return
  end

  UpdateBoostInfo(newBlockList)

  global.blockList = newBlockList
end


export.UnboostBlockedTurrets = function()
  for tuID, tu in pairs(global.tunions) do
    if tu.boosted and global.blockList[tu.turret.name:gsub(d.boostSuffix, "")] then
      export.UnBoost(tu, true)
    end
  end
end


return export
