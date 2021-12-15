local mod_gui = require("mod-gui")


local script_data =
{
  finished = {},
  spaced = {},
  removed_old_gui = true
}


local remove_old_frame = function(player)
  local gui = mod_gui.get_frame_flow(player)
  local frame = gui.silo_gui_frame
  if frame then frame.destroy() end
end


local remove_old_button = function(player)
  local button_flow = mod_gui.get_button_flow(player)
  local button = button_flow.silo_gui_sprite_button
  if button then button.destroy() end
end


local remove_old_gui = function()
  for k, player in pairs (game.players) do
    remove_old_frame(player)
    remove_old_button(player)
  end
end


local insertArtilleryShell = function()
  for k, player in pairs(game.forces["Smugglers"].players) do
    local inv = player.get_main_inventory()
    if inv.get_item_count("artillery-shell") < 30 then
      inv.insert({name = "artillery-shell", count = 1})
    end
  end
end


local on_built_entity = function(event)
  local e = event.created_entity
  if e.force.name == "Smugglers" and e.name == "spidertron" then
    e.minable = false
    
    firepos = e.position
    firepos.x = firepos.x - 0.3
    pos = e.position
    pos.y = pos.y + 0.6
    
    chest = e.surface.create_entity{name = "crash-site-chest-2", position = pos, force = "Smugglers"}
    chest.get_inventory(defines.inventory.chest).insert({name="repair-pack", count=1})
    
    local box = chest.bounding_box
    for k, entity in pairs (e.surface.find_entities_filtered{area = box, collision_mask = "player-layer"}) do
      if entity.valid then
        if entity ~= chest and entity ~= e then
          entity.die()
        end
      end
    end
    
    box.left_top.x = box.left_top.x - 1.2
    box.left_top.y = box.left_top.y - 1.2
    box.right_bottom.x = box.right_bottom.x + 1.2
    box.right_bottom.y = box.right_bottom.y + 1.2
    for k, entity in pairs (e.surface.find_entities_filtered{area = box, collision_mask = "player-layer"}) do
      if entity.valid then
        entity.damage(200, "neutral")
      end
    end
    
    e.surface.create_entity{name = "crash-site-fire-flame", position = firepos}
    e.surface.create_entity{name = "crash-site-fire-smoke", position = firepos}
    e.surface.create_entity{name = "big-artillery-explosion", position = pos}
  end
end


local on_driving_changed_state = function(event)
  local player = game.players[event.player_index]
  
  if player.force.name ~= "Smugglers" then
    return
  end
  
  local remoteCount = player.get_main_inventory().get_item_count("artillery-targeting-remote")

  if player.driving then
    if remoteCount == 0 then
      player.get_main_inventory().insert({name = "artillery-targeting-remote", count = 1})
    end
  else
    player.get_main_inventory().remove({name = "artillery-targeting-remote", count = remoteCount})
  end
end


local on_inv_changed = function(event)
  local player = game.players[event.player_index]
  
  if player.force.name ~= "Smugglers" then
    return
  end
  
  local remoteCount = player.get_main_inventory().get_item_count("artillery-targeting-remote")

  if not player.driving and remoteCount > 0 then
    player.get_main_inventory().remove({name = "artillery-targeting-remote", count = remoteCount})
  end
end


local on_rocket_launched = function(event)

  if global.no_victory then return end

  local rocket = event.rocket
  if not (rocket and rocket.valid) then return end

  local force = rocket.force
  
  script_data.finished = script_data.finished or {}
  if script_data.finished[force.name] then
    return
  end
  
  script_data.spaced = script_data.spaced or {}
    
  if not event.player_index then
    if not script_data.spaced["No passenger"] then
      script_data.spaced["No passenger"] = true
      game.print("Rocket launched with no passenger")
      game.print("... Don't you want to leave before it's too late?")
    end
    return
  end
    
  spacedPlayer = game.players[event.player_index]
  script_data.spaced[spacedPlayer.index] = true
  
  spacedPlayer.force = "Smugglers"
  spacedPlayer.show_on_map = false
  spacedPlayer.clear_items_inside()
  spacedPlayer.character.destroy()
  
  spacedPlayer.clear_items_inside()  
  spacedPlayer.set_active_quick_bar_page(1, 3)
  spacedPlayer.set_active_quick_bar_page(2, 4)
  
  spacedPlayer.set_quick_bar_slot(21, "artillery-targeting-remote")
  spacedPlayer.set_quick_bar_slot(22, "artillery-shell")
  spacedPlayer.set_quick_bar_slot(23, "spidertron")
  
  for i = 24, 40 do 
    spacedPlayer.set_quick_bar_slot(i, nil)
  end
  
  spacedPlayer.get_main_inventory().insert({name = "spidertron", count = 1})
  spacedPlayer.print("[Orbital Control]: Munitions Reload Initiated")
  spacedPlayer.print("[Orbital Control]: Remote Access Granted")
  spacedPlayer.print("[Orbital Control]: Spidertron Drop-Pod Granted")
  spacedPlayer.print("[Orbital Control]: Artillery Control Linked To Spidertron. Good hunting, " .. spacedPlayer.name)
  
  game.forces["Smugglers"].disable_research()
  game.forces["Smugglers"].disable_all_prototypes()
  game.forces["Smugglers"].manual_mining_speed_modifier = -1
  
  if #game.forces["Smugglers"].players ~= #game.players then
    return
  end
  
  script_data.finished[force.name] = true

  game.set_game_state
  {
    game_finished = true,
    player_won = true,
    can_continue = true,
    victorious_force = force
  }

end


local add_remote_interface = function()
  if not remote.interfaces["silo_script"] then
    remote.add_interface("silo_script",
    {
      set_no_victory = function(bool)
        if type(bool) ~= "boolean" then error("Value for 'set_no_victory' must be a boolean") end
        global.no_victory = bool
      end
    })
  end
end
add_remote_interface()


local silo_script = {}


silo_script.events =
{
  [defines.events.on_player_driving_changed_state] = on_driving_changed_state,
  [defines.events.on_rocket_launched] = on_rocket_launched,
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_player_main_inventory_changed] = on_inv_changed,
}


silo_script.on_nth_tick = 
{
  [5400] = insertArtilleryShell
}

silo_script.on_configuration_changed = function()
  if not script_data.removed_old_gui then
    script_data.removed_old_gui = true
    script_data.tracked_items = nil
    remove_old_gui()
    log("Remove the old silo script GUI")
  end
  script_data.finished = script_data.finished or {}
  script_data.spaced = script_data.spaced or {}
end


silo_script.on_init = function()
  global.silo_script = global.silo_script or script_data
end


silo_script.on_load = function()
  script_data = global.silo_script or script_data
end


silo_script.get_events = function()
  --legacy
  return silo_script.events
end


silo_script.add_remote_interface = function()
  --legacy
  add_remote_interface()
end


silo_script.add_commands = function()
  --legacy
end


return silo_script
