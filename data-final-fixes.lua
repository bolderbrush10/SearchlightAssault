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


local function GetBaseName(name)
  if not u.EndsWith(name, d.boostSuffix) then
    return nil -- wasn't boosted
  end

  return name:gsub(d.boostSuffix, "")
end


local function GetBoostAmmoName(ammo, table)
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

  if val and val < d.rangeBoostAmount then
  	actDelivery.max_range = d.rangeBoostAmount
  	return true
  end

  return false
end


local function ParseAmmoAction(ammoAction, rangeMod)
  if not ammoAction.action_delivery then
    return false
  end
  
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
  if not ammoType.action then
    return false
  end

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
		local boostedName = GetBoostAmmoName(ammo, currTable)
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

        if boostCopy.flags == nil then
          boostCopy.flags = {}
        end
        -- Just hides from some GUIs (logistics requests, etc)
        table.insert(boostCopy.flags, "hidden")

	      boostCopy.name = boostedName
  			data:extend{boostCopy}
  		end
		end
  end
end


local function InjectIntoEffects(tech, base, boosted)
  for index, e in pairs(tech.effects) do
    if     e.type      and e.type == "turret-attack" 
       and e.turret_id and e.turret_id == base then
        boostE = table.deepcopy(e)
        boostE.turret_id = boosted
        table.insert(tech.effects, index+1, boostE)
        data:extend{tech}
        return
     end
  end
end

local function InjectIntoTechnologies(base, boosted)
  local techs = data.raw["technology"]

  for _, t in pairs(techs) do
    if t.effects then
      InjectIntoEffects(t, base, boosted)
    end
  end
end


local function MakeTechBoost(turrets)
  for _, t in pairs(turrets) do
    local boosted = t.name
    local base = GetBaseName(boosted)
    InjectIntoTechnologies(base, boosted)
  end
end

MakeAmmoBoost(data.raw["ammo"])
MakeTechBoost(data.raw["ammo-turret"])
MakeTechBoost(data.raw["fluid-turret"])
MakeTechBoost(data.raw["electric-turret"])
