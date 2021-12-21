-- Be sure to declare functions and vars as 'local' in prototype / data*.lua files,
-- because other mods may have inadvertent access to functions & variables at this step.

require("prototypes.sl-entities")
require("prototypes.sl-techItemRecipe")

local d = require("sl-defines")
local u = require("sl-util")


-- Since some other mods mess with the health of entities 
-- in a later data stage than they probably should;
-- try to make sure our copies of their turrets match their health
local function MatchHealth(currTable)
  for index, turret in pairs(currTable) do
    if u.EndsWith(turret.name, d.boostSuffix) then
	  local originalT = turret.name:sub(1, #turret.name - #d.boostSuffix)

	  turret.max_health = currTable[originalT].max_health
	end
  end
end


MatchHealth(data.raw["ammo-turret"])
MatchHealth(data.raw["fluid-turret"])
MatchHealth(data.raw["electric-turret"])


local function GetBoostName(ammo, table)
  if not string.match(ammo.name, d.boostSuffix) then

    local boostedName =  ammo.name .. d.boostSuffix

    if table[boostedName] == nil then
      return boostedName
    end

  end

  return nil
end


local function ParseActDelivery(actDelivery, rangeMod)
  local val = actDelivery.max_range
  if val and rangeMod then
    val = val * rangeMod
  end

  if val and val < d.searchlightRange then
  	actDelivery.max_range = d.searchlightRange
  	return true
  end

  return false
end


local function ParseAmmoAction(ammoAction, rangeMod)
	local updated = false

	-- action_delivery can either be a table of ammo_types,
	-- or just the action_delivery entry directly...
	if ammoAction.action_delivery.type then
		updated = ParseActDelivery(ammoAction.action_delivery, rangeMod)
	else
    for _, del in pairs(ammoAction.action_delivery) do	    
			updated = updated or ParseActDelivery(del, rangeMod)
    end
  end

  return updated
end


local function ParseAmmoType(ammoType)
	local rangeMod = ammoType.range_modifier	

	-- No point checking ammoType.source_type,
	-- wiki basically says that any type can go into any entity

	local updated = false

  -- action can either be a table of ammo_types,
  -- or just the action entry directly...
  if ammoType.action.type then
  	updated = ParseAmmoAction(ammoType.action, rangeMod)
	else
	  for _, a in pairs(ammoType.action) do
  		updated = updated or ParseAmmoAction(a, rangeMod)
	  end
	end

  return updated
end


-- We'll make some prototype copies of various ammos in case the player wants
-- to have boosted turrets ignore the range limits on ammo
-- Other mods have a habit of changing stuff from the base game in weird places,
-- so we have to do this here instead of in data-updates.lua
local function MakeAmmoBoost(currTable)
	for index, ammo in pairs(currTable) do
		local boostedName = GetBoostName(ammo, currTable)
		if boostedName then
			local boostCopy = table.deepcopy(currTable[ammo.name])
  		local range_modifier = boostCopy.range_modifier
  		local boostNeeded = false

  		-- ammo_type can either be a table of ammo_types,
  		-- or just the ammo_type entry directly...
  		if boostCopy.ammo_type.category then
  			boostNeeded = ParseAmmoType(boostCopy.ammo_type)
  		else
  			for _, ammoType in pairs(boostCopy.ammo_type) do
					boostNeeded = boostNeeded or ParseAmmoType(ammoType)
  			end
  		end

  		if boostNeeded then
	      boostCopy.localised_name = {"item-name." .. boostCopy.name}
	      if {"item-description." .. boostCopy.name} then
	        boostCopy.localised_description = {"item-description." .. boostCopy.name}
	      end

	      boostCopy.name = boostedName
  			data:extend{boostCopy}
  		end
		end
  end
end

MakeAmmoBoost(data.raw["ammo"])
