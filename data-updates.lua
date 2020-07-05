-- This file's job is to grab any turrets it can find and create a boosted-range version.
-- If some other mod put their turret into this data stage (or later), and we don't grab it, then too bad.

require("searchlight-defines")

function GetBoostName(entity, table)
  if not string.match(entity.name, boostSuffix)
     and not string.match(entity.name, "searchlight") then

    local boostedName =  entity.name .. boostSuffix

    if table[boostedName] == nil then
      return boostedName
    end

  end

  return nil
end


-- Make boosted-range versions of non search light turrets
-- (Factorio might run this entity-script multiple times, so be sure to avoid making dupes)
function MakeBoost(currTable, newRange)
  for index, turret in pairs(currTable) do
    local boostedName = GetBoostName(turret, currTable)
    if boostedName then

      local boostCopy = table.deepcopy(currTable[turret.name])

      -- Inspired by Mooncat. Thanks, Mooncat.
      boostCopy.localised_name = {"entity-name." .. boostCopy.name}
      if {"entity-description." .. boostCopy.name} then
        boostCopy.localised_description = {"entity-description." .. boostCopy.name}
      end

      boostCopy.name = boostedName
      boostCopy.flags = {"hidden"}
      boostCopy.create_ghost_on_death = false

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

      data:extend{boostCopy}

    end
  end
end


currTable = data.raw["electric-turret"]
MakeBoost(currTable, elecBoost)

currTable = data.raw["ammo-turret"]
MakeBoost(currTable, ammoBoost)

currTable = data.raw["fluid-turret"]
MakeBoost(currTable, fluidBoost)
