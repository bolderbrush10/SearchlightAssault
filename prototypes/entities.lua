require "defines"

-- You should declare your functions and vars as local in data*.lua files,
-- because other mods apparently have access to your functions at this step (-_-)

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
  scale = 2,
  flags = { "light" },
  shift = {0.3, 0},
}

local redTint = {r=1.0, g=0.1, b=0.1, a=1}

local Light_Layer_SpotLight_NormLight_Less = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_NormLight_Less.filename = "__Searchlights__/graphics/spotlight-r-less.png"

local Light_Layer_SpotLight_RimLight = table.deepcopy(Light_Layer_SpotLight_NormLight)
Light_Layer_SpotLight_RimLight.filename = "__Searchlights__/graphics/spotlight-r-rim.png"

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
  width = 1,
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

data:extend({
{
  type = "trigger-target-type",
  name = turtleMaskName
}
})

local SearchLightBaseEntity =
{
  type = "electric-turret",
  name = searchlightBaseName,
  -- arbitrary high number btween 5 and 500 to be 'instant'
  rotation_speed  = 50,
  -- -- Energy priority: Should be below laser turrets, same as most machines, above lamps & accumulators
  folded_animation = table.deepcopy(data.raw["electric-turret"]["laser-turret"].folded_animation),
  alert_when_attacking = false,
  call_for_help_radius = 40, -- I don't know what this affects for a turret, but it's mandatory
  max_health = 200,
  collision_box = {{ -0.7, -0.7}, {0.7, 0.7}},
  selection_box = {{ -1, -1}, {1, 1}},
  flags = {"placeable-player", "placeable-enemy", "player-creation"},
  minable =
  {
    mining_time = 0.5,
    result = searchlightBaseName,
  },
  energy_source =
  {
    type = "electric",
    usage_priority = "secondary-input",
    buffer_capacity = searchlightCapacitorSize,
    input_flow_limit = "2000kW",
    drain = searchlightEnergyUsage,
  },
  attack_parameters =
  {
    type = "beam",
    range = searchlightOuterRange,
    cooldown = 60, -- measured in ticks
    ammo_type =
    {
      category = "beam",
      -- For some reason, the electric buffer won't show on turrets if you don't specify some cost per shot
      energy_consumption = "1J",
    },
  },
  radius_visualisation_specification =
  {
    distance = searchlightFriendRadius,
    sprite =
    {
      filename = "__base__/graphics/entity/beacon/beacon-radius-visualization.png",
      priority = "extra-high-no-scale",
      width = 10,
      height = 10,
    },
  },
  icon = "__Searchlights__/graphics/terrible.png",
  icon_size = 80,
  base_picture =
  {
    filename = "__Searchlights__/graphics/terrible.png",
    width = 80,
    height = 80,
  },
}


-- TODO: use radar_range?
local SearchLightAttackEntity = table.deepcopy(data.raw["electric-turret"]["laser-turret"])
-- TODO remove this commented flag when we're done,
--      keep it in case we need to remember that we can make things hidden
-- SearchLightAttackEntity.flags = {"hidden"}
SearchLightAttackEntity.selectable_in_game = false
SearchLightAttackEntity.name = searchlightAttackName
 -- arbitrary high number btween 5 and 500 to be 'instant'
SearchLightAttackEntity.rotation_speed = 50
-- Energy priority: Should be below laser turrets, same as most machines, above lamps & accumulators
-- TODO consume electricity by drawing from the base-entity's buffer
SearchLightAttackEntity.energy_source.usage_priority = "secondary-input"
-- We don't intend to leave a corpse at all, but if the worst happens...
-- TODO This is actually a bit more instrusive than you'd think.. find / make an actually-transparent corpse
--      Likewise for the turtle
SearchLightAttackEntity.corpse = "small-scorchmark"
SearchLightAttackEntity.create_ghost_on_death = false
SearchLightAttackEntity.energy_source =
{
  type = "electric",
  usage_priority = "secondary-input",
}
SearchLightAttackEntity.attack_parameters =
{
  type = "beam",
  range = searchlightOuterRange,
  cooldown = 40,
  -- Undocumented, but I'd guess that this is the count of directions that the beam can emit out from
  source_direction_count = 64,
  source_offset = {0, -3.423489 / 4},
  -- I have no idea what are good penalty values here.
  -- These parameters are pretty new, and there's scant documentation.
  -- A negative health penalty will encourage attacking higher-hp targets.
  health_penalty = -10,
  rotate_penalty = 10,
  -- We don't intend to leave a corpse at all, but if the worst happens...
  corpse = "small-scorchmark",
  attack_target_mask = {turtleMaskName},
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
  ammo_type =
  {
    category = "beam",
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

-- The dummy seeking spotlight's beam draws where the turtle is
local Turtle =
{
  type = "unit",
  name = "searchlight-turtle",
  run_animation = table.deepcopy(data.raw["unit"]["small-biter"]).run_animation,
  -- We don't intend to leave a corpse at all, but if the worst happens...
  corpse = "small-scorchmark",
  selectable_in_game = false,
  selection_box = {{-0.0, -0.0}, {0.0, 0.0}},
  collision_box = {{0, 0}, {0, 0}}, -- enable noclip
  collision_mask = {}, -- enable noclip for pathfinding too
  ai_settings =
  {
    allow_try_return_to_spawner = false,
    destroy_when_commands_fail = false,
  },
  flags =
  {
    "placeable-off-grid",
    "not-repairable",
    "not-on-map",
    "not-blueprintable",
    "not-deconstructable",
    "hidden",
    "not-flammable",
    "no-copy-paste",
    "not-selectable-in-game",
  },
  movement_speed = searchlightTrackSpeed,
  distance_per_frame = 1,
  pollution_to_join_attack = 5000,
  distraction_cooldown = 1,
  vision_distance = 0,
  -- TODO Can we leave out the attack parameters?
  attack_parameters =
  {
    type = "projectile",
    range = 0,
    cooldown = 100,
    ammo_type = make_unit_melee_ammo_type(0),
    animation = Layer_transparent_animation,
  },
  -- run_animation = Layer_transparent_animation,
}


-- Add new definitions to game data
data:extend{SearchLightAttackEntity, SearchLightBaseEntity, Turtle}
