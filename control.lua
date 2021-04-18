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

  -- CheckForFoesNearSL(event.tick)

  DecrementBoostTimers(event.tick)

  DEBUGTOOL(event.tick) -- TODO Remove
end)


script.on_event(defines.events.on_script_trigger_effect,
function(event)
  -- if event.effect_id == spottedEffectID then
  --   FoeSpotted(event.source_entity, event.target_entity)
  --   if event.target_entity.unit_number then
  --     game.print("attacking: " .. event.target_entity.unit_number)
  --   else
  --     game.print("attacking something with no unit_number")
  --   end
  -- end
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

  -- game.print("command completed by unit number " .. event.unit_number)
  -- game.print("was distracted: " .. (event.was_distracted and "true" or "false"))
  if event.was_distracted then
    game.print("was distracted: true")
    game.print("result: " .. event.result)
  end

end)


-- Manual debug tool, triggered by typing anything into the console
-- TODO remove
script.on_event(defines.events.on_console_command,
function (event)
  -- p = game.players[1]
  -- if p.selected then
  --   entities = p.surface.find_entities_filtered{position=p.selected.position, radius=5}
  --   if entities then
  --     game.print("count: " .. #entities)
  --     for i, e in pairs(entities) do
  --       if e.type == "unit" and e.spawner then
  --         game.print("ename: " .. e.name .. " and spawner: " .. e.spawner.name)
  --       else
  --         game.print("ename: " .. e.name .. " but no spawner")
  --       end
  --     end

  --   else
  --     game.print("nil")
  --   end
  -- else
  --   game.print("nothing selected")
  -- end
end)

local turt = nil
-- Automatic debug tool, triggered every tick
-- TODO remove
function DEBUGTOOL(tick)
  -- if not turt then
  --   p = game.players[1]
  --   res = p.surface.find_entities_filtered{name=turtleName}
  --   if res[1] then
  --     turt = res[1]
  --   else
  --     return
  --   end
  -- end

  -- if turt.command then
  --   game.print("turt command: " .. turt.command.type)
  --   if turt.command.type == defines.command.attack then
  --     game.print("target: " .. turt.command.target.name)
  --   end
  -- else
  --   game.print("no command")
  -- end
  -- if turt.distraction_command then
  --   game.print("turt distraction: " .. turt.distraction_command.type)
  --   if turt.distraction_command.type == defines.command.attack then
  --     game.print("target: " .. turt.distraction_command.target.name)
  --   end
  -- else
  --   game.print("no distraction")
  -- end





  -- if game.players[1].selected then
  --   rendering.draw_circle{color={0.8, 0.1, 0.1, 0.5}, radius=5, filled=true, target=game.players[1].selected, target_offset={0,0}, surface=game.players[1].surface, time_to_live=2, players={game.players[1]}, draw_on_ground=true}
  -- end
end