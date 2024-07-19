

--------------------
--  Helper Funcs  --
--------------------


-- valid directions: 0 - 7
-- Normally, players rotate things in increments of 2 (90 degrees),
-- so we'll roll that back by one unit to get 45 degree changes.
-- We can compare oldDir to the current direction to figure out
-- whether the player is rotating clockwise or counterclockwise.
function RotateDirByOne(g, light, oldDir)
  local newDir = light.direction

  -- Detect clockwise looparound
  if oldDir == 6 and newDir == 0 then
    return 45
  end
  if oldDir == 7 and newDir == 1 then
    return 45
  end

  -- Detect counter-clockwise looparound
  if oldDir == 0 and newDir == 6 then
    return -45
  end
  if oldDir == 1 and newDir == 7 then
    return -45
  end

  -- Detect clockwise procession
  if oldDir < newDir then
    return 45
  end

  -- counterclockwise is the only remaining case
  return -45
end


--------------------
--     Events     --
--------------------




function Rotated(g, light, oldDir, pIndex)
  if not g.tWanderParams then
    g.tWanderParams = {}
  end
  if not g.tWanderParams.rotation then
    g.tWanderParams.rotation = 0
  end

  local newRot = RotateDirByOne(g, light, oldDir)

  ct.UpdateWanderParams(g, g.tWanderParams.radius, g.tWanderParams.rotation + newRot, 
                        g.tWanderParams.min, g.tWanderParams.max)
  rd.DrawSearchArea(g.light, nil, g.light.force)

  local control = g.signal.get_control_behavior()
  local sig = control.get_signal(d.circuitSlots.rotateSlot)

  -- We'll clamp the value down here so we don't try to factor in circuit signals
  sig.count = u.clampDeg(sig.count + newRot, 0, true)
  control.set_signal(d.circuitSlots.rotateSlot, sig)

  -- If there's a direct waypoint set, go ahead and rotate that
  if     g.tState == ct.MOVE 
      or g.tWanderParams.radius == 360 
      or g.tWanderParams.radius == 0 then
    if g.tState == ct.MOVE then
      local distSq = u.lensquared(u.TranslateCoordinate(g, g.tCoord), light.position)

      local theta = math.atan2(g.tCoord.y, g.tCoord.x)
      newCoord = u.ScreenOrientationToPosition(light.position, theta + newRot, math.sqrt(distSq))

      local dirX = control.get_signal(d.circuitSlots.dirXSlot)
      local dirY = control.get_signal(d.circuitSlots.dirYSlot)
      dirX.count = newCoord.x - light.position.x
      dirY.count = newCoord.y - light.position.y

      control.set_signal(d.circuitSlots.dirXSlot, dirX)
      control.set_signal(d.circuitSlots.dirYSlot, dirY)
    else
      local distSq = u.lensquared(g.turtle.position, light.position)
      local theta = (g.tWanderParams.rotation*math.pi)/180

      newCoord = u.ScreenOrientationToPosition(light.position, theta, math.sqrt(distSq))

      ct.WanderTurtle(g, newCoord)
    end
  end

  local player = game.players[pIndex]
  if player and player.valid then
    cgui.Rotated(g) -- Treat rotation like it was a text input
  end
end
