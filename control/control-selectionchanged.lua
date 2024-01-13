----------------------------------------------------------------
  -- forward declarations
  local onChange
----------------------------------------------------------------

script.on_event(defines.events.on_selected_entity_changed, sc.onChange)


function onChange(event)
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
end


----------------------------------------------------------------
  local public = {}
  public.onChange = onChange
  return public
----------------------------------------------------------------
