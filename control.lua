require "control-common"
require "control-forces"
require "control-grid"
require "control-searchlight"
require "control-turtle"


--
-- TODO filter all these events
--


-- On Init
script.on_init(
function(event)

  InitForces()
  InitTables()

end)


-- On Load
script.on_load(
function(event)

  -- TODO Is there anything unsaved we need to recalculate every load here?

end)


-- On Tick
script.on_event(defines.events.on_tick,
function(event)
  CheckElectricNeeds(event.tick)

  TrackSpottedFoes(event.tick)

  DecrementBoostTimers(event.tick)
end)


-- On Force Created
script.on_event(defines.events.on_force_created,
function(event)

  if event.force.name ~= searchlightFriend and event.force.name ~= searchlightFoe then
    SetCeaseFires(event.force)
  end

end)


-- On Script Trigger (turtle attack)
script.on_event(defines.events.on_script_trigger_effect,
function(event)
  if event.effect_id == spottedEffectID
  and event.source_entity and event.target_entity then
    FoeSpotted(event.source_entity, event.target_entity)
  end
end)


-- On Command Completed
script.on_event(defines.events.on_ai_command_completed,
function(event)

  if not event.was_distracted and global.turtles[event.unit_number] then
    TurtleWaypointReached(event.unit_number)
  end

  -- event.unit_number
  -- event.was_distracted
  -- event.result

  -- TODO if a turtle gets distracted, re-issue it's goto command n times,
  --      or figure out what entity it was trying to attack and manually fire the
  --      attack_trigger event here

end)


--
-- CONSTRUCTIONS
--


-- TODO steal this pattern
-- (for-loop is needed because filters can't be applied to an
-- array of events!)
-- for event_name, e in pairs({
--   on_built_entity       = defines.events.on_built_entity,
--   on_robot_built_entity = defines.events.on_robot_built_entity,
--   script_raised_built   = defines.events.script_raised_built,
--   script_raised_revive  = defines.events.script_raised_revive
-- defines.events.on_trigger_created_entity
-- }) do
-- --~ log("WT.turret_list: " .. serpent.block(WT.turret_list))
-- --~ log("event_name: " .. serpent.block(event_name) .. "\te: " .. serpent.block(e))
--   script.on_event(e, function(event)
--       WT.dprint("Entered event script for %s.", { event_name })
--       on_built(event)
--       WT.dprint("End of event script for %s.", { event_name })
--     end, {
--     {filter = "type", type = WT.turret_type},
--     {filter = "name", name = WT.steam_turret_name, mode = "and"},

--     {filter = "type", type = WT.turret_type, mode = "or"},
--     {filter = "name", name = WT.water_turret_name, mode = "and"},

--     {filter = "type", type = WT.turret_type, mode = "or"},
--     {filter = "name", name = WT.extinguisher_turret_name, mode = "and"},
--   })
-- end


-- Via Player
script.on_event(defines.events.on_built_entity,
function(event)

  if event.created_entity.name == searchlightBaseName then
    SearchlightAdded(event.created_entity)
  end

  -- TODO other functions for turrets

end)


-- Via Robot
script.on_event(defines.events.on_robot_built_entity,
function(event)

  SearchlightAdded(event.created_entity)

end)


-- Via Script
script.on_event(defines.events.script_raised_built,
function(event)

  SearchlightAdded(event.created_entity)

end)


-- Via Revived by Script
script.on_event(defines.events.script_raised_revive,
function(event)

  SearchlightAdded(event.created_entity)

end)


--
-- DESTRUCTIONS
--


-- Via Player
script.on_event(defines.events.on_pre_player_mined_item,
function(event)

  if event.entity.name == searchlightBaseName then
    SearchlightRemoved(event.entity)
  end

end)


-- Via Robot
script.on_event(defines.events.on_robot_mined_entity,
function(event)

  SearchlightRemoved(event.entity)

end)


-- Via Damage
script.on_event(defines.events.on_entity_died,
function(event)

  if event.entity.name == searchlightBaseName then
    SearchlightRemoved(event.entity)
  elseif event.entity.unit_number then
    FoeDied(event.entity)
  end

  -- TODO if this was a biter / etc, then we could probably check
  --      whether relevant boosted turrets are still allowed to be boosted
  -- On the other hand... turrets probably acquire new shooting targets
  -- long before their bullets actually reach their final destination...
end)


-- Via Script
script.on_event(defines.events.script_raised_destroy,
function(event)

  SearchlightRemoved(event.created_entity)

end)
