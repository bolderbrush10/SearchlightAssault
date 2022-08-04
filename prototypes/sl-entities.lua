local d = require "sl-defines"
local g = require "sl-graphics"
local a = require "audio.sl-audio"

local sounds = require("__base__/prototypes/entity/sounds")
local hit_effects = require ("__base__/prototypes/entity/hit-effects")

require "util" -- for table.deepcopy and util.empty_sprite(animation_length)

-- Be sure to declare functions and vars as 'local' in prototype / data*.lua files,
-- because other mods may have inadvertent access to functions at this step.


local baseHiddenEntityFlags =
{
  "hidden", -- Just hides from some GUIs. Use transparent sprites to bypass rendering
  "no-automated-item-insertion",
  "not-deconstructable",
  "not-flammable",
  "not-in-kill-statistics",
  "not-on-map",
  "not-repairable",
  "not-rotatable",
  "not-upgradable",
  "placeable-off-grid",
}

local circuitInterfaceFlags = table.deepcopy(baseHiddenEntityFlags)
table.insert(circuitInterfaceFlags, "player-creation")
table.insert(circuitInterfaceFlags, "placeable-neutral")

local hiddenEntityFlags = table.deepcopy(baseHiddenEntityFlags)
table.insert(hiddenEntityFlags, "not-blueprintable")
table.insert(hiddenEntityFlags, "not-selectable-in-game")


local baseIcon = "__SearchlightAssault__/graphics/searchlight-icon.png"
local controlIcon = "__SearchlightAssault__/graphics/control-icon.png"

-- Searchlight Base Entity
local sl_b = {}
sl_b.name = d.searchlightBaseName
sl_b.type = "electric-turret"
sl_b.max_health = 250
sl_b.icon = baseIcon
sl_b.icon_size = 64
sl_b.icon_mipmaps = 4
sl_b.alert_when_attacking = false
sl_b.energy_source =
{
  type = "electric",
  usage_priority = "secondary-input",
  buffer_capacity = d.searchlightCapacitorSize,
  input_flow_limit = "500kW",
  drain = d.searchlightEnergyUsage,
}
sl_b.collision_box = {{ -0.7, -0.7}, {0.7, 0.7}}
sl_b.selection_box = {{ -1, -1}, {1, 1}}
sl_b.drawing_box   = {{ -1, -1.3}, {1, 0.7}} -- Controls drawing-bounds in the info-panel
sl_b.allow_copy_paste = true
sl_b.additional_pastable_entities = {d.searchlightAlarmName, d.searchlightSafeName, d.searchlightSignalInterfaceName}
sl_b.flags = {"placeable-player", "player-creation"}
sl_b.is_military_target  = true
sl_b.allow_run_time_change_of_is_military_target = false
sl_b.call_for_help_radius = 40
sl_b.minable =
{
  mining_time = 0.5,
  result = d.searchlightItemName,
}
sl_b.radius_visualisation_specification =
{
  distance = d.searchlightMaxNeighborDistance + 1,
  draw_in_cursor = true,
  draw_on_selection = true,
  sprite = g.radiusSprite,
}
sl_b.base_picture = g.searchlightBaseLayer
sl_b.integration = g.searchlightIntegration
sl_b.water_reflection = g.searchlightReflection
sl_b.folded_animation      = {layers = {g.searchlightHeadAnimation, g.searchlightMaskAnimation, g.searchlightShadowLayer}}
sl_b.prepared_animation    = {layers = {g.searchlightHeadAnimation, g.searchlightMaskAnimation, g.searchlightShadowLayer}}
sl_b.energy_glow_animation = g.searchlightGlowAnimation
sl_b.glow_light_intensity = 1.0
sl_b.energy_glow_animation_flicker_strength = 0
sl_b.preparing_animation = nil
sl_b.folding_animation   = nil
sl_b.attacking_animation = nil
sl_b.damaged_trigger_effect = hit_effects.entity()
sl_b.dying_explosion = "laser-turret-explosion"
sl_b.corpse = d.remnantsName
sl_b.rotated_sound = {filename = "__core__/sound/rotate-big.ogg"}
sl_b.vehicle_impact_sound = sounds.generic_impact
sl_b.working_sound = a.working
sl_b.turret_base_has_direction = true
sl_b.shoot_in_prepare_state = true
sl_b.allow_turning_when_starting_attack = true
sl_b.rotation_speed = 0.05
-- Affects "hop" time between despawning the turtle and attacking directly, etc
-- Too low will cause lighting to overlap
local attackCooldownDuration = 25
sl_b.attack_parameters =
{
  type = "beam",
  range = d.searchlightRange,
  cooldown = attackCooldownDuration,
  -- Undocumented, but I'd guess that this is the count of directions that the beam can emit out from
  -- Higher == smoother
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
        beam = "searchlight-beam-passive",
        max_length = d.searchlightRange,
        duration = attackCooldownDuration,
      }
    }
  }
}


