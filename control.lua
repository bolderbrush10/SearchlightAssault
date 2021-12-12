local d = require "sl-defines"
local r = require "sl-relation"

local cc = require "control-common"
local cf = require "control-forces"
local cg = require "control-gestalt"
local ci = require "control-items"
local cs = require "control-searchlight"
local ct = require "control-turtle"
local cu = require "control-tunion"


-- Reference: https://wiki.factorio.com/Military_units_and_structures
local militaryFilter =
{
  {filter = "turret"},
  {filter = "type", type = "character"},
  {filter = "type", type = "combat-robot"},
  {filter = "type", type = "construction-robot"},
  {filter = "type", type = "logistic-robot"},
  {filter = "type", type = "land-mine"},
  {filter = "type", type = "unit"},
  {filter = "type", type = "artillery-turret"},
  {filter = "type", type = "radar"},
  {filter = "type", type = "unit-spawner"},
  {filter = "type", type = "player-port"},
  {filter = "type", type = "simple-entity-with-force"},
}

--
-- In the case where multiple event defines could ostensibly handle the same entity being created or destroyed,
-- we'll register for the event definition which happens 'soonest'
--


-- On Init
script.on_init(
function(event)

  cc.InitTables()

end)


local function handleUninstall()
  if settings.global[d.uninstallMod].value then
    for _, g in pairs(global.gestalts) do
      local b = g.light;
      cg.SearchlightRemoved(b);
      b.destroy()
    end

    -- The above loop SHOULD have cleaned this out,
    -- but it can't hurt to be careful
    for _, tID in pairs(global.boosted_to_tunion) do
      cu.UnBoost(global.tunions[tID])
    end

    global.boosted_to_tunion = {}
    global.tunions = {}
  end
end


local function handleModSettingsChanges(event)
  if not event or event.setting == d.ignoreEntriesList then
    cu.UpdateBlockList()
    cu.UnboostBlockedTurrets()
  end
  handleUninstall()
end


-- On Mod Settings Changed
script.on_event(defines.events.on_runtime_mod_setting_changed, handleModSettingsChanges)
-- (Doesn't handle runtime changes or changes from the main menu, unless another mod is enabled/diabled)
script.on_configuration_changed(handleModSettingsChanges)
-- script.on_load()
-- on_load doesn't provide access to game.* functions,
-- and mod settings changed at the main menu don't seem to persist
-- onto already-created games anyway... So, don't bother.


-- On Tick
script.on_event(defines.events.on_tick,
function(event)

  -- Run seperate loops for gestalts vs turrets since they
  -- could possibly be in seperate electric networks
  cg.CheckElectricNeeds()
  cu.CheckElectricNeeds()

  cg.CheckGestaltFoes()

  if global.watch_circles[event.tick] then
    cg.CloseWatchCircle(global.watch_circles[event.tick])
    global.watch_circles[event.tick] = nil
  end

end)


-- Run twice a second (at 60 ups)
script.on_nth_tick(30,
function(event)

  cs.CheckCircuitConditions()

end)


-- On Script Trigger (turtle attack)
script.on_event(defines.events.on_script_trigger_effect,
function(event)
  if event.source_entity and event.target_entity then
    if event.effect_id == d.spottedEffectID then
      cg.FoeSuspected(event.source_entity, event.target_entity.position)
    elseif event.effect_id == d.confirmedSpottedEffectID then
      cg.OpenWatchCircle(event.source_entity, event.target_entity, game.tick + 1)
    end
  end
end)


-- On Command Completed
script.on_event(defines.events.on_ai_command_completed,
function(event)

  local g = global.unum_to_g[event.unit_number]
  if not g then
    return
  end

  -- In an edge case, it's possible to unlink the searchlight from shooting at the turtle
  -- if someone aggros the turtle near the searchlight max range and pulls it away from the sl
  -- In that case, we'll retarget the turtle as soon as we get an event to let us know
  -- this possibly happened: here.
  ct.CheckForTurtleEscape(g)

  -- Triggers after the distraction finishes or command finishes failing
  -- If a turtle is having trouble attacking something, we'll manually spawn a spotter for it
  local failed = event.result == defines.behavior_result.fail
  if event.was_distracted or failed then
    cg.FoeSuspected(g.turtle, g.turtle.position)
  else
    ct.TurtleWaypointReached(g)
  end

end)


-- On Player Rotated
script.on_event(defines.events.on_player_rotated_entity,
function(event)
  local e = event.entity
  local tu = global.boosted_to_tunion[e.unit_number]

  if not tu then
    return
  end

  if    not e.shooting_target
     or not next(r.getRelationLHS(global.FoeGestaltRelations, e.unit_number)) then
    cu.UnBoost(tu)
  end

end)


--
-- CONSTRUCTIONS
--


-- Instead of doing this loop, you could pass in an array of events.
-- But you can't use filters with such an array, so loop we shall.
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
      cg.SearchlightAdded(entity)
    elseif entity.name == d.searchlightSignalInterfaceName then
      ci.CheckSignalInterfaceHasSearchlight(entity)
    else
      cu.TurretAdded(entity)
    end

  end, {
    {filter = "turret"},
    {filter = "name", name = d.searchlightSignalInterfaceName}
  })
