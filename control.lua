require "control-common"
require "control-forces"
require "control-searchlight"
require "control-turtle"


--
-- TODO We need to think about what happens when a searchlight/turret of the opposing force is added / removed
-- We'll have to make an event hook here that'll update something in control-forces.lua
--


--
-- In the case where multiple event defines could ostensibly handle the same entity being created or destroyed,
-- we'll register for the event definition which happens 'soonest'
--


-- On Init
script.on_init(
function(event)

  InitTables()

end)


-- On Load
script.on_load(
function(event)

  -- TODO Is there anything unsaved we need to recalculate every load here?
  --      Anything we can recalculate, to save disk space?

end)


-- On Tick
script.on_event(defines.events.on_tick,
function(event)

  CheckElectricNeeds()
  HandleCircuitConditions()
  TrackSpottedFoes()

  if global.watch_circles[event.tick] then
    CloseWatchCircle(global.watch_circles[event.tick])
    global.watch_circles[event.tick] = nil
  end

end)


-- On Script Trigger (turtle attack)
script.on_event(defines.events.on_script_trigger_effect,
function(event)
  if event.source_entity and event.target_entity then
    if event.effect_id == spottedEffectID then
      FoeSuspected(event.source_entity, event.target_entity)
    elseif event.effect_id == confirmedSpottedEffectID then
      OpenWatchCircle(event.source_entity, event.target_entity, game.tick + 1)
    end
  end
end)


-- On Command Completed
script.on_event(defines.events.on_ai_command_completed,
function(event)

  if global.unum_to_g[event.unit_number] then
    if not event.was_distracted then
      TurtleWaypointReached(event.unit_number, event.result == defines.behavior_result.fail)
    else
      -- TODO Will this trigger before or after the distraction starts/finishes?
      TurtleDistracted(event.unit_number, event.result == defines.behavior_result.fail)
    end
  end

end)


--
-- CONSTRUCTIONS
--


for index, e in pairs
({
  defines.events.on_built_entity,
  defines.events.on_robot_built_entity,
  defines.events.script_raised_built,
  defines.events.script_raised_revive,
}) do
  script.on_event(e,
  function(event)

    local entity = nil
    if event.created_entity then
      entity = event.created_entity
    else
      entity = event.entity
    end

    if entity.name == searchlightBaseName then
      SearchlightAdded(entity)
    else
      TurretAdded(entity)
    end

  end, {
    {filter = "name", name = searchlightBaseName},
    {filter = "turret", mode = "or"}
  })
end


-- Doesn't support filters, so it's on its own here
script.on_event(defines.events.on_trigger_created_entity,
function(event)

  if event.entity.name == searchlightBaseName then
    SearchlightAdded(event.entity )
  elseif event.entity.type:match "-turret" and event.entity.type ~= "artillery-turret" then
    TurretAdded(event.entity)
  end

end)


--
-- DESTRUCTIONS
--


for index, e in pairs
({
  defines.events.on_pre_player_mined_item,
  defines.events.on_robot_pre_mined,
}) do
  script.on_event(e,
  function(event)

    if event.entity.name == searchlightBaseName or event.entity.name == searchlightAlarmName then
      SearchlightRemoved(event.entity)
    else
      TurretRemoved(event.entity)
    end

  end, {
    {filter = "name", name = searchlightBaseName},
    {filter = "name", name = searchlightAlarmName, mode = "or"},
    {filter = "turret", mode = "or"}
  })
end


for index, e in pairs
({
  defines.events.on_entity_died,
  defines.events.script_raised_destroy,
}) do
  script.on_event(e,
  function(event)

    if event.entity.name == searchlightBaseName or event.entity.name == searchlightAlarmName then
      SearchlightRemoved(event.entity)
    elseif event.entity.type:match "-turret" and event.entity.type ~= "artillery-turret" then
      TurretRemoved(event.entity)
    elseif event.entity.unit_number and global.foes[event.entity.unit_number] then
      FoeDied(event.entity)
    end

  end)
end


--
-- FORCES
--

-- On Force Relationship Changed
for index, e in pairs
({
  defines.events.on_force_cease_fire_changed,
  defines.events.on_force_friends_changed,
}) do
  script.on_event(e,
  function(event)

    UpdateTForceRelationships(event.force)

  end)
end


-- On Force About To Be Merged
script.on_event(defines.events.on_forces_merging,
function(event)

  MigrateTurtleForces(event.source, event.destination)

end)
