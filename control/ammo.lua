----------------------------------------------------------------
  local d = require "sl-defines"
  local u = require "sl-util"

  -- forward declarations
  local AuditBoostedAmmo
  local GetBoostableAmmoType
  local GetEntityInventoriesList
  local GetSlotBoostedAmmoCount
  local GetTurretInventory
  local InitTables_Ammo
  local SwapAmmo
  local TryBoostingAmmo
  local UnBoostAmmo
----------------------------------------------------------------


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
local lookupAmmoToBoosted = {}


function InitTables_Ammo()
  global.ammoAudit = {}
end


-- TODO Maybe make this more robust, take in a slot number
function SwapAmmo(inventory, stack, new)
  local ammoCount = stack.count
  local roundCount = stack.ammo
  stack.clear()
  inventory.insert({name=new.name, count=ammoCount})

  -- Hopefully this won't be abused in turrets with multiple ammo slots
  if roundCount then
    inventory.find_item_stack(new.name).ammo = roundCount
  end

  return ammoCount
end


function GetSlotBoostedAmmoCount(invSlot)
  if not (invSlot and invSlot.valid) then
    return false -- Something just messed with this stack, wait until next tick to audit
  end

  if invSlot.valid_for_read then
    if u.EndsWith(invSlot.name, d.boostSuffix) then
      return invSlot.count
    end
  end
  -- else ammoCount = ammoCount + 0 (since the stack is empty when not valid for read)
end


function GetTurretInventory(turret)
  if     not turret.valid
      or not turret.get_inventory
      or not turret.get_inventory(defines.inventory.turret_ammo)
      or not turret.get_inventory(defines.inventory.turret_ammo).valid then
    return false
  end

  return turret.get_inventory(defines.inventory.turret_ammo)
end


function GetEntityInventoriesList(entity)
  if lookupInventories[entity.name] then
    return lookupInventories[entity.name]
  end

  if not entity.get_inventory then
    lookupInventories[entity.name] = false
    return lookupInventories[entity.name]
  end

  lookupInventories[entity.name] = {}
  for inv in pairs(ammoInventories) do
    if entity.get_inventory(inv) then
      table.insert(lookupInventories[entity.name], inv)
    end
  end

  if not next(lookupInventories[entity.name]) then
    lookupInventories[entity.name] = false
  end

  return lookupInventories[entity.name]
end


function GetBoostableAmmoType(ammoStack)
  if     not ammoStack.valid
      or not ammoStack.valid_for_read then
    return
  end

  if not ammoStack.name then
    return false
  end

  local name = ammoStack.name
  if lookupAmmoToBoosted[name] then
    return lookupAmmoToBoosted[name]
  end

  local prototype = game.item_prototypes[name]
  local boostName = prototype.name .. d.boostSuffix

  if game.item_prototypes[boostName] then
    lookupAmmoToBoosted[name] = boostName
  end
end


function TryBoostingAmmo(turret)
  local inv = turret.get_inventory(defines.inventory.turret_ammo)
  if not inv then
    return
  end

  local ammoCount = 0
  for index=1, #inv do
    local boostName = GetBoostableAmmoType(inv[index])
    if boostName then
      ammoCount = ammoCount + SwapAmmo(inv, inv[index], game.item_prototypes[boostName])
    end
  end

  if ammoCount == 0 then
    return
  end

  global.ammoAudit[turret.unit_number] = ammoCount
end


function UnBoostAmmo(entity)
  -- If this was actually a different type of boosted turret, 
  -- we can let it keep whatever ammo it has
  -- (We'll just hope nobody tries to take advantage of this for now)
  if  u.EndsWith(entity.name, d.boostSuffix) 
      and settings.global[d.overrideAmmoRange].value then
    return
  end

  if not entity.unit_number then
    return
  end

  global.ammoAudit[entity.unit_number] = nil

  local invList = GetEntityInventoriesList(entity)

  if not invList then
    return
  end

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


function AuditBoostedAmmo(turret)
  if global.ammoAudit[turret.unit_number] then
    local ammoCount = 0
    local inv = GetTurretInventory(turret)

    if not inv then
      return -- Inventory invalidated, try again later
    end

    auditAmmo = global.ammoAudit[turret.unit_number]
    currentAmmo = 0
    for index=1, #inv do
      slotAmmo = GetSlotBoostedAmmoCount(inv[index])
      if slotAmmo then
        currentAmmo = currentAmmo + slotAmmo
      end
    end

    if currentAmmo > 0 then
      global.ammoAudit[turret.unit_number] = currentAmmo
    else
      global.ammoAudit[turret.unit_number] = nil
    end

    if currentAmmo >= auditAmmo then
      return -- Audit passed
    end
    -- else Audit failed

    -- Find all nearby entities NOT named after this boosted turret
    -- so we can see if they robbed it of its ammo somehow and unboost it.
    -- We'll use a radius of 4 arbitrarily -- big enough to catch any long-handed
    -- inserters, short enough that we won't lag things out too bad (hopefully)
    -- TODO Since 4 is a lot further away than a player, do a seperate function to look up the player inventory
    --      (and exclude players from this function somehow?)
    -- TODO Maybe register all boosted ammo somehow, so we can find it later, even if it moves?
    --      Is registering item stacks a thing?
    local neighbors = turret.surface.find_entities_filtered{invert = true,
                                                            name=turret.name,
                                                            position=turret.position,
                                                            radius=4
                                                           }

    for _, n in pairs(neighbors) do
      UnBoostAmmo(n)
    end
  else
    TryBoostingAmmo(turret)
  end
end


----------------------------------------------------------------
  local public = {}
  public.AuditBoostedAmmo = AuditBoostedAmmo
  public.GetBoostableAmmoType = GetBoostableAmmoType
  public.GetEntityInventoriesList = GetEntityInventoriesList
  public.GetSlotBoostedAmmoCount = GetSlotBoostedAmmoCount
  public.GetTurretInventory = GetTurretInventory
  public.InitTables_Ammo = InitTables_Ammo
  public.SwapAmmo = SwapAmmo
  public.TryBoostingAmmo = TryBoostingAmmo
  public.UnBoostAmmo = UnBoostAmmo
  return public
----------------------------------------------------------------
