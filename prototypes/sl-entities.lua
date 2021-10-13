local d = require "sl-defines"
local g = require "sl-graphics"

require "util" -- for table.deepcopy

-- Be sure to declare functions and vars as 'local' in prototype / data*.lua files,
-- because other mods may have inadvertent access to functions at this step.


local baseHiddenEntityFlags =
{
  "hidden", -- Just hides from some GUIs. Use transparent sprites to bypass rendering
  "no-copy-paste",
  "no-automated-item-insertion",
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

local circuitInterfaceFlags = table.deepcopy(baseHiddenEntityFlags)
table.insert(circuitInterfaceFlags, "player-creation")
table.insert(circuitInterfaceFlags, "placeable-neutral")

local hiddenEntityFlags = table.deepcopy(baseHiddenEntityFlags)
table.insert(hiddenEntityFlags, "not-blueprintable")


-- Searchlight Base Entity
local sl_b = {}
sl_b.name = d.searchlightBaseName
sl_b.type = "electric-turret"
sl_b.max_health = 250
sl_b.icon = "__Searchlights__/graphics/spotlight-icon.png"
sl_b.icon_size = 64
sl_b.icon_mipmaps = 4
sl_b.alert_when_attacking = false
sl_b.energy_source =
{
  type = "electric",
  usage_priority = "secondary-input",
  buffer_capacity = d.searchlightCapacitorSize,
  input_flow_limit = "6000kW",
  drain = d.searchlightEnergyUsage,
}
sl_b.collision_box = {{ -0.7, -0.7}, {0.7, 0.7}}
sl_b.selection_box = {{ -1, -1}, {1, 1}}
sl_b.drawing_box   = {{ -1, -1.3}, {1, 0.7}} -- Controls drawing-bounds in the info-panel
sl_b.flags = {"placeable-player", "placeable-neutral", "placeable-enemy", "player-creation"}
sl_b.call_for_help_radius = 40
sl_b.minable =
{
  mining_time = 0.5,
  result = d.searchlightItemName,
}
sl_b.shoot_in_prepare_state = true
sl_b.folded_animation      = {layers = {g.spotlightHeadAnimation, g.spotlightMaskAnimation, g.spotlightShadowLayer}}
sl_b.prepared_animation    = {layers = {g.spotlightHeadAnimation, g.spotlightMaskAnimation, g.spotlightShadowLayer}}
sl_b.energy_glow_animation = g.spotlightGlowAnimation
sl_b.glow_light_intensity = 1.0
sl_b.preparing_animation = nil
sl_b.folding_animation   = nil
sl_b.attacking_animation = nil
sl_b.base_picture = g.spotlightBaseLayer
-- Affects "hop" time between despawning the turtle and attacking directly, etc
-- Too low will cause lighting to overlap
local attackCooldownDuration = 25
sl_b.attack_parameters =
{
  type = "beam",
  range = d.searchlightRange,
  cooldown = attackCooldownDuration,
  -- Undocumented, but I'd guess that this is the count of directions that the beam can emit out from
  source_direction_count = 256,
  source_offset = {0, 1.2},
  ammo_type =
  {
    category = "beam",
    energy_consumption = "1J", -- If zero, info panel won't show an electricy bar
    action =
    {
      type = "direct",
      action_delivery =
      {
        type = "beam",
        beam = "spotlight-beam-passive",
        max_length = d.searchlightRange,
        duration = attackCooldownDuration,
      }
    }
  }
}


-- Searchlight Alarm Entity
local sl_a = table.deepcopy(sl_b)
sl_a.name = d.searchlightAlarmName
sl_a.alert_when_attacking = true
sl_a.base_picture = g.spotlightBaseAnimated
sl_a.energy_glow_animation = g.spotlightAlarmGlowAnimation
sl_a.attack_parameters.ammo_type.action.action_delivery.beam = "spotlight-beam-alarm"
sl_a.placeable_by = {item = d.searchlightItemName, count = 1}


-- Searchlight Control Entity
local sl_c = {}
sl_c.name = d.searchlightControllerName
sl_c.type = "electric-energy-interface"
sl_c.animation = g.controlUnitSprite
sl_c.light   = g.controlUnitLight
sl_c.icon = "__Searchlights__/graphics/control-icon.png"
sl_c.icon_size = 64
sl_c.icon_mipmaps = 4
sl_c.continuous_animation = true
sl_c.energy_source =
{
  type = "electric",
  usage_priority = "primary-input",
  buffer_capacity = d.searchlightCapacitorSize,
  drain = d.searchlightControlEnergyUsage,
}
sl_c.render_layer = "object"
sl_c.flags = hiddenEntityFlags
sl_c.corpse = "small-scorchmark"
sl_c.create_ghost_on_death = false
sl_c.vision_distance = 0
sl_c.selectable_in_game = false
sl_c.selection_box = {{-0.0, -0.0}, {0.0, 0.0}}
sl_c.collision_box = {{0, 0}, {0, 0}} -- enable noclip
sl_c.collision_mask = {} -- enable noclip for pathfinding too


-- Searchlight Signal Interface Entity
local sl_s = {}
sl_s.type = "constant-combinator"
sl_s.name = d.searchlightSignalInterfaceName
sl_s.icon = "__Searchlights__/graphics/spotlight-icon.png"
sl_s.icon_size = 64
sl_s.icon_mipmaps = 4
sl_s.flags = circuitInterfaceFlags
sl_s.selection_box = {{-.8, .2}, {.8, 1}}
sl_s.collision_box = sl_b.collision_box -- Copy the base collision box so we'll be captured in blueprints / deconstruction
sl_s.collision_mask = {} -- enable noclip for pathfinding too
sl_s.selection_priority = 255
sl_s.item_slot_count = 8
sl_s.placeable_by = {item = d.searchlightItemName, count = 0}
sl_s.circuit_wire_max_distance = 9
sl_s.sprites = g.layerTransparentPixel
sl_s.activity_led_sprites = g.layerTransparentPixel
sl_s.activity_led_light_offsets =
{
  {0, 0},
  {0, 0},
  {0, 0},
  {0, 0},
}
local wirePos =
{
  wire =
  {
    red = {0.35, .45},
    green = {-0.35, .45},
  },
  shadow =
  {
    red = {0.35 + .4, .45 + .4},
    green = {-0.35 + .4, .45 + .4},
  }
}
sl_s.circuit_wire_connection_points =
{
  wirePos,
  wirePos,
  wirePos,
  wirePos,
}


-- The Spotlight's beam lights up the turtle's location
-- The turtle also helps out by using its very small radius of vision to spot foes of the searchlight
-- Many of the values are the product of hours of trial-and-error
-- Do not tweak them without careful observation
local t = {}
t.name = d.turtleName
t.type = "unit"
t.movement_speed = d.searchlightWanderSpeed -- Can update during runtime for wander vs track mode
t.run_animation = g.layerTransparentAnimation
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
t.vision_distance = d.searchlightSpotRadius
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
t.attack_parameters =
{
  range = d.searchlightSpotRadius - 2,
  min_attack_distance = 6,
  type = "projectile",
  cooldown = 60, -- measured in ticks
  animation = g.layerTransparentAnimation,
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
          effect_id = d.spottedEffectID,
        }
      }
    }
  }
}