-- Searchlight Safe Entity
local sl_f = table.deepcopy(sl_b)
sl_f.name = d.searchlightSafeName
sl_f.allow_copy_paste = true
sl_f.additional_pastable_entities = {d.searchlightBaseName, d.searchlightAlarmName, d.searchlightSignalInterfaceName}
-- Since folded/prepare/attack_animation don't animate, 
-- only face toward foes, we'll use the base picture to simulate a radar spin
sl_f.base_picture = {layers = {g.searchlightSafeHeadAnimated, 
                               g.searchlightSafeMaskAnimated, 
                               g.searchlightSafeShadowAnimated, 
                               g.searchlightSafeBaseAnimated}}
-- We need to tweak the render layers so the head and mask don't act like they're also on the ground
sl_f.base_picture_render_layer = "object"
-- energy_glow_animation can actually spin if you let it know it has animation frames,
-- which is great since it'll stop glowing when the power goes out
sl_f.energy_glow_animation = g.searchlightSafeGlowAnimation
sl_f.folded_animation = util.empty_sprite(1)
sl_f.prepared_animation = util.empty_sprite(1)
-- Little trick to let us blueprint / copy-paste as the base searchlight, instead
sl_f.placeable_by = {item = d.searchlightItemName, count = 1}
sl_f.shoot_in_prepare_state = true
sl_f.prepare_range = 1 -- The spotter will use the actual d.searchlightSafeRange to detect foes
sl_f.attack_parameters =
{
  type = "beam",
  range = 0.1, -- We don't care about actually hitting anything with this light
  cooldown = attackCooldownDuration,
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
        beam = "searchlight-beam-safe",
        duration = attackCooldownDuration,
      }
    }
  }
}


-- Searchlight Alarm Entity
local sl_a = table.deepcopy(sl_b)
sl_a.name = d.searchlightAlarmName
sl_a.allow_copy_paste = true
sl_a.additional_pastable_entities = {d.searchlightBaseName, d.searchlightSafeName, d.searchlightSignalInterfaceName}
sl_a.alert_when_attacking = true
sl_a.base_picture = g.searchlightBaseAnimated
sl_a.energy_glow_animation = g.searchlightAlarmGlowAnimation
sl_a.attack_parameters.ammo_type.action.action_delivery.beam = "searchlight-beam-alarm"
sl_a.rotation_speed = 1 -- 1 is instant
-- Little trick to let us blueprint / copy-paste as the base searchlight, instead
sl_a.placeable_by = {item = d.searchlightItemName, count = 1}


-- Searchlight Remnants Entity
local sl_r = {}
sl_r.name = d.remnantsName
sl_r.type = "corpse"
sl_r.icon = baseIcon
sl_r.icon_size = 64
sl_r.icon_mipmaps = 4
sl_r.flags = {"placeable-neutral", "not-on-map"}
sl_r.subgroup = "defensive-structure-remnants"
sl_r.order = "a-d-a"
sl_r.selection_box = {{-1, -1}, {1, 1}}
sl_r.tile_width = 2
sl_r.tile_height = 2
sl_r.selectable_in_game = false
sl_r.time_before_removed = 60 * 60 * 15 -- 15 minutes, same as laser-turret remnants
sl_r.final_render_layer = "remnants"
sl_r.remove_on_tile_placement = false
sl_r.animation = g.searchlightRemnants


-- Searchlight Control Entity
local sl_c = {}
sl_c.name = d.searchlightControllerName
sl_c.type = "electric-energy-interface"
sl_c.animation = g.controlUnitSprite
sl_c.integration_patch = g.controlIntegration
sl_c.light   = g.controlUnitLight
sl_c.icon = controlIcon
sl_c.icon_size = 64
sl_c.icon_mipmaps = 4
sl_c.continuous_animation = true
sl_c.energy_source =
{
  type = "electric",
  usage_priority = "secondary-input",
  buffer_capacity = d.searchlightCapacitorSize,
  input_flow_limit = "500kW",
  drain = d.searchlightControlEnergyUsage,
}
sl_c.render_layer = "object"
sl_c.flags = hiddenEntityFlags
sl_c.selectable_in_game = false
sl_c.is_military_target  = false
sl_c.allow_run_time_change_of_is_military_target = false
sl_c.corpse = "small-scorchmark"
sl_c.create_ghost_on_death = false
sl_c.vision_distance = 0
sl_c.selectable_in_game = false
sl_c.selection_box = {{-0.0, -0.0}, {0.0, 0.0}}
sl_c.collision_box = {{-3, -3}, {3, 0}} -- expand bounding box so we can leech electricity reliably
sl_c.collision_mask = {} -- enable noclip for pathfinding too
-- prevent Space Exploration from enabling collision with almost every entity, regardless of being in space
sl_c.se_allow_in_space = true


