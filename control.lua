local d = require "sl-defines"

require "control-common"
require "control-forces"
require "control-items"
require "control-searchlight"
require "control-turtle"


--
-- In the case where multiple event defines could ostensibly handle the same entity being created or destroyed,
-- we'll register for the event definition which happens 'soonest'
--


-- On Init
script.on_init(
function(event)

  InitTables()
  UpdateBlockList()

end)


-- On Load
script.on_load(
function(event)

  -- UpdateBlockList()
  -- on_load doesn't provide access to game.* functions
  -- maybe we'll find a workaround later
  -- For now, players will just have to update
  -- their settings in game

end)


-- On Mod Settings Changed
script.on_event(defines.events.on_runtime_mod_setting_changed,
function(event)
  if event.setting == d.ignoreEntriesList then
    UpdateBlockList()
    UnboostBlockedTurrets()
  end
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
    if event.effect_id == d.spottedEffectID then
      FoeSuspected(event.source_entity, event.target_entity)
    elseif event.effect_id == d.confirmedSpottedEffectID then
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

    if entity.name == d.searchlightBaseName then
      SearchlightAdded(entity)
    else
      TurretAdded(entity)
    end

  end, {
    {filter = "turret"}
  })
end


-- Doesn't support filters, so it's on its own here
script.on_event(defines.events.on_trigger_created_entity,
function(event)

  if event.entity.name == d.searchlightBaseName then
    SearchlightAdded(event.entity)
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

    if event.entity.name == d.searchlightBaseName or event.entity.name == d.searchlightAlarmName then
      SearchlightRemoved(event.entity)
    else
      TurretRemoved(event.entity)
    end

  end, {
    {filter = "turret"}
  })
end


for index, e in pairs
({
  defines.events.on_entity_died,
  defines.events.script_raised_destroy,
}) do
  script.on_event(e,
  function(event)

    if event.entity.name == d.searchlightBaseName or event.entity.name == d.searchlightAlarmName then
      SearchlightRemoved(event.entity)
    elseif event.entity.type:match "-turret" and event.entity.type ~= "artillery-turret" then
      TurretRemoved(event.entity)
    elseif event.entity.unit_number and global.foes[event.entity.unit_number] then
      FoeDied(event.entity)
    end

  end)
end


for index, e in pairs
({
  defines.events.on_pre_surface_cleared,
  defines.events.on_pre_surface_deleted,
}) do
  script.on_event(e,
  function(event)
    local entities = game.surfaces[event.surface_index].find_entities_filtered{name = {d.searchlightBaseName,
                                                                                       d.searchlightAlarmName}}
    for _, e in pairs(entities) do
      SearchlightRemoved(e)
    end
  end)
end


script.on_event(defines.events.on_pre_chunk_deleted,
function(event)
  local s = game.surfaces[event.surface_index]

  -- Since we're iterating by chunk, we have to be more surgical
  for _, chunkPos in pairs(event.positions) do
    -- Since this is the only handy way to get all entities on a chunk,
    -- we have to iterate for each force
    for _, force in pairs(game.forces) do
      local entities = s.get_entities_with_force(chunkPos, force)

      for _, e in pairs(entities) do
        if e.name == d.searchlightBaseName or e.name == d.searchlightAlarmName then
          SearchlightRemoved(e)
        elseif e.name == d.turtleName
          or e.name == d.spotterName
          or e.name == d.searchlightControllerName then

           -- Just blow up the searchlight as collateral damage
          SearchlightRemoved(e)
          e.destroy()

        elseif e.unit_number then
          TurretRemoved(e) -- Should ignore non-turrets properly
        end
      end
    end
  end
end)


--
-- BLUEPRINTS & GHOSTS
--


-- When the player sets up / configures a blueprint,
-- convert any boosted / alarm-mode entities
-- back to their base entity type
script.on_event(defines.events.on_player_setup_blueprint, ScanBP_StacksAndSwapToBaseType)
script.on_event(defines.events.on_player_configured_blueprint, ScanBP_StacksAndSwapToBaseType)

script.on_event(defines.events.on_pre_ghost_deconstructed,
function(event)
  -- TODO filter this for searchlights
  --      make sure all searchlight ghosts destroyed also have their signal-interface ghost destroyed too
end)


-- When a turret dies, check to see if we need to swap its ghost to a base type
script.on_event(defines.events.on_post_entity_died,
function(event)

  if not event.ghost then
    return
  end

  local unboostedName = ""
  if event.prototype.name == d.searchlightAlarmName then
    unboostedName = d.searchlightBaseName
  else
    unboostedName = event.prototype.name:gsub(d.boostSuffix, "")
  end

  if not game.entity_prototypes[unboostedName] then
    return
  end

  local gh = event.ghost

  game.surfaces[event.surface_index].create_entity{name = "entity-ghost",
                                                   inner_name = unboostedName,
                                                   expires = true,
                                                   fast_replace = true,
                                                   raise_built = false,
                                                   create_build_effect_smoke = false,
                                                   position = gh.position,
                                                   direction = gh.direction,
                                                   force = gh.force,
                                                  }

  gh.destroy()

end, {{filter = "type", type = "ammo-turret"},
      {filter = "type", type = "fluid-turret"},
      {filter = "type", type = "electric-turret"},})


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
