require "searchlight-defines"

local beaconEntity = table.deepcopy(data.raw["beacon"])
local spotlightAnimation = beaconEntity.animation

local spotlightBeam = table.deepcopy(data.raw["beam"]["laser-beam"])

spotlightBeam.name = "spotlight-beam"
spotlightBeam.head = spotlightAnimation


-- TODOOOOOOOOOOOOOO
-- use the 'target_type' : position parameter and work from that.
-- (How will rotating the turret work? Will we still need a hidden entity for the turret to target?)

--
-- turretEntity; the primary entity which uses a lamp like a turret
--
-- Might want to figure out how to use the 'alert_when_attacking' characteristic such that we alert when real foes are present, and not imaginary ones
-- also look into:
--  allow_turning_when_starting_attack
--  attack_from_start_frame
local turretEntity = table.deepcopy(data.raw["electric-turret"]["laser-turret"])
turretEntity.name = "searchlight"
turretEntity.minable.result = "searchlight"
turretEntity.rotation_speed = 50 -- arbitrary high number btween 5 and 500 to be 'instant'

-- Energy priority: Should be below laser turrets, same as most machines, above lamps & accumulators
turretEntity.energy_source.usage_priority = "secondary-input"

-- TODO energy cost
-- TODO make use of new feature from patch notes: - Added optional lamp prototype property "always_on".

-- Basically we just want the turret to point itself at things, not have any real effect. We're going to just use draw_light calls in control.lua for the actual effect.
-- TODO maybe do a subtle shaft of light effect as a beam 'attack'?
-- turretEntity.attack_parameters = {
--     type = "beam",
--     cooldown = 100,
--     range = searchlightOuterRange,
--     use_shooter_direction = true,
--     ammo_type =
--     {
--         category = "laser-turret",
--         target_type = "position",
--         action =
--         {
--             type = "area",
--             radius = 2.0,
--             action_delivery =
--             {
--                 type = "beam",
--                 beam = "spotlight-beam",
--                 duration = 10,
--                 --starting_speed = 0.3
--             }
--         }
--     }
-- }

--
-- spotLightSprite; A simple sprite with a directional light effect
--
local spotLightSprite = {
    type = "sprite",
    name = "spotLightSprite",
    filename = "__Searchlights__/graphics/spotlight.png",
    priority = "extra-high",
    width = 200, 
    height = 200
}

--
-- spotLightHiddenEnt; A simple hidden entity for the spotlight to target while no enemies are present
--
local spotLightHiddenEnt = table.deepcopy(data.raw["unit"]["small-biter"])
spotLightHiddenEnt.name = "SpotlightShine"
spotLightHiddenEnt.collision_box = {{0, 0}, {0, 0}} -- enable noclip
spotLightHiddenEnt.collision_mask = {"not-colliding-with-itself"}
spotLightHiddenEnt.selectable_in_game = false
spotLightHiddenEnt.selection_box = {{-0.0, -0.0}, {0.0, 0.0}}


--
-- Add new definitions to game data
--
data:extend{spotlightAnimation, spotlightBeam, turretEntity, spotLightSprite, spotLightHiddenEnt}
-- data:extend{spotlightBeam, turretEntity, spotLightSprite, spotLightHiddenEnt}
-- data:extend{turretEntity, spotLightSprite, spotLightHiddenEnt}
-- data:extend{spotlightAnimation, spotlightBeam}


--[[

blank = {
     filename = "__Searchlights__/graphics/transparent_pixel.png",
     priority = "extra-high",
     width = 1,
     height = 1
}

graphicOn = {
    filename = "__Searchlights__/graphics/terribleLight.png",
    priority = "extra-high",
    width = 95,
    height = 82
}

graphicOff = {
    filename = "__Searchlights__/graphics/terrible-off.png",
    priority = "extra-high",
    width = 95,
    height = 82
}

light = {
    color = {
      b = 1,
      g = 1,
      r = 1
    },
    intensity = 0.8,
    size = 12
}

spotlight = {
	type = "oriented",
	picture =
	{
		filename = "__Searchlights__/graphics/spotlight.png",
		priority = "extra-high",
		flags = { "light" },
		scale = 2,
		width = 200,
		height = 200
	},
	minimum_darkness = 0.8,
	shift = {0, 0},
	size = 1,
	intensity = 0.8,
	color = {r = 1.0, g = 1.0, b = 1.0}
}

--
-- lightEntity; a hidden entity to make the spotlight effect on ground
--
--local lightEntity = table.deepcopy(data.raw["lamp"]["small-lamp"])
--
--table.deepcopy(data.raw["lamp"]["small-lamp"])
--
--lightEntity.name = "searchlight-hidden"
--lightEntity.flags = {"placeable-off-grid", "not-on-map"}
--lightEntity.selectable_in_game = false
--lightEntity.collision_box = {{-0.0, -0.0}, {0.0, 0.0}}
--lightEntity.selection_box = {{-0.0, -0.0}, {0.0, 0.0}}
--lightEntity.collision_mask = {"not-colliding-with-itself"}
--
---- We dont' intend to leave a corpse at all, but if the worst happens...
--lightEntity.corpse = "small-scorchmark"
--lightEntity.energy_source = {
--  type = "void",
--  usage_priority = "lamp"
--}
--lightEntity.light = spotlight
--lightEntity.light_when_colored = spotlight
--lightEntity.picture_off = blank
--lightEntity.picture_on = blank


--]]
