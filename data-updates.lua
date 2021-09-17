-- This file's job is to grab any turrets it can find and create a boosted-range version.
-- If some other mod put their turret into this data stage (or later), and we don't grab it, then too bad.

require("sl-defines")

-- Be sure to declare functions and vars as 'local' in prototype / data*.lua files,
-- because other mods may have inadvertent access to functions at this step.


-- TODO make use of this.. Would be good to show that turrets are being "overcharged"
-- If there was a way to sneak this into the firing animations,
-- or injected as a trigger to be created in the attack parameters, that'd be rad
local BoostSmoke =
{
  name = "range-boost-smoke",
  type = "trivial-smoke",
  animation = data.raw["trivial-smoke"]["smoke-building"].animation,
  duration = 255,
  affected_by_wind = true,
  show_when_smoke_off = true,
  cyclic = true,
}

data:extend{BoostSmoke}


local function GetBoostName(entity, table)
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
local function MakeBoost(currTable, newRange)
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

      if boostCopy.attack_parameters
        and boostCopy.attack_parameters.cooldown then
        boostCopy.attack_parameters.cooldown = boostCopy.attack_parameters.cooldown * 50
      end

      data:extend{boostCopy}

    end
  end
end

local currTable
currTable = data.raw["electric-turret"]
MakeBoost(currTable, rangeBoostAmount)

currTable = data.raw["ammo-turret"]
MakeBoost(currTable, rangeBoostAmount)

currTable = data.raw["fluid-turret"]
MakeBoost(currTable, rangeBoostAmount)
