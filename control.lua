local d = require "sl-defines"
local r = require "sl-relation"

local cb = require "control-blocklist"
local cc = require "control-common"
local cf = require "control-forces"
local cg = require "control-gestalt"
local ci = require "control-items"
local cs = require "control-searchlight"
local ct = require "control-turtle"
local cu = require "control-tunion"

local cgui = require "control-gui"

local rd = require "sl-render"

local compat = require "compatability/sl-compatability"


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

local pastableSignals =
{
  d.circuitSlots.radiusSlot,
  d.circuitSlots.rotateSlot,
  d.circuitSlots.minSlot   ,
  d.circuitSlots.maxSlot   ,
  d.circuitSlots.dirXSlot  ,
  d.circuitSlots.dirYSlot  ,
}


--
-- In the case where multiple event defines could ostensibly handle the same entity being created or destroyed,
-- we'll register for the event definition which happens 'soonest'
--


-- On Init
script.on_init(
function(event)

  cc.InitTables()

  compat.Compatability_OnInit()

end)


local function handleUninstall()
  if settings.global[d.uninstallMod].value then
    for _, g in pairs(global.gestalts) do
      local b = g.light;
      cg.SearchlightRemoved(b.unit_number);
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
  -- In case this mod was updated, close any open windows
  -- so we don't have to worry about obsolete GUI
  -- elements being available
  for pIndex, _ in pairs(game.players) do
    cgui.CloseSearchlightGUI(pIndex)
  end

  if not event or event.setting == d.ignoreEntriesList then
    cb.UpdateBlockList()
    cb.UnboostBlockedTurrets()
  end

  if event and event.setting == d.overrideAmmoRange then
    if not settings.global[d.overrideAmmoRange].value then
      cu.RespectMaxAmmoRange()
    end
  end

  handleUninstall()
  cb.UpdateBlockList()
end

local function handleConfigurationChanged(event)
  for _, force in pairs(game.forces) do
    cf.UpdateTForceRelationships(force)
  end

  handleModSettingsChanges(event)
end

