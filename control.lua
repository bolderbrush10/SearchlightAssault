require "control-common"
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

  CheckForFoesNearSL(event.tick)

  DecrementBoostTimers(event.tick)

  DEBUGTOOL(event.tick) -- TODO Remove
end)


-- On Force Created
script.on_event(defines.events.on_force_created,
function(event)

  if event.force.name ~= searchlightFriend and event.force.name ~= searchlightFoe then
    SetCeaseFires(event.force)
  end

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
    AddSearchlight(event.created_entity)
  end

  -- TODO other functions for turrets

end)


-- Via Robot
script.on_event(defines.events.on_robot_built_entity,
function(event)

  AddSearchlight(event.created_entity)

end)


-- Via Script
script.on_event(defines.events.script_raised_built,
function(event)

  AddSearchlight(event.created_entity)

end)


-- Via Revived by Script
script.on_event(defines.events.script_raised_revive,
function(event)

  AddSearchlight(event.created_entity)

end)

--
-- DESTRUCTIONS
--

-- Via Player
script.on_event(defines.events.on_pre_player_mined_item,
function(event)

  if event.entity.name == searchlightBaseName then
    RemoveSearchlight(event.entity)
  end

end)


-- Via Robot
script.on_event(defines.events.on_robot_mined_entity,
function(event)

  RemoveSearchlight(event.entity)

end)


-- Via Damage
script.on_event(defines.events.on_entity_died,
function(event)

  if event.entity.name == searchlightBaseName then
    RemoveSearchlight(event.entity)
  end


  -- TODO if this was a biter / etc, then we could probably check
  --      whether relevant boosted turrets are still allowed to be boosted
  -- On the other hand... turrets probably acquire new shooting targets
  -- long before their bullets actually reach their final destination...
end)


-- Via Script
script.on_event(defines.events.script_raised_destroy,
function(event)

  RemoveSearchlight(event.created_entity)

end)


--
-- Manually render spotlight range on mouseover / held in cursor
--

-- local renderID = nil

-- script.on_event(defines.events.on_selected_entity_changed,
-- function(event)

--   local player = game.players[event.player_index]
--   if player.selected and not renderID then
--     renderID = renderRange(player, player.selected)
--     game.print("rendering " .. renderID)
--   elseif renderID then
--     game.print("destroying " .. renderID)
--     rendering.destroy(renderID)
--     renderID = nil
--   end

-- end)

-- script.on_event(defines.events.on_player_cursor_stack_changed,
-- function(event)

--   local player = game.players[event.player_index]
--   if player.cursor_stack.valid_for_read then
--     -- and player.cursor_stack.name == searchlightItemName

--     renderRange(game.players[event.player_index], player.cursor_position)
--   end

-- end)


-- -- target can either be a position or an entity
-- function renderRange(player, target)

--   return rendering.draw_circle{color={0.8, 0.1, 0.1, 0.5},
--                                radius=5,
--                                filled=true,
--                                target=target,
--                                target_offset={0,0},
--                                surface=player.surface,
--                                time_to_live=0,
--                                players={player},
--                                draw_on_ground=true}

-- end


--
-- Misc
--

-- On Command Completed
script.on_event(defines.events.on_ai_command_completed,
function(event)
  -- TODO ConsiderTurtle(event.unit_number)

  -- Contains
  -- unit_number :: uint: unit_number/group_number of the unit/group which just completed a command.
  -- result :: defines.behavior_result
  -- was_distracted :: boolean: Was this command generated by a distraction.

end)


-- Manual debug tool, triggered by typing anything into the console
-- TODO remove
script.on_event(defines.events.on_console_command,
function (event)
  if game.players[1].selected then
    game.players[1].selected.active = not game.players[1].selected.active
    game.players[1].selected.destructible = true
    game.print("toggled active")
  else
    game.print("nothing selected")
  end
end)


-- Automatic debug tool, triggered every tick
-- TODO remove
function DEBUGTOOL(tick)
  -- if game.players[1].selected then
  --   rendering.draw_circle{color={0.8, 0.1, 0.1, 0.5}, radius=5, filled=true, target=game.players[1].selected, target_offset={0,0}, surface=game.players[1].surface, time_to_live=2, players={game.players[1]}, draw_on_ground=true}
  -- end
end