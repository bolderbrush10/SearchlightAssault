require "searchlight-defines"

local Layer_transparent_pixel =
{
  filename = "__Searchlights__/graphics/transparent_pixel.png",
  width = 1,
  height = 1,
}

local Layer_transparent_animation =
{
  filename = "__Searchlights__/graphics/transparent_pixels.png",
  width = 8,
  height = 8,
  direction_count = 1,
}

local Light_Layer_SpotLight_NormLight =
{
  filename = "__Searchlights__/graphics/spotlight-r.png",
  width = 200,
  height = 200,
  scale = 1.5,
  flags = { "light" },
  shift = {0.3, 0},
}

local redTint = {r=1.0, g=0.1, b=0.1, a=1}

local Light_Layer_SpotLight_NormLight_Less = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_NormLight_Less.filename = "__Searchlights__/graphics/spotlight-r-less.png"

local Light_Layer_SpotLight_RimLight = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_RimLight.filename = "__Searchlights__/graphics/spotlight-r-rim.png"

-- TODO make this a 'heat shimmer' animation, so it looks awesome during the day
local Light_Layer_SpotLight_DimLight = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_DimLight.filename = "__Searchlights__/graphics/spotlight-r-less-dim.png"

local Light_Layer_SpotLight_NormLight_Red = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_NormLight_Red.tint = redTint

local Light_Layer_SpotLight_RimLight_Red = table.deepcopy(Light_Layer_SpotLight_RimLight)
Light_Layer_SpotLight_RimLight_Red.tint = redTint

local Light_Layer_SpotLight_DimLight_Red = table.deepcopy(Light_Layer_SpotLight_DimLight)
Light_Layer_SpotLight_DimLight_Red.tint = redTint


local SpotlightBeamPassive =
{
  type = "beam",
  name = "spotlight-beam-passive",
  flags = {"not-on-map"},
  width = 0.5,
  damage_interval = 1,
  random_end_animation_rotation = false,
  ground_light_animations =
  {
    ending =
    {
      layers =
      {
        Light_Layer_SpotLight_NormLight,
      }
    }
  },
  ending =
  {
    layers =
    {
      Light_Layer_SpotLight_DimLight,
    }
  },
  head = Layer_transparent_pixel,
  tail = Layer_transparent_pixel,
  body = Layer_transparent_pixel,
}


local SpotlightBeamAlarm = table.deepcopy(SpotlightBeamPassive)
SpotlightBeamAlarm.name = "spotlight-beam-alarm"
SpotlightBeamAlarm.ground_light_animations =
{
  ending =
  {
    layers =
    {
      Light_Layer_SpotLight_NormLight_Red,
      Light_Layer_SpotLight_NormLight_Less,
    }
  }
}
SpotlightBeamAlarm.ending =
{
  layers =
  {
    Light_Layer_SpotLight_RimLight_Red,
    Light_Layer_SpotLight_DimLight_Red,
  }
}

data:extend{SpotlightBeamPassive, SpotlightBeamAlarm}


-- SearchLightForDummy; the primary entity which uses a lamp like a turret
-- TODO: use radar_range?
local SearchLightForDummy = table.deepcopy(data.raw["electric-turret"]["laser-turret"])
SearchLightForDummy.flags = {"hidden"}
SearchLightForDummy.name = "searchlight-dummy"
SearchLightForDummy.minable.result = "searchlight"
 -- arbitrary high number btween 5 and 500 to be 'instant'
SearchLightForDummy.rotation_speed = 50
-- Energy priority: Should be below laser turrets, same as most machines, above lamps & accumulators
SearchLightForDummy.energy_source.usage_priority = "secondary-input"
SearchLightForDummy.attack_parameters =
{
  type = "beam",
  range = searchlightOuterRange,
  cooldown = 40,
  source_direction_count = 64,
  source_offset = {0, -3.423489 / 4},
  -- I have no idea what are good penalty values here.
  -- These parameters are pretty new, and there's scant documentation.
  health_penalty = -10,
  rotate_penalty = 10,
  ammo_type =
  {
    category = "laser-turret",
    action =
    {
      type = "direct",
      action_delivery =
      {
        type = "beam",
        beam = "spotlight-beam-passive",
        max_length = searchlightOuterRange,
        duration = 40,
        source_offset = {-1, -1.31439 }
      }
    }
  }
}


local SearchLightForReal = table.deepcopy(SearchLightForDummy)
SearchLightForReal.name = "searchlight"
SearchLightForReal.attack_parameters.ammo_type.action.action_delivery.beam = "spotlight-beam-alarm"


-- The dummy seeking spotlight's beam draws where the turtle is
local Turtle =
{
  type = "unit",
  name = "searchlight-turtle",
  flags =
  {
    "placeable-off-grid",
    "not-on-map",
    "not-blueprintable",
    "not-deconstructable",
    "hidden",
    "not-flammable",
    "no-copy-paste",
    "not-selectable-in-game",
  },
  collision_mask = {"not-colliding-with-itself"},
  collision_box = {{0, 0}, {0, 0}}, -- enable noclip
  selectable_in_game = false,
  selection_box = {{-0.0, -0.0}, {0.0, 0.0}},
  -- We don't intend to leave a corpse at all, but if the worst happens...
  corpse = "small-scorchmark",
  ai_settings =
  {
    allow_try_return_to_spawner = false,
    destroy_when_commands_fail = true
  },
  movement_speed = searchlightTrackSpeed,
  distance_per_frame = 1,
  pollution_to_join_attack = 5000,
  distraction_cooldown = 1,
  vision_distance = 1,
  attack_parameters =
  {
    type = "projectile",
    range = 1,
    cooldown = 100,
    ammo_type = make_unit_melee_ammo_type(1),
    animation = Layer_transparent_animation,
  },
  run_animation = Layer_transparent_animation,
}


-- Add new definitions to game data
data:extend{SearchLightForDummy, SearchLightForReal, Turtle}
