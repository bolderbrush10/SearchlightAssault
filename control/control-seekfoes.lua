

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


local public = {}
return public