-- Searchlight Signal Interface Entity
local sl_s = {}
sl_s.type = "constant-combinator"
sl_s.name = d.searchlightSignalInterfaceName
sl_s.allow_copy_paste = true
sl_s.additional_pastable_entities = {d.searchlightBaseName, d.searchlightAlarmName, d.searchlightSafeName}
sl_s.icon = baseIcon
sl_s.icon_size = 64
sl_s.icon_mipmaps = 4
sl_s.flags = circuitInterfaceFlags
sl_s.allow_copy_paste = true
sl_s.is_military_target  = false
sl_s.allow_run_time_change_of_is_military_target = false
sl_s.selection_box = sl_b.selection_box
sl_s.collision_box = sl_b.collision_box -- Copy the base collision box so we'll be captured in blueprints / deconstruction
sl_s.collision_mask = {} -- enable noclip for pathfinding too
-- prevent Space Exploration from enabling collision with almost every entity, regardless of being in space
sl_s.se_allow_in_space = true
sl_s.selection_priority = 1 -- In control.lua we'll detect if the player is holding a wire and fix things there
sl_s.item_slot_count = 20
sl_s.circuit_wire_max_distance = 9
sl_s.sprites = util.empty_sprite()
sl_s.activity_led_sprites = util.empty_sprite()
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


-- The Searchlight's beam lights up the turtle's location
-- The turtle uses its very small radius of vision to spot foes of the searchlight
-- Many of the values are the product of hours of trial-and-error
-- Do not tweak them without careful observation
local t = {}
t.name = d.turtleName
t.type = "unit"
t.movement_speed = d.searchlightWanderSpeed -- Can update during runtime for wander vs track mode
t.run_animation = util.empty_sprite()
t.working_sound = a.scan
t.distance_per_frame = 1 -- speed at which the run animation plays, in tiles per frame
t.rotation_speed = 1.0
-- We don't intend to leave a corpse at all, but if the worst happens...
t.corpse = "small-scorchmark"
t.flags = hiddenEntityFlags
t.selectable_in_game = false
t.is_military_target  = true
t.allow_run_time_change_of_is_military_target = false
t.pollution_to_join_attack = 0
t.has_belt_immunity = true
t.selectable_in_game = false
t.selection_box = {{-0.0, -0.0}, {0.0, 0.0}}
t.collision_box = {{-0.1, -0.1}, {0.1, 0.1}}
t.collision_mask = {}
-- prevent Space Exploration from enabling collision with almost every entity, regardless of being in space
t.se_allow_in_space = true
t.ai_settings =
{
  allow_try_return_to_spawner = false,
  destroy_when_commands_fail = false, -- We'll destroy it ourselves if this happens
  do_separation = false,
}
t.distraction_cooldown = 0 -- undocumented, mandatory
t.min_pursue_time = 0
t.vision_distance = d.searchlightSpotRadius + 1
t.max_pursue_distance = t.vision_distance + 10
t.move_while_shooting = true
t.attack_parameters =
{
  range = 1,
  type = "projectile",
  cooldown = 60, -- measured in ticks
  animation = util.empty_sprite(),
  range_mode = "center-to-center",
  movement_slow_down_factor = 0,
  movement_slow_down_cooldown = 0,
  activation_type = "activate",
  ammo_type =
  {
    category= "melee",
    target_type = "direction",
    action =
    {
      type = "direct",
      action_delivery =
      {
        type = "instant",
        target_effects =
        {
          {
            type = "script",
            effect_id = d.confirmedSpottedEffectID,
          },
          {
            type = "play-sound",
            sound = a.spotted,
          }
        }
      }
    }
  }
}


local spotter = {}
spotter.name = d.spotterName
spotter.type = "turret"
spotter.flags = hiddenEntityFlags
spotter.selectable_in_game = false
spotter.is_military_target  = false
spotter.allow_run_time_change_of_is_military_target = false
spotter.selection_box = {{-0.0, -0.0}, {0.0, 0.0}}
spotter.collision_box = {{0, 0}, {0, 0}} -- enable noclip
spotter.collision_mask = {} -- enable noclip for pathfinding too
-- prevent Space Exploration from enabling collision with almost every entity, regardless of being in space
spotter.se_allow_in_space = true
spotter.base_picture = util.empty_sprite()
spotter.folded_animation = util.empty_sprite()
spotter.call_for_help_radius = 1
spotter.attack_parameters =
{
  range = d.searchlightSafeRange,
  type = "projectile",
  cooldown = 60, -- measured in ticks
  animation = util.empty_sprite(),
  range_mode = "center-to-center",
  movement_slow_down_factor = 0,
  movement_slow_down_cooldown = 0,
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
        source_effects =
        {
          {
            type = "script",
            effect_id = d.spottedEffectID,
          },
        }
      }
    }
  }
}


local t_s = table.deepcopy(data.raw["corpse"]["small-scorchmark-tintable"])
t_s.name = "sl-tiny-scorchmark-tintable"
t_s.time_before_removed = 1000
t_s.ground_patch.sheet.scale = 0.2
t_s.ground_patch_higher.sheet.scale = 0.1
t_s.ground_patch.sheet.hr_version.scale = 0.2
t_s.ground_patch_higher.sheet.hr_version.scale = 0.1

-- Add new definitions to game data
data:extend{sl_a, sl_b, sl_c, sl_f, sl_r, sl_s, spotter, t, t_s}