-- After a turtle has 'found' a foe, use the spotter to chase them down
-- so the foe has a chance to escape
local spotter = {}
spotter.name = d.spotterName
spotter.type = "land-mine"
spotter.flags = hiddenEntityFlags
spotter.selection_box = {{-0.0, -0.0}, {0.0, 0.0}}
spotter.collision_box = {{0, 0}, {0, 0}} -- enable noclip
spotter.collision_mask = {} -- enable noclip for pathfinding too
spotter.picture_safe = g.layerTransparentPixel
spotter.picture_set = g.layerTransparentPixel
spotter.trigger_radius = d.searchlightSpotRadius
-- Keeping the spotter alive will make handling on_script_event calls slightly easier.
-- We'll destroy it ourselves the tick after this fires, when we're done collecting events.
spotter.force_die_on_attack = false
spotter.timeout = d.searchlightSpotTime_ms
spotter.action =
{
  type = "direct",
  action_delivery =
  {
    type = "instant",
    source_effects =
    {
      type = "nested-result",
      affects_target = true,
      action =
      {
        type = "area",
        radius = d.searchlightSpotRadius,
        force = "enemy",
        action_delivery =
        {
          type = "instant",
          target_effects =
          {
            type = "script",
            effect_id = d.confirmedSpottedEffectID,
          }
        }
      }
    }
  }
}


-- Add new definitions to game data
data:extend{sl_a, sl_b, sl_c, sl_s, spotter, t}