end


-- Doesn't support filters, so it's on its own here
script.on_event(defines.events.on_trigger_created_entity,
function(event)

  if event.entity.name == d.searchlightBaseName then
    cg.SearchlightAdded(event.entity)
  elseif entity.name == d.searchlightSignalInterfaceName then
    ci.CheckSignalInterfaceHasSearchlight(entity)
  elseif event.entity.type:match "-turret" and event.entity.type ~= "artillery-turret" then
    cu.TurretAdded(event.entity)
  end

end)


--
-- DESTRUCTIONS
--

local function entityRemoved(event)
  local entity = event.entity

  if entity.name == d.searchlightBaseName or entity.name == d.searchlightAlarmName then

    local onDeath = event.name == defines.events.on_entity_died 
    -- or event.name == defines.events.script_raised_destroy
    -- Since destroy() doesn't leave a corpse / ghost, we probably don't want to manually create any
    
    cg.SearchlightRemoved(entity, onDeath)
  elseif entity.type:match "-turret" and entity.type ~= "artillery-turret" then
    cu.TurretRemoved(entity)
  end

  -- It's possible that one searchlight's friend is another's foe...
  if entity.unit_number and next(r.getRelationLHS(global.FoeGestaltRelations, entity.unit_number)) then
    cg.FoeDied(entity)
  end
end


for index, e in pairs
({
  defines.events.on_pre_player_mined_item,
  defines.events.on_robot_pre_mined,
}) do
  script.on_event(e, entityRemoved, militaryFilter)
end


for index, e in pairs
({
  defines.events.on_entity_died,
  defines.events.script_raised_destroy,
}) do
  script.on_event(e, entityRemoved)
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
      cg.SearchlightRemoved(e)
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
          cg.SearchlightRemoved(e)
        elseif e.name == d.turtleName
          or e.name == d.spotterName
          or e.name == d.searchlightControllerName then

          -- Just destroy the searchlight as collateral damage
          cg.SearchlightRemoved(e)
          e.destroy()

        elseif e.unit_number then
          cu.TurretRemoved(e) -- Should ignore non-turrets properly
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
script.on_event(defines.events.on_player_setup_blueprint,      ci.ScanBP_StacksAndSwapToBaseType)
script.on_event(defines.events.on_player_configured_blueprint, ci.ScanBP_StacksAndSwapToBaseType)


-- Make sure all searchlight ghosts destroyed also have their signal-interface ghost destroyed too
script.on_event(defines.events.on_pre_ghost_deconstructed,
function(event)
  local signal = event.ghost.surface.find_entities_filtered{ghost_name = d.searchlightSignalInterfaceName,
                                                            position   = event.ghost.position,}
  for _, s in pairs(signal) do
    s.destroy()
  end
end,
{
  {filter = "ghost_name", name = d.searchlightBaseName}
})


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

    cf.UpdateTForceRelationships(event.force)

  end)
end


-- On Force About To Be Merged
script.on_event(defines.events.on_forces_merging,
function(event)

  cf.MigrateTurtleForces(event.source, event.destination)

end)
