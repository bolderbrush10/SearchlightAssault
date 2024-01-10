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

local public = {}
return public
