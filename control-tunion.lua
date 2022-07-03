local d = require "sl-defines"
local r = require "sl-relation"
local u = require "sl-util"


local export = {}


-- boostInfo states (Shared with control-blocklist)
local UNBOOSTED     = 0
local BOOSTED       = 1
local BLOCKED       = 2
local NOT_BOOSTABLE = 3

export.bInfo = {}
export.bInfo.UNBOOSTED     = UNBOOSTED
export.bInfo.BOOSTED       = BOOSTED
export.bInfo.BLOCKED       = BLOCKED
export.bInfo.NOT_BOOSTABLE = NOT_BOOSTABLE


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

  -- Map: tuID -> TUnion
  global.boosted_to_tunion = {}

  -- Map: turret name -> BOOSTED / UNBOOSTED / BLOCKED / NOT_BOOSTABLE
  global.boostInfo = {}
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
  local checkAmmoRange = not settings.global[d.overrideAmmoRange].value

  for gID, _ in pairs(r.getRelationRHS(gtRelations, tuID)) do
    local g = global.gestalts[gID]
    -- Check light.valid here because this could get called 
    -- while checking if the map editor failed to fire an event
    if g.light.valid then
      local gtarget = g.light.shooting_target
      if  gtarget 
          and gtarget.valid 
          and gtarget.unit_number ~= g.turtle.unit_number
          and u.IsPositionWithinTurretArc(gtarget.position, turret, checkAmmoRange) then

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


local function SwapAmmo(inventory, stack, new)
  local ammoCount = stack.count
  local roundCount = stack.ammo
  stack.clear()
  inventory.insert({name=new.name, count=ammoCount})

  -- Hopefully this won't be abused in turrets with multiple ammo slots
  if roundCount then
    inventory.find_item_stack(new.name).ammo = roundCount
  end
end


-- We'll try to skip some of the more questionable inventories
-- for ammo to be in (eg, fuel, lab_input)
local ammoInventories = {
  defines.inventory.chest,
  defines.inventory.character_main,
  defines.inventory.character_ammo,
  defines.inventory.character_trash,
  defines.inventory.god_main,
  defines.inventory.robot_cargo,
  defines.inventory.item_main,
  defines.inventory.car_trunk,
  defines.inventory.car_ammo,
  defines.inventory.cargo_wagon,
  defines.inventory.turret_ammo,
  defines.inventory.character_corpse,
  defines.inventory.artillery_turret_ammo,
  defines.inventory.artillery_wagon_ammo,
  defines.inventory.spider_trunk,
  defines.inventory.spider_ammo,
  defines.inventory.spider_trash,
}


local lookupInventories = {}


-- memoize inventory lists since we'll probably be doing this a lot
local function GetAmmoInv(entity)
  local entityName = entity.name
  local invList = lookupInventories[entityName]

  if not invList then
    lookupInventories[entityName] = {}
    for _, invName in pairs(ammoInventories) do
      if entity.get_inventory(invName) then
        table.insert(lookupInventories[entityName], invName)
      end
    end

    invList = lookupInventories[entityName]
  end

  return invList
end


