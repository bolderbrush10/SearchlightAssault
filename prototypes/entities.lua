require "defines"

local g = require "graphics"

-- Be sure to declare functions and vars as 'local' in prototype / data*.lua files,
-- because other mods may have inadvertent access to functions at this step.

local hiddenEntityFlags =
{
  "hidden", -- Just hides from some GUIs. Use transparent sprites to bypass rendering
  "no-copy-paste",
  "no-automated-item-insertion",
  "not-blueprintable",
  "not-deconstructable",
  "not-flammable",
  "not-in-kill-statistics",
  "not-on-map",
  "not-selectable-in-game",
  "not-upgradable",
  "placeable-off-grid",
}

-- Searchlight Base Entity
local sl_b =
{
  -- type = "electric-turret",
  -- type = "lamp",
  type = "electric-energy-interface",
  name = searchlightBaseName,
  -- arbitrary high number btween 5 and 500 to be 'instant'
  rotation_speed  = 50,
  folded_animation = table.deepcopy(data.raw["electric-turret"]["laser-turret"].folded_animation),
  picture = table.deepcopy(data.raw["electric-turret"]["laser-turret"].folded_animation),
  picture_on = table.deepcopy(data.raw["electric-turret"]["laser-turret"].folded_animation),
  picture_off = table.deepcopy(data.raw["electric-turret"]["laser-turret"].folded_animation),
  -- energy_usage = "1J",

    -- circuit_wire_connection_point = circuit_connector_definitions["lamp"].points,
    -- circuit_connector_sprites = circuit_connector_definitions["lamp"].sprites,
    -- circuit_wire_max_distance = default_circuit_wire_max_distance,

  -- alert_when_attacking = false,
  -- call_for_help_radius = 40, -- I don't know what this affects for a turret, but it's mandatory
  max_health = 200,
  collision_box = {{ -0.7, -0.7}, {0.7, 0.7}},
  selection_box = {{ -1, -1}, {1, 1}},
  flags = {"placeable-player", "placeable-neutral", "placeable-enemy", "player-creation"},
  minable =
  {
    mining_time = 0.5,
    result = searchlightItemName,
  },
  energy_usage = searchlightEnergyUsage,
  energy_source =
  {
    type = "electric",
    usage_priority = "secondary-input",
    buffer_capacity = searchlightCapacitorSize,
    input_flow_limit = "2000kW",
  },
  attack_parameters =
  {
    type = "beam",
    -- range = searchlightOuterRange,
    range = 1,
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
      layers =
      {
        {
          filename = "__Searchlights__/graphics/circleish-radius-visualizat.png",
          priority = "extra-high-no-scale",
          width = 10,
          height = 10,
          scale = 8,
          tint = {0.8, 0.2, 0.2, 0.8}
        },
        {
          filename = "__Searchlights__/graphics/terrible.png",
          priority = "extra-high-no-scale",
          width = 80,
          height = 80,
          scale = 0.125,
          tint = {0.2, 0.2, 0.8, 0.8}
        },
      }
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


-- Searchlight Attack Entity
local sl_a = table.deepcopy(data.raw["electric-turret"]["laser-turret"])
sl_a.selectable_in_game = false
sl_a.name = searchlightAttackName
 -- arbitrary high number between 5 and 500 to be 'instant'
sl_a.rotation_speed = 50
-- Energy priority: Should be below laser turrets, same as most machines, above lamps & accumulators
-- TODO consume electricity by drawing from the base-entity's buffer
sl_a.energy_source.usage_priority = "secondary-input"
-- We don't intend to leave a corpse at all, but if the worst happens...
-- TODO This is actually a bit more instrusive than you'd think.. find / make an actually-transparent corpse
--      Likewise for the turtle
sl_a.corpse = "small-scorchmark"
sl_a.create_ghost_on_death = false
sl_a.flags = hiddenEntityFlags
sl_a.energy_source =
{
  type = "electric",
  usage_priority = "secondary-input",
}
sl_a.attack_parameters =
{
  type = "beam",
  range = searchlightOuterRange,
  cooldown = 40,
  -- Undocumented, but I'd guess that this is the count of directions that the beam can emit out from
  source_direction_count = 64,
  source_offset = {0, -3.423489 / 4},
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
local turtle =
{
  type = "unit",
  name = turtleName,
  run_animation = table.deepcopy(data.raw["unit"]["small-biter"]).run_animation,
  -- We don't intend to leave a corpse at all, but if the worst happens...
  corpse = "small-scorchmark",
  selectable_in_game = false,
  selection_box = {{-0.0, -0.0}, {0.0, 0.0}},
  collision_box = {{0, 0}, {0, 0}}, -- enable noclip
  collision_mask = {}, -- enable noclip for pathfinding too
  flags = hiddenEntityFlags,
  movement_speed = searchlightTrackSpeed,
  distance_per_frame = 1,
  pollution_to_join_attack = 5000,
  distraction_cooldown = 1,
  vision_distance = 0,
  ai_settings =
  {
    allow_try_return_to_spawner = false,
    destroy_when_commands_fail = false,
  },
  -- TODO Can we leave out the attack parameters?
  attack_parameters =
  {
    type = "projectile",
    range = 0,
    cooldown = 100,
    ammo_type = make_unit_melee_ammo_type(0),
    animation = g["Layer_transparent_animation"],
  },
  -- run_animation = Layer_transparent_animation,
}


-- Add new definitions to game data
data:extend{sl_a, sl_b, turtle}
