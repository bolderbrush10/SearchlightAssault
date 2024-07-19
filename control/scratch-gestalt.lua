
-- Tiny optimization, reduces calls to global table
-- Not quite as fast as declaring locally in a function,
-- but our loops should usually be fairly small...
local pairs = pairs
local next  = next


function BoostFriends(gestalt, spottedFoe)
  local gtRelations = global.GestaltTunionRelations

  for tID, _ in pairs(r.getRelationLHS(gtRelations, gestalt.gID)) do
    local tu = global.tunions[tID]
    if not tu.boosted and tu.turret.shooting_target == nil then
      cu.Boost(tu, spottedFoe)
    end
  end
end


function ResumeTargetingTurtle(g, turtlePositionToResume)
  ct.ResumeTurtleDuty(g, turtlePositionToResume)
  g.light.shooting_target = g.turtle
end


function EnterAlarmMode(g, spottedFoe)
  SpawnAlarmLight(g)

  -- No need to keep firing the spotter while we're targeting a foe
  -- (in fact, we don't want it to fire and kick us back to warn mode)
  g.spotter.active = false

  r.setRelation(global.FoeGestaltRelations, spottedFoe.unit_number, g.gID, spottedFoe)

  g.light.shooting_target = spottedFoe
  g.turtle.teleport(spottedFoe.position)
  ct.TurtleChase(g, spottedFoe)
  cs.ProcessAlarmRaiseSignals(g)

  BoostFriends(g, spottedFoe)

  cgui.updateOnEntity(g)
end


function EnterWarnMode(g, escapedFoe)
  if g.light.name == d.searchlightBaseName then
    return -- Alarm already cleared
  end

  -- If we were spinning around in safe mode,
  -- match up our orientation to that spin so
  -- it looks smoother when we retarget the turtle
  local val = nil
  if g.light.shooting_target and g.light.shooting_target == g.spotter then
    val = ((game.tick % d.spinFactor) / d.spinFactor)
  end

  SpawnBaseLight(g)

  if val then
    g.light.orientation = val
  end

  g.spotter.active = true

  -- If the spotter doesn't fire again by this time,
  -- we'll go back to safe mode
  export.OpenWatch(g.gID)

  global.check_power[g.gID] = g

  if escapedFoe then
    ResumeTargetingTurtle(g, escapedFoe.position)
  else
    ResumeTargetingTurtle(g, nil)
  end

  cs.ProcessAlarmClearSignals(g, game.tick)

  cgui.updateOnEntity(g)
end


function EnterSafeMode(g)
  if g.light.name == d.searchlightSafeName then
    return -- Already in safe mode
  end

  SpawnSafeLight(g)

  g.turtle.active = false
  g.light.shooting_target = g.spotter

  cs.ProcessSafeSignals(g)

  global.check_power[g.gID] = nil

  cgui.updateOnEntity(g)
end


function EnterSafeModeSync(g)
  g.turtle.active = false
  local light = g.light
  light.shooting_target = g.spotter

  local tickd.turnDelay = game.tick + d.turnDelay
  if not global.animation_sync[tickd.turnDelay] then
    global.animation_sync[tickd.turnDelay] = {}
  end

  table.insert(global.animation_sync[tickd.turnDelay], g.gID)
end


----------------------
--  On Tick Events  --
----------------------


-- Wouldn't need this function if there was an event for when entities run out of power
function CheckElectricNeeds()
  -- Not happy about having to add this loop,
  -- but too many other mods have been blowing up our turtles somehow,
  -- so we have to do this.
  for _, g in pairs(global.gestalts) do
    if not g.turtle.valid then

      -- Something nuked our mod's turtle, gotta try to respawn it now
      if not ct.RespawnBrokenTurtle(g) then
        -- Somehow the respawn failed, so just blow up the whole searchlight

        g.light.die() -- The on_death() event won't happen until long after this function,
                      -- so clean it up now so we don't iterate over a dead light below

        -- (It should be safe in lua to remove from a table while iterating)
        export.SearchlightRemoved(nil, false, g)
      end
    end
  end

  for _, g in pairs(global.check_power) do
    if g.light.valid and g.signal.valid then
      g.turtle.active = g.light.energy > 0
    else
      -- Something nuked our mod's searchlight, gotta remove it now
      -- (It should be safe in lua to remove from a table while iterating)
      export.SearchlightRemoved(nil, false, g)
    end
  end
end


-- Every tick, check that all spotlights are shooting at sanctioned foes,
-- and check if any unboosted turrets have been freed up & try boosting them.
-- (Heavy logic only runs while a foe is spotted, so not too performance-impacting)
-- (Boosted turrets will seek new gestalt-targets on their own before unboosting)
function CheckGestaltFoes()
  if r.empty(global.FoeGestaltRelations) then
    return
  end

  local fgRelations = global.FoeGestaltRelations
  for fun, gIDs in pairs(r.getRelationMatrix(fgRelations)) do
    for gID, foe in pairs(gIDs) do
      local g = global.gestalts[gID]

      if     not foe.valid
          or g.light.shooting_target == nil
          or g.light.shooting_target.unit_number ~= fun then

        if foe.valid then
          -- Retarget turtle, teleport turtle to roughly the foe's location
          EnterWarnMode(g, foe)
        else
          EnterWarnMode(g, g.turtle)
        end

        -- In lua, it's usually safe to remove from a table while iterating
        -- (If you're nil'ing entries while using pairs())
        -- (But not safe to add into a table)
        r.removeRelation(fgRelations, fun, gID)
        cu.FoeGestaltRelationRemoved(g)

      else
        BoostFriends(g, foe)
      end
    end
  end

end


------------------------
--  Aperiodic Events  --
------------------------


function FoeDied(foe)
  local fgRelations = global.FoeGestaltRelations
  local gestalts = global.gestalts
  local gIDs = r.popRelationLHS(fgRelations, foe.unit_number)

  for gID, _ in pairs(gIDs) do
    EnterWarnMode(gestalts[gID], foe)
    cu.FoeGestaltRelationRemoved(gestalts[gID])
  end

end



function FoeFound(turtle, foe)
  -- If something's in a vehicle, target the driver instead of the vehicle
  local foeOrDriver = u.CheckEntityOrDriver(foe)
  if not foeOrDriver then
    return
  end

  local g = global.unum_to_g[turtle.unit_number]

  EnterAlarmMode(g, foe)
end


function FoeSuspected(spotter)
  local g = global.unum_to_g[spotter.unit_number]
  if not g then
    return
  end

  g.lastSpotted = game.tick
  export.OpenWatch(g.gID)

  if g.light.energy > 0 then
    -- Leave safe mode, start hunting for foes
    EnterWarnMode(g, nil)
  end
end


function OpenWatch(gID)
  local tickToClose = game.tick + d.searchlightSafeTime
  -- Align to base_picture rotation so we transition smoothly
  tickToClose = tickToClose + (d.spinFactor - (tickToClose % d.spinFactor))
  tickToClose = tickToClose + (d.spinFactor * 0.25) - d.turnDelay

  if not global.spotter_timeouts[tickToClose] then
    global.spotter_timeouts[tickToClose] = {}
  end

  table.insert(global.spotter_timeouts[tickToClose], gID)
end


-- If our watch has expired with no foes in range, then go back to safe mode
function CloseWatch(gIDs)
  local tick = game.tick

  for _, gID in pairs(gIDs) do
    local g = global.gestalts[gID]

    -- Check if our searchlight was destroyed in the ticks since the watch was opened
    if g and g.light.name == d.searchlightBaseName then

      if     not g.lastSpotted 
          or (tick - g.lastSpotted) >= d.searchlightSafeTime then
        if g.light.energy > 0 then
          EnterSafeModeSync(g)
        else
          -- If we're out of power, try again later
          export.OpenWatch(gID)
        end
      -- else
        -- Another watch-tick was already opened for whenever the last foe-spotting was
      end
    end
  end
end


function SyncReady(gIDs)
  for _, gID in pairs(gIDs) do
    local g = global.gestalts[gID]

    if g then
      EnterSafeMode(g)
    end
  end
end


-- If a searchlight has reached the desired orientation,
-- disable the spotlight effect from rendering on the spotter, which looks ugly
function CheckSync(gIDs)
  for _, gID in pairs(gIDs) do
    local g = global.gestalts[gID]

    if g then
      local light = g.light
      -- The light will be renabled in a few ticks in EnterSafeMode() by the spawn(), don't worry
      if light.orientation > 0.2 and light.orientation < 0.3 then
        light.active = false
      end
    end
  end
end