-- On Mod Settings Changed
script.on_event(defines.events.on_runtime_mod_setting_changed, handleModSettingsChanges)
-- (Doesn't handle runtime changes or changes from the main menu, unless another mod is enabled/diabled)
script.on_configuration_changed(handleConfigurationChanged)


-- on_load doesn't provide access to game.* functions,
-- and mod settings changed at the main menu don't seem to persist
-- onto already-created games...
-- The most we can really do is handle mod-comapability
script.on_load(
function()
  compat.Compatability_OnLoad()
end)



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


script.on_event(defines.events.on_selected_entity_changed,
function(event)
  local p = game.players[event.player_index]
  local entity = p.selected
  if entity and entity.force == p.force then
    if     entity.name == d.searchlightBaseName 
        or entity.name == d.searchlightSafeName
        or entity.name == d.searchlightAlarmName then
      local g = global.unum_to_g[entity.unit_number]
      if g then
        -- 'Wake' safe-mode'd searchlights so they update wander parameters
        cs.ReadWanderParameters(g, g.signal, g.signal.get_control_behavior())

        -- Shouldn't double draw if already drawn for whole force by above call
        rd.DrawSearchArea(entity, p, nil)
        
        rd.DrawTurtlePos(p, g)

        -- If player is holding a wire, hide the "can not connect" icon
        local cursorStack = p.cursor_stack
        if      cursorStack 
            and cursorStack.valid
            and cursorStack.valid_for_read then

          if     cursorStack.name == "red-wire"
              or cursorStack.name == "green-wire" then
                p.selected = g.signal
            return
          end
        end
      end
    end
  end
end)


-- On Tick
script.on_event(defines.events.on_tick,
function(event)
  local tick = event.tick

  -- Run seperate loops for gestalts vs turrets since they
  -- could possibly be in seperate electric networks
  cg.CheckElectricNeeds()
  cu.CheckAmmoElectricNeeds()

  cg.CheckGestaltFoes()

  if global.spotter_timeouts[tick] then
    cg.CloseWatch(global.spotter_timeouts[tick])
    global.spotter_timeouts[tick] = nil
  end

  for syncTick, list in pairs(global.animation_sync) do
    if tick == syncTick then
      cg.SyncReady(list)
      -- Should be safe to remove from table while iterating in lua      
      global.animation_sync[tick] = nil
    else
      cg.CheckSync(list)
    end
  end

  for pIndex, gAndGUI in pairs(global.pIndexToGUI) do
    local gID = gAndGUI[1]
    if cgui.validatePlayerAndLight(pIndex, gID) and cgui.validateGUI(gAndGUI[2]) then
      local g = global.gestalts[gID]
      cgui.updateOnTick(g, gAndGUI[2])
      -- Update the wander parameters, just in case this searchlight is in safe mode
      cs.ReadWanderParameters(g, g.signal, g.signal.get_control_behavior())
    else
      -- Should be safe to remove from table while iterating in lua
      cgui.CloseSearchlightGUI(pIndex)
    end
  end

  rd.Update(event.tick)
end)


-- Run twice a second (at 60 updates per second)
script.on_nth_tick(30,
function(event)

  cs.CheckCircuitConditions()

end)


-- Circuit conditions / GUI events
script.on_event(d.openSearchlightGUI, function(event)
  if event.selected_prototype 
    and (event.selected_prototype.name == d.searchlightBaseName 
      or event.selected_prototype.name == d.searchlightSafeName
      or event.selected_prototype.name == d.searchlightAlarmName
      or event.selected_prototype.name == d.searchlightSignalInterfaceName) then
    cgui.OpenSearchlightGUI(event.player_index, event.cursor_position)
  end
end)


script.on_event(d.closeSearchlightGUI, function(event)
  cgui.CloseSearchlightGUI(event.player_index)
end)


script.on_event(d.closeSearchlightGUIalt, function(event)
  cgui.CloseSearchlightGUI(event.player_index)
end)


script.on_event(defines.events.on_gui_click, function(event)
  if event.element and event.element.name == d.guiClose then
    cgui.CloseSearchlightGUI(event.player_index)
  end
end)


-- Close our GUI if something else opens
script.on_event(defines.events.on_gui_opened, function(event)
  cgui.CloseSearchlightGUI(event.player_index)
end)


script.on_event(defines.events.on_gui_text_changed, function(event)
  local gAndGUI = global.pIndexToGUI[event.player_index]
  if not gAndGUI then
    return
  end

  if     not cgui.validatePlayerAndLight(event.player_index, gAndGUI[1])
      or not cgui.validateGUI(gAndGUI[2]) then
    cgui.CloseSearchlightGUI(event.player_index)
    return
  end

  local g = global.gestalts[gAndGUI[1]]
  cgui.updateOnTextInput(g, gAndGUI[2])

  cs.ReadWanderParameters(g, g.signal, g.signal.get_control_behavior())
end)


-- On Script Trigger (turtle/spotter attack)
script.on_event(defines.events.on_script_trigger_effect,
function(event)
  if event.effect_id == d.spottedEffectID then
    if event.source_entity then
      cg.FoeSuspected(event.source_entity)
    end
  elseif event.effect_id == d.confirmedSpottedEffectID then
    if event.source_entity and event.target_entity then
      cg.FoeFound(event.source_entity, event.target_entity)
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
  local failed = event.result == defines.behavior_result.fail
  if event.was_distracted or failed then
    if failed then
      ct.TurtleFailed(g.turtle)
    end
  else
    ct.TurtleWaypointReached(g)
  end

end)


-- On Player Rotated
script.on_event(defines.events.on_player_rotated_entity,
function(event)
  local e = event.entity
  local tu = global.tun_to_tunion[e.unit_number]
  local g = global.unum_to_g[e.unit_number]

  if tu and tu.boosted then
    -- Detect if a player rotated a turret with an arc (eg, a flame turret)
    -- and check if it can still hit that foe.
    -- If it can target something in its new direction, it'll get reboosted in a moment.
    if not e.shooting_target then
      cu.UnBoost(tu)
    end
  elseif g then
    cs.Rotated(g, e, event.previous_direction, event.player_index)
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


--
-- BLUEPRINTS & GHOSTS
--

local function CopyCombinatorToSignalInterface(source, dest)
  local sourceParams = source.parameters

  for _, slotNum in pairs(pastableSignals) do
    local currSig = dest.get_signal(slotNum)
    currSig.count = 0
    
    for _, p in pairs(sourceParams) do
      if p.signal.name == currSig.signal.name and p.count then
        currSig.count = currSig.count + p.count
      end
    end

    dest.set_signal(slotNum, currSig)
  end
end


-- When the player sets up / configures a blueprint,
-- convert any boosted / alarm-mode entities
-- back to their base entity type
script.on_event(defines.events.on_player_setup_blueprint,      ci.ScanBP_StacksAndSwapToBaseType)
script.on_event(defines.events.on_player_configured_blueprint, ci.ScanBP_StacksAndSwapToBaseType)


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


script.on_event(defines.events.on_entity_settings_pasted,
function(event)
  local source = event.source
  local dest = event.destination

  if not source.valid and not source.unit_number then
    return
  end

  if not dest.valid and not dest.unit_number then
    return
  end

  local gDest = global.unum_to_g[dest.unit_number]

  if not gDest then
    return
  end

  if source.name == "constant-combinator" then
    CopyCombinatorToSignalInterface(source.get_control_behavior(), 
                                    gDest.signal.get_control_behavior())
  else
    local gSource = global.unum_to_g[source.unit_number]

    if not gSource then
      return
    end

    local sourceC = gSource.signal.get_control_behavior()
    local destC = gDest.signal.get_control_behavior()
    for _, slotNum in pairs(pastableSignals) do
      destC.set_signal(slotNum, sourceC.get_signal(slotNum))
    end      
  end
end)


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
