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

local militaryAndGhostsFilter =
{
  {filter = "type", type = "entity-ghost"},
  table.unpack(militaryFilter)
}


local function entityRemoved(event)
  local entity = event.entity

  if entity.type == "entity-ghost" and entity.ghost_name == d.searchlightBaseName then
    ghostRemoved(entity)
  elseif entity.name == d.searchlightBaseName 
      or entity.name == d.searchlightAlarmName 
      or entity.name == d.searchlightSafeName then
    local onDeath = event.name == defines.events.on_entity_died 
    -- or event.name == defines.events.script_raised_destroy
    -- Since destroy() doesn't leave a corpse / ghost, we probably don't want to manually create any
    
    cg.SearchlightRemoved(entity.unit_number, onDeath)
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
  -- We used to check 'on_robot_pre_mined' but it turns out,
  -- robots doing a fast-replace doesn't trigger that call
  defines.events.on_robot_mined_entity,
}) do
  script.on_event(e, entityRemoved, militaryAndGhostsFilter)
end


for index, e in pairs
({
  defines.events.on_entity_died,
  defines.events.script_raised_destroy,
}) do
  script.on_event(e, entityRemoved)
end


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


-- It's possible for the player to right click to destroy a searchlight ghost,
-- but leave behind the signal interface ghost from a blueprint.
-- The best we can do is detect when such ghosts are built and destroy them
-- after the fact, since there doesn't seem to be an event to detect when
-- the player manually clears a ghost via right click.
export.CheckSignalInterfaceHasSearchlight = function(i)
  local sLight = i.surface.find_entities_filtered{name={d.searchlightBaseName,d.searchlightAlarmName},
                                                  position = i.position}

  local slGhost = i.surface.find_entities_filtered{ghost_name={d.searchlightBaseName},
                                                   position = i.position}

  if not ((sLight  and sLight[1])
       or (slGhost and slGhost[1])) then
    i.destroy()
  end
end

-- Doesn't support filters, so it's on its own here
script.on_event(defines.events.on_trigger_created_entity,
function(event)

  if event.entity.name == d.searchlightBaseName then
    cg.SearchlightAdded(event.entity)
  elseif event.entity.name == d.searchlightSignalInterfaceName then
    ci.CheckSignalInterfaceHasSearchlight(entity)
  elseif event.entity.type:match "-turret" and event.entity.type ~= "artillery-turret" then
    cu.TurretAdded(event.entity)
  end

end)


--
-- DESTRUCTIONS
--

-- Detect destructions registered through LuaBootstrap.register_on_entity_destroyed
-- TODO Do I need to register ghost-entities for the searchlight & interface, too?
script.on_event(defines.events.on_entity_destroyed, function(event)
  if event.unit_number then
    cg.SearchlightRemoved(event.unit_number)
  end
end)


-- Make sure all destroyed searchlight ghosts and signal-interface ghosts have their counterparts destroyed too
local function ghostRemoved(ghost)
  local complements = nil
  if ghost.ghost_name == d.searchlightBaseName then
    complements = ghost.surface.find_entities_filtered{ghost_name = d.searchlightSignalInterfaceName,
                                                      position   = ghost.position,}
  else
    complements = ghost.surface.find_entities_filtered{ghost_name = d.searchlightBaseName,
                                                       position   = ghost.position,}
  end

  for _, g in pairs(complements) do
    g.destroy()
  end
end



for index, e in pairs
({
  defines.events.on_pre_surface_cleared,
  defines.events.on_pre_surface_deleted,
}) do
  script.on_event(e,
  function(event)
    local entities = game.surfaces[event.surface_index].find_entities_filtered{name = {d.searchlightBaseName,
                                                                                       d.searchlightAlarmName,
                                                                                       d.searchlightSafeName}}
    for _, e in pairs(entities) do
      cg.SearchlightRemoved(e.unit_number)
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
        if     e.name == d.searchlightBaseName 
            or e.name == d.searchlightAlarmName
            or e.name == d.searchlightSafeName then
          cg.SearchlightRemoved(e.unit_number)
        elseif e.name == d.turtleName
          or e.name == d.spotterName
          or e.name == d.searchlightControllerName then

          -- Just destroy the searchlight as collateral damage
          cg.SearchlightRemoved(e.unit_number)
          e.destroy()

        elseif e.unit_number then
          cu.TurretRemoved(e) -- Should ignore non-turrets properly
        end
      end
    end
  end
end)

script.on_event(defines.events.on_pre_ghost_deconstructed,
function(event)
  ghostRemoved(event.ghost)
end,
{
  {filter = "ghost_name", name = d.searchlightBaseName},
  {filter = "ghost_name", name = d.searchlightSignalInterfaceName}
})


-- When a turret dies, check to see if we need to swap its ghost to a base type
script.on_event(defines.events.on_post_entity_died,
function(event)

  if not event.ghost then
    return
  end

  local unboostedName = ""
  if     event.prototype.name == d.searchlightAlarmName
      or event.prototype.name == d.searchlightSafeName then
    unboostedName = d.searchlightBaseName
  else
    unboostedName = event.prototype.name:gsub(d.boostSuffix, "")
  end

  if unboostedName == event.prototype.name then
    return
  end

  if not game.entity_prototypes[unboostedName] then
    return
  end

  local gh = event.ghost

  game.surfaces[event.surface_index].create_entity{name = "entity-ghost",
                                                   inner_name = unboostedName,
                                                   expires = true,
                                                   fast_replace = false,
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

local function detectEditorChanges()
  local surfaces = global.editorSurfaces
  
  if not surfaces then
    surfaces = {}
    for pindex, p in pairs(game.players) do
      surfaces[p.surface.index] = true
    end
  end

  for sindex, _ in pairs(surfaces) do
    local s = game.surfaces[sindex]
    local turrets = s.find_entities_filtered{type="turret"}

    -- First things first, iterate through all tunions
    -- and carefully pick apart any tunions with an invalid turret
    -- (We'll do the turrets first to make it less likely to crash
    --  if an invalid searchlight references an invalid turret)
    for tuID, tu in pairs(global.tunions) do
      if not tu.turret.valid then
        cu.TurretRemoved(nil, tu)
      end
    end

    -- Then do the same for gestalts
    for gID, g in pairs(global.gestalts) do
      if not g.light.valid then
        cg.SearchlightRemoved(nil, false, g)
      end
    end

    for _, t in pairs(turrets) do
      -- Then check for searchlights without a gestalt
      if  t.name == d.searchlightBaseName
          or t.name == d.searchlightAlarmName
          or t.name == d.searchlightSafeName then
        if not global.unum_to_g[t.unit_number] then SearchlightAdded(t) end
      -- Then check for turrets neighboring gestalts to make sure they got added
      elseif not global.tun_to_tunion[t.unit_number] then
        cu.TurretAdded(t)
      end   
    end

  end
end


-- This is the best we can do for detecting when
-- a player is messing with stuff in the map editor
-- (Since events don't fire in some editor tabs)
local function checkEditor()
  global.editorSurfaces = nil

  for _, p in pairs(game.players) do
    if p.controller_type == defines.controllers.editor then
      if not global.editorSurfaces then
        global.editorSurfaces = {}
      end

      global.editorSurfaces[p.surface.index] = true
    end
  end

  -- All players left the editor, do a final sweep
  if global.inEditor == nil then
    detectEditorChanges()
  end
end


script.on_event(defines.events.on_player_toggled_map_editor, checkEditor)