local function UnBoostAmmo(entity)
  -- If this was actually a different type of boosted turret, 
  -- we can let it keep whatever ammo it has
  -- (We'll just hope nobody tries to take advantage of this for now)
  if  u.EndsWith(entity.name, d.boostSuffix) 
      and settings.global[d.overrideAmmoRange].value then
    return
  end

  local invList = GetAmmoInv(entity)

  for _, invName in pairs(invList) do
    local inv = entity.get_inventory(invName)
    for index=1, #inv do
      if inv[index] and inv[index].valid and inv[index].valid_for_read then
        local prototype = game.item_prototypes[inv[index].name]
        if u.EndsWith(prototype.name, d.boostSuffix) then
          local baseName = prototype.name:gsub(d.boostSuffix, "")
          if game.item_prototypes[baseName] then
            SwapAmmo(inv, inv[index], game.item_prototypes[baseName])
          end
        end
      end
    end
  end
end


-- Every tick, we'll make sure ammo within this turret is boosted,
-- and check the nearby area to make sure no boosted ammo has leaked
-- (Sadly, it doesn't look like there's a way to 'lock' an inventory)
local function BoostAmmo(turret)
  if not turret.get_inventory 
    or not turret.get_inventory(defines.inventory.turret_ammo) then    
    return
  end

  local inv = turret.get_inventory(defines.inventory.turret_ammo)
  for index=1, #inv do
    if inv[index] and inv[index].valid and inv[index].valid_for_read then
      local prototype = game.item_prototypes[inv[index].name]
      if not u.EndsWith(prototype.name, d.boostSuffix) then
        local boostName = prototype.name .. d.boostSuffix
        if game.item_prototypes[boostName] then
          SwapAmmo(inv, inv[index], game.item_prototypes[boostName])
        end
      end
    end
  end

  -- Find all nearby entities NOT named after this boosted turret
  -- so we can see if they robbed it of its ammo somehow and unboost it.
  -- We'll use a radius of 4 arbitrarily -- big enough to catch any long-handed
  -- inserters, short enough that we won't lag things out too bad (hopefully)
  local neighbors = turret.surface.find_entities_filtered{invert = true,
                                                          name=turret.name,
                                                          position=turret.position,
                                                          radius=4
                                                         }

  for _, n in pairs(neighbors) do
    UnBoostAmmo(n)
  end
end


local function AmplifyRange(tunion, foe)
  if  tunion.boosted
     or global.boostInfo[tunion.turret.name] ~= UNBOOSTED
     or global.boostInfo[tunion.turret.name .. d.boostSuffix] == nil
     or global.boostInfo[tunion.turret.name .. d.boostSuffix] ~= BOOSTED then

    return

  end

  local checkAmmoRange = not settings.global[d.overrideAmmoRange].value
  local turret = tunion.turret

  if not (turret.valid and u.IsPositionWithinTurretArc(foe.position, turret, checkAmmoRange)) then
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
  tunion.turret  = newT
  global.tun_to_tunion[newT.unit_number] = tunion
  global.tun_to_tunion[turret.unit_number] = nil
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


local function DeamplifyRange(tunion)
  local turret = tunion.turret

  if not turret.valid or not tunion.boosted then
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

  tunion.turret  = newT
  global.tun_to_tunion[newT.unit_number] = tunion
  global.tun_to_tunion[turret.unit_number] = nil
  turret.destroy()
  -- As with AmplifyRange(), don't raise script_raised_destroy

  UnBoostAmmo(newT)

  return newT
end


----------------------
--  On Tick Events  --
----------------------


-- Wouldn't need this function if there was an event for when entities run out of power
export.CheckAmmoElectricNeeds = function()
  local checkAmmoRange = not settings.global[d.overrideAmmoRange].value

  for tuID, t in pairs(global.boosted_to_tunion) do
    local turret = t.turret
    local foe = t.foe
    
    -- Some mods put a limited range on ammo, so check for that here
    if turret.shooting_target and not u.IsPositionWithinTurretArc(turret.shooting_target.position, turret, checkAmmoRange) then
      export.UnBoost(t)
    elseif not foe or not foe.valid then
      if not ReassignTurret(turret, tuID) then
        export.UnBoost(t)
      end
    elseif t.control.energy > 5000 then
      AmplifyRange(t, foe) -- will invalidate t
      if not checkAmmoRange then
        BoostAmmo(t.turret)
      end
    elseif t.control.energy < 100 then
      DeamplifyRange(t)
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
    global.boosted_to_tunion[tu.tuID] = nil
    global.tunions[tu.tuID] = nil
  else
    -- Some workarounds are necessary here
    -- to deal with the map editor not firing events
    r.removeRelationRHS(global.GestaltTunionRelations, tu.tuID)

    if tu.control then
      tu.control.destroy()
      tu.control = nil
    end

    -- TODO I don't remember writing these 3 loops of garbage
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
-- (Unboosting would happen in FoeGestaltRelationRemoved)
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
  global.boosted_to_tunion[tu.tuID] = nil
  global.tunions[tu.tuID] = nil
end


-- Called when a searchlight or turret is created
export.CreateRelationship = function(g, t)
  if global.boostInfo[t.name] == NOT_BOOSTABLE then
    return

  -- Fine-tune checking that a turret is in a good range to be neighbors
  elseif u.RectangeDistSquared(u.UnpackRectangles(t.selection_box, g.light.selection_box))
   < u.square(d.searchlightMaxNeighborDistance) then

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


-- Called when the override max ammo range mod setting changes to false,
-- which means we need to find and swap back any taboo'd ammo
export.RespectMaxAmmoRange = function()
  for _, tu in pairs(global.boosted_to_tunion) do
    local turret = tu.turret
    local entities = turret.surface.find_entities_filtered{position=turret.position,
                                                           radius=4
                                                          }

    for _, e in pairs(entities) do
      UnBoostAmmo(e)
    end

    -- We'll reboost this turret if its foe was still actually in range
    export.UnBoost(tu)
  end
end


------------------------
-- Un/Boost Functions --
------------------------


-- After being added to the map of boostables,
-- we'll check if it's time to actually swap to
-- the range-boosted turret in CheckAmmoElectricNeeds()
-- via onTick()
export.Boost = function(tunion, foe)
  if global.boosted_to_tunion[tunion.tuID] or global.boostInfo[tunion.turret.name] == BLOCKED then
    return
  end

  global.boosted_to_tunion[tunion.tuID] = tunion
  tunion.control = SpawnControl(tunion.turret)
  tunion.foe = foe
end


export.UnBoost = function(tunion)
  if not global.boosted_to_tunion[tunion.tuID] then
    return
  end

  global.boosted_to_tunion[tunion.tuID] = nil
  local c = tunion.control
  if c then -- In some cases, other mods apparently can destroy our control entity...
    c.surface.create_entity{name = "spark-explosion", position = c.position}
    c.surface.create_entity{name = "spark-explosion", position = c.position}
    c.destroy()
  end

  tunion.control = nil
  tunion.foe = nil

  if tunion.boosted then
    DeamplifyRange(tunion)
  end
end


return export
