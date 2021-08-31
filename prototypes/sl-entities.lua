require "sl-defines"

local g = require "sl-graphics"


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
  "not-repairable",
  "not-rotatable",
  "not-selectable-in-game",
  "not-upgradable",
  "placeable-off-grid",
}


-- Searchlight Base Entity
local sl_b = table.deepcopy(data.raw["electric-turret"]["laser-turret"])
sl_b.type = "turret"
sl_b.name = searchlightBaseName
sl_b.max_health = 250
sl_b.icon = "__Searchlights__/graphics/terrible.png"
sl_b.icon_size = 80
sl_b.alert_when_attacking = false
sl_b.energy_source =
{
  type = "electric",
  usage_priority = "secondary-input",
  buffer_capacity = searchlightCapacitorSize,
  input_flow_limit = "6000kW",
  drain = searchlightEnergyUsage,
}
sl_b.collision_box = {{ -0.7, -0.7}, {0.7, 0.7}}
sl_b.selection_box = {{ -1, -1}, {1, 1}}
sl_b.flags = {"placeable-player", "placeable-neutral", "placeable-enemy", "player-creation"}
sl_b.minable =
{
  mining_time = 0.5,
  result = searchlightItemName,
}
-- TODO move into graphics
-- TODO This got broken at some point?? figure that out...
sl_b.radius_visualisation_specification =
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
  }
}
sl_b.attack_parameters =
{
  type = "beam",
  range = searchlightRange,
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
        max_length = searchlightRange,
        duration = 40,
        source_offset = {-1, -1.31439 }
      }
    }
  }
}


-- The Spotlight's beam lights up the turtle's location
-- The turtle also helps out by using its very small radius of vision to spot foes of the searchlight
local t = {}
t.type = "unit"
t.name = turtleName
t.movement_speed = searchlightWanderSpeed -- Can update during runtime for wander vs track mode
-- run_animation = Layer_transparent_animation
t.run_animation = table.deepcopy(data.raw["unit"]["small-biter"]).run_animation
t.distance_per_frame = 1 -- speed at which the run animation plays, in tiles per frame
-- We don't intend to leave a corpse at all, but if the worst happens...
t.corpse = "small-scorchmark"
t.flags = hiddenEntityFlags
t.pollution_to_join_attack = 0
t.has_belt_immunity = true
t.move_while_shooting = true
t.distraction_cooldown = 0 -- undocumented, mandatory
t.min_pursue_time = 0
t.max_pursue_distance = 5
-- Setting vision distance too low can cause turtles to get stuck in their foes
t.vision_distance = searchlightSpotRadius
t.selectable_in_game = false
t.selection_box = {{-0.0, -0.0}, {0.0, 0.0}}
t.collision_box = {{0, 0}, {0, 0}} -- enable noclip
t.collision_mask = {} -- enable noclip for pathfinding too
t.ai_settings =
{
  allow_try_return_to_spawner = false,
  destroy_when_commands_fail = false,
  do_separation = false,
}
-- TODO We could probably make a mod option to filter against
--      target masks / entity flags here so flying units, etc aren't spottable
t.attack_parameters =
{
  -- Any smaller a value for range(1) or min_attack_distance(3) will cause
  -- the turtle to just wiggle in the center of biter nests.
  -- Too much higher for min_attack_distance(6) and turtles will
  -- give up on attacking and walk away more often.
  range = 1,
  min_attack_distance = 6,
  type = "projectile",
  cooldown = 60, -- measured in ticks
  animation = g["Layer_transparent_animation"],
  range_mode = "center-to-center",
  movement_slow_down_factor = 0,
  movement_slow_down_cooldown = 0,
  activation_type = "activate",
  ammo_type =
  {
    category= "melee",
    target_type = "entity",
    action =
    {
      type = "direct",
      action_delivery =
      {
        type = "instant",
        target_effects =
        {
          type = "script",
          effect_id = spottedEffectID,
        }
      }
    }
  }
}


-- Add new definitions to game data
data:extend{sl_b, t}
