local d = require "sl-defines"
local u = require "sl-util"

require "control-common"

-- The 'turtle' force exists to hold an imaginary target (The 'Turtle')
-- for spotlights to 'shoot' while they scan around for enemy units.

-- This turtle force also needs to 'attack' any foes of the spotlight's owner
-- to trigger a function call that will let us know we've spotted an enemy.

-- For multiplayer compatiblity, we create a turtle force for any force
-- that builds a spotlight and update relationships accordingly.


-- Called when a new spotlight is created
function PrepareTurtleForce(SpotlightForce)
  local turtleForceName = SpotlightForce.name .. d.turtleForceSuffix

  if global.sl_force_init[turtleForceName] then
    return turtleForceName -- We've already initialized this force, nothing to do
  end

  game.create_force(turtleForceName)
  global.sl_force_init[turtleForceName] = true

  UpdateTForceRelationships(SpotlightForce)

  return turtleForceName
end


-- When something (another mod, most likely) creates a new force,
-- or updates a relationship, reflect those relations in the turtle force.
-- The turtle force should ignore the spotlight's friends and attack its enemies.
-- Only the spotlight owner should have cease_fire = false with its turtle.
-- Everyone else should ignore it.
function UpdateTForceRelationships(SpotlightForce)

  if u.EndsWith(SpotlightForce.name, d.turtleForceSuffix) then
    return -- Don't recurse
  end

  local turtleForceName = SpotlightForce.name .. d.turtleForceSuffix

  if global.sl_force_init[turtleForceName] == nil then
    return -- Don't recurse
  end

  local tForce = game.forces[turtleForceName]

  -- The owner force needs to have cease_fire == false toward the turtle force.
  -- Otherwise, spotlights won't target turtles under any circumstances
  -- (Make the turtle itself invulnerable and things will ignore it by default,
  --  then we can use .set_shooting_target to get the spotlight to attack)
  SpotlightForce.set_cease_fire(tForce, false)
  SpotlightForce.set_friend(tForce, false)
  -- Turtles, naturally, shouldn't attack their spotlight-owner force
  tForce.set_cease_fire(SpotlightForce, true)
  tForce.set_friend(SpotlightForce, false)

  for _, f in pairs(game.forces) do

    if f.name == turtleForceName then
      ;
    elseif f.name == SpotlightForce.name then
      ;
    elseif u.EndsWith(f.name, d.turtleForceSuffix) then
      -- Turtles should always ignore other turtles
      -- (Otherwise, two turtles from allied forces might fight in the middle of nowhere)
      f.set_cease_fire(tForce, true)
      f.set_friend(tForce, false)

      tForce.set_cease_fire(f, true)
      tForce.set_friend(f, false)
    else

      f.set_cease_fire(tForce, true)
      f.set_friend(tForce, false)

      -- Since friend relationships overrule cease_fire = false,
      -- we need to mirror them as well.
      tForce.set_friend(f, SpotlightForce.get_friend(f))
      tForce.set_cease_fire(f, SpotlightForce.get_cease_fire(f))

    end

  end

end


function MigrateTurtleForces(oldSLForce, newSLForce)
  -- Don't recurse when we migrate turtles
  if u.EndsWith(oldSLForce.name, d.turtleForceSuffix) then
    return
  end

  local oldtForceName = oldSLForce.name .. d.turtleForceSuffix

  -- If there's no associated turtle force, nothing to do
  if global.sl_force_init[oldtForceName] == nil then
    return
  end

  global.sl_force_init[oldtForceName] = nil
  local newtForceName = PrepareTurtleForce(newSLForce)

  -- The API says nested merge_forces will happen next tick,
  -- but that should be fine, I think...
  game.merge_forces(oldtForceName, newtForceName)
end
