-- This file's job is to grab any turrets it can find and create a boosted-range version.
-- If some other mod put their turret into this data stage (or later), and we don't grab it, then too bad.

local d = require "sl-defines"

require "util" -- for table.deepcopy

-- Be sure to declare functions and vars as 'local' in prototype / data*.lua files,
-- because other mods may have inadvertent access to functions at this step.


local function GetBoostName(entity, table)
  if not string.match(entity.name, d.boostSuffix)
     and not string.match(entity.name, "searchlight") then

    local boostedName =  entity.name .. d.boostSuffix

    if table[boostedName] == nil then
      return boostedName
    end

  end

  return nil
end


local function LookupPlaceableItem(name)
  for _, i in pairs(data.raw["item"]) do
    if i.place_result == name then
      return i.name
    end
  end

  return nil
end


-- Make boosted-range versions of non search light turrets
-- (Factorio might run this entity-script multiple times, so be sure to avoid making dupes)
local function MakeBoost(currTable, newRange)
  for index, turret in pairs(currTable) do
    local boostedName = GetBoostName(turret, currTable)
    if boostedName then

      local boostSuccess = false

      local boostCopy = table.deepcopy(currTable[turret.name])

      -- Inspired by Mooncat. Thanks, Mooncat.
      boostCopy.localised_name = {"entity-name." .. boostCopy.name}
      if {"entity-description." .. boostCopy.name} then
        boostCopy.localised_description = {"entity-description." .. boostCopy.name}
      end

      boostCopy.name = boostedName

      if boostCopy.attack_parameters
         and boostCopy.attack_parameters.range < newRange then
        boostCopy.attack_parameters.range = newRange
      end

      if boostCopy.attack_parameters
        and boostCopy.attack_parameters.ammo_type
        and boostCopy.attack_parameters.ammo_type.action
        and boostCopy.attack_parameters.ammo_type.action.action_delivery
        and boostCopy.attack_parameters.ammo_type.action.action_delivery.max_length then
          boostCopy.attack_parameters.ammo_type.action.action_delivery.max_length = newRange
      end

      if boostCopy.attack_parameters
        and boostCopy.attack_parameters.cooldown then
        boostCopy.attack_parameters.cooldown = boostCopy.attack_parameters.cooldown * d.attackCooldownPenalty
        -- If we can't increase a turret's cooldown, we probably don't want to give it massive range
        boostSuccess = true
      end


      -- "placeable_by" is normally only used by curved rails in the base game,
      -- but we can take advantage of it here to make the smart-pipette ("Q") tool
      -- select the base version of this turret, and also make blueprints think
      -- they're using the base version.
      -- (We'll detect when blueprints are actually created / updated and
      --  silently swap out the range-boosted entity for the base version there)
      if not boostCopy.placeable_by then

        if data.raw["item"][turret.name] then
          boostCopy.placeable_by = {item = turret.name, count = 1}
        else
          local placable = LookupPlaceableItem(turret.name)
          if placable then
            boostCopy.placeable_by = {item = placable, count = 1}
          else
            -- If there's no item that creates this turret,
            -- then don't even try boosting it.
            -- Otherwise we'll probably crash at some point
            -- if players mess around with blueprints or somthing.
            boostSuccess = false
          end
        end

      end

      if boostSuccess then
        data:extend{boostCopy}
      end

    end
  end
end


MakeBoost(data.raw["ammo-turret"],     d.rangeBoostAmount)
MakeBoost(data.raw["fluid-turret"],    d.rangeBoostAmount)
MakeBoost(data.raw["electric-turret"], d.rangeBoostAmount)
