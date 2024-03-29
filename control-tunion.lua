local ca = require "control-ammo"

local d = require "sl-defines"
local r = require "sl-relation"
local u = require "sl-util"


local export = {}


-- boostInfo states (Shared with control-blocklist)
local UNBOOSTED     = 0
local BOOSTED       = 1
local BLOCKED       = 2
local NOT_BOOSTABLE = 3

export.bInfo = {}
export.bInfo.UNBOOSTED     = UNBOOSTED
export.bInfo.BOOSTED       = BOOSTED
export.bInfo.BLOCKED       = BLOCKED
export.bInfo.NOT_BOOSTABLE = NOT_BOOSTABLE


------------------
-- Turret Union --
------------------
--[[
{
  tuID    = int (tuID),
  turret  = base / boosted,
  boosted = true / false,
  control = entity / nil,
  boostAnimation = renderID / nil,
}
]]--

export.InitTables_Turrets = function()

  global.tuID = 0

  -- Map: turret union ID -> TUnion
  global.tunions = {}

  -- Map: turret unit_number -> TUnion
  global.tun_to_tunion = {}

  -- Map: tuID -> TUnion
  global.boosted_to_tunion = {}

  -- Map: turret name -> BOOSTED / UNBOOSTED / BLOCKED / NOT_BOOSTABLE
  global.boostInfo = {}

  ca.InitTables_Ammo()
end


------------------------
--  Helper Functions  --
------------------------


local function newTUID()
  global.tuID = global.tuID + 1
  return global.tuID
end


-- May return nil if turret is not boostable / already has tunion
local function makeTUnionFromTurret(turret)
  if global.tun_to_tunion[turret.unit_number] then
    return nil
  end

  local bInfo = global.boostInfo[turret.name]

  if bInfo == NOT_BOOSTABLE then
    return nil
  end

  local tunion = {tuID = newTUID(),
                  turret = turret,
                  boosted = (bInfo == BOOSTED)}

  global.tunions[tunion.tuID] = tunion
  global.tun_to_tunion[turret.unit_number] = tunion

  return tunion
end


local function getTuID(turret)
  if not global.tun_to_tunion[turret.unit_number] then
    return makeTUnionFromTurret(turret).tuID
  end

  return global.tun_to_tunion[turret.unit_number].tuID
end


local function ReassignTurret(turret, tuID)
  local gtRelations = global.GestaltTunionRelations
  local checkAmmoRange = not settings.global[d.overrideAmmoRange].value

  for gID, _ in pairs(r.getRelationRHS(gtRelations, tuID)) do
    local g = global.gestalts[gID]
    -- Check light.valid here because this could get called 
    -- while checking if the map editor failed to fire an event
    if g.light.valid then
      local gtarget = g.light.shooting_target
      if  gtarget 
          and gtarget.valid 
          and gtarget.unit_number ~= g.turtle.unit_number
          and u.IsPositionWithinTurretArc(gtarget.position, turret, checkAmmoRange) then

        turret.shooting_target = gtarget
        return true

      end
    end
  end

  return false
end


local function SpawnControl(turret)
  local width = turret.bounding_box.right_bottom.x - turret.bounding_box.left_top.x
  local pos   = turret.bounding_box.right_bottom

  -- Slightly randomizing the position to add visual interest,
  -- staying near the bottom edge of the entity, varying around ~80% of its width.
  -- (math.random(x, y) doesn't return a float, so we'll add our product to math.random() which does)
  -- (math.random(x, y) crashes when given positions too close, so check variance before using)
  local xVar = math.abs((0) - (width - 0.2))
  local xRand = 0
  if xVar >= 1 then
    xRand = math.random((0),  (width - 0.2))
  end

  pos.x = pos.x - 0.2 - xRand
  pos.y = pos.y - 0.1 + math.random()/8

  local scorchPos = {x,y}
  scorchPos.x = pos.x
  scorchPos.y = pos.y + 0.27

  -- This scorchmark comes with a short time to live and will clean itself up
  turret.surface.create_entity{name = "sl-tiny-scorchmark-tintable", position = scorchPos}

  local control = turret.surface.create_entity{name = d.searchlightControllerName,
                                               position = pos,
                                               force = turret.force,
                                               create_build_effect_smoke = true}

  -- Explosions clean themselves up after they're done playing, so that's nice
  turret.surface.create_entity{name = "rock-damaged-explosion", position = pos}
  turret.surface.create_entity{name = "rock-damaged-explosion", position = pos}

  control.destructible = false

  return control
end


local function SpawnBoostAnimation(turret)
  local boostHazeSize = 200 / 32 -- 32 pixels per tile
  local cBox = turret.prototype.collision_box
  local tWidth = cBox.left_top.x - cBox.right_bottom.x
  local tHeight = cBox.left_top.y - cBox.right_bottom.y
  return rendering.draw_animation{animation=d.boostHaze, 
                                  target=turret.position, 
                                  surface=turret.surface,
                                  x_scale=(tWidth+12)/boostHazeSize,
                                  y_scale=(tHeight+12)/boostHazeSize,
                                  render_layer="radius-visualization",
                                  time_to_live=0
                                 }
end


local function AmplifyRange(tunion, foe)
  if  tunion.boosted
     or global.boostInfo[tunion.turret.name] ~= UNBOOSTED
     or global.boostInfo[tunion.turret.name .. d.boostSuffix] == nil
     or global.boostInfo[tunion.turret.name .. d.boostSuffix] ~= BOOSTED then

    return

  end

  local checkAmmoRange = not settings.global[d.overrideAmmoRange].value
  local turret = tunion.turret

  if not (turret.valid and u.IsPositionWithinTurretArc(foe.position, turret, checkAmmoRange)) then
    return
  end

  local newT = turret.surface.create_entity{name = turret.name .. d.boostSuffix,
                                            position = turret.position,
                                            force = turret.force,
                                            direction = turret.direction,
                                            fast_replace = false,
                                            create_build_effect_smoke = false}

  u.CopyTurret(turret, newT)
  tunion.boosted = true
  tunion.turret  = newT
  global.tun_to_tunion[newT.unit_number] = tunion
  global.tun_to_tunion[turret.unit_number] = nil
  turret.destroy()
  -- Don't raise script_raised_destroy since we're trying to do a swap-in-place,
  -- not actually "destroy" the entity (We'll put the original back soon
  -- (albeit with a new unit_number...))
  -- On the other hand, what if the other mod has its own hidden entities
  -- mapped to what we're destroying? We're messing up their unit_number too...
  -- Would we be better off just setting active=false on the original entity
  -- and somehow hiding it / synchronizing its movement & firing animations?

  newT.shooting_target = foe

 return newT
end


local function DeamplifyRange(tunion)
  local turret = tunion.turret

  if not turret.valid or not tunion.boosted then
    return
  end

  local newT = turret.surface.create_entity{name = turret.name:gsub(d.boostSuffix, ""),
                                            position = turret.position,
                                            force = turret.force,
                                            direction = turret.direction,
                                            fast_replace = false,
                                            create_build_effect_smoke = false}

  u.CopyTurret(turret, newT)
  tunion.boosted = false

  tunion.turret  = newT
  global.tun_to_tunion[newT.unit_number] = tunion
  global.tun_to_tunion[turret.unit_number] = nil
  turret.destroy()
  -- As with AmplifyRange(), don't raise script_raised_destroy

  ca.UnBoostAmmo(newT)

  return newT
end


----------------------
--  On Tick Events  --
----------------------


-- Wouldn't need most of this function if there was an event for when entities run out of power
export.CheckAmmoElectricNeeds = function()
  local overrideAmmoRange = settings.global[d.overrideAmmoRange].value

  for tuID, tu in pairs(global.boosted_to_tunion) do
    local turret = tu.turret
    local foe = tu.foe
    
    -- Some mods put a limited range on ammo, so check for that here
    if turret.shooting_target and 
      not u.IsPositionWithinTurretArc(turret.shooting_target.position, turret, (not overrideAmmoRange)) then
      export.UnBoost(tu)
    elseif not foe or not foe.valid then
      if not ReassignTurret(turret, tuID) then
        export.UnBoost(tu)
      end
    elseif tu.control.energy > 5000 then
      AmplifyRange(tu, foe) -- will invalidate reference to turret
      if overrideAmmoRange then
        ca.AuditBoostedAmmo(tu.turret)
      end
    elseif tu.control.energy < 100 then
      DeamplifyRange(tu)
    end
    
  end
end


------------------------
--  Aperiodic Events  --
------------------------


-- Turret placed
function export.TurretAdded(turret)
  if not global.boostInfo[turret.name]
      or global.boostInfo[turret.name] == NOT_BOOSTABLE then
    return
  end

  local friends = turret.surface.find_entities_filtered{area=u.GetBoostableAreaFromPosition(turret.position),
                                                        name={d.searchlightBaseName, d.searchlightAlarmName, d.searchlightSafeName},
                                                        force=turret.force}

  for _, f in pairs(friends) do
    export.CreateRelationship(global.unum_to_g[f.unit_number], turret)
  end
end


-- Turret removed
function export.TurretRemoved(turret, tu)
  if turret then
    if not global.tun_to_tunion[turret.unit_number] then
      return -- We weren't tracking this turret, so nothing to do
    end

    local tu = global.tun_to_tunion[turret.unit_number]
    r.removeRelationRHS(global.GestaltTunionRelations, tu.tuID)

    if tu.control then
      tu.control.destroy()
      tu.control = nil
    end
    if tu.boostAnimation then
      rendering.destroy(tu.boostAnimation)
    end

    global.tun_to_tunion[turret.unit_number] = nil
    global.boosted_to_tunion[tu.tuID] = nil
    global.tunions[tu.tuID] = nil
  else
    if not tu then
      return
    end

    -- Some workarounds are necessary here
    -- to deal with the map editor not firing events
    r.removeRelationRHS(global.GestaltTunionRelations, tu.tuID)

    if tu.control then
      tu.control.destroy()
      tu.control = nil
    end
    if tu.boostAnimation then
      rendering.destroy(tu.boostAnimation)
    end

    -- TODO I don't remember writing these 3 loops of garbage
    for lhs, rhs in pairs(global.tun_to_tunion) do
      if rhs.tuID == tu.tuID then
        global.tun_to_tunion[lhs] = nil
      end
    end

    for lhs, rhs in pairs(global.boosted_to_tunion) do
      if rhs.tuID == tu.tuID then
        global.boosted_to_tunion[lhs] = nil
      end
    end

    for lhs, rhs in pairs(global.tunions) do
      if rhs.tuID == tu.tuID then
        global.tunions[lhs] = nil
      end
    end
  end
end


-- Gestalt removed
-- (Unboosting would happen in FoeGestaltRelationRemoved)
function export.GestaltRemoved(tuID)
  -- Check if we still have a relationship with anything before removing this tunion
  if next(r.getRelationRHS(global.GestaltTunionRelations, tuID)) then
    return
  end

  local tu = global.tunions[tuID]

  if tu.control then
    tu.control.destroy()
    tu.control = nil
  end

  global.tun_to_tunion[tu.turret.unit_number] = nil
  global.boosted_to_tunion[tu.tuID] = nil
  global.tunions[tu.tuID] = nil
end


export.IsBoostableAndInRange = function(g, t)
  if global.boostInfo[t.name] == NOT_BOOSTABLE then
    return false

  -- Fine-tune checking that a turret is in a good range to be neighbors
  elseif u.RectangeDistSquared(u.UnpackRectangles(t.selection_box, g.light.selection_box))
   < u.square(d.searchlightMaxNeighborDistance) then
    return true
  end

  return false
end


-- Called when a searchlight or turret is created
export.CreateRelationship = function(g, t)
  if not export.IsBoostableAndInRange(g, t) then
    return
  end

  local tuID = getTuID(t)
  r.setRelation(global.GestaltTunionRelations, g.gID, tuID)
end


-- Unboost any turrets shooting at unsactioned foes.
-- We have three conditions upon which we need to check for unboosting:
-- Foe left range (checked in gestalt.CheckGestaltFoes),
-- Foe died (checked in gestalt.FoeDied),
-- Searchlight deconstructed / died while targeting a Foe (checked in gestalt.SearchlightRemoved)
export.FoeGestaltRelationRemoved = function(g, tIDlist)

  if tIDlist == nil then
    tIDlist = r.getRelationLHS(global.GestaltTunionRelations, g.gID)
  end

  for tuID, _ in pairs(tIDlist) do
    local tu = global.tunions[tuID]
    if not ReassignTurret(tu.turret, tuID) then
      export.UnBoost(tu)
    end
  end

end


-- Called when the override max ammo range mod setting changes to false,
-- which means we need to find and swap back any taboo'd ammo
export.RespectMaxAmmoRange = function()
  for _, tu in pairs(global.boosted_to_tunion) do
    local turret = tu.turret
    local entities = turret.surface.find_entities_filtered{position=turret.position,
                                                           radius=4
                                                          }

    for _, e in pairs(entities) do
      ca.UnBoostAmmo(e)
    end

    -- We'll reboost this turret if its foe was still actually in range
    export.UnBoost(tu)
  end
end


------------------------
-- Un/Boost Functions --
------------------------


-- After being added to the map of boostables,
-- we'll check if it's time to actually swap to
-- the range-boosted turret in CheckAmmoElectricNeeds()
-- via onTick()
export.Boost = function(tunion, foe)
  if global.boosted_to_tunion[tunion.tuID] or global.boostInfo[tunion.turret.name] == BLOCKED then
    return
  end

  global.boosted_to_tunion[tunion.tuID] = tunion
  tunion.control = SpawnControl(tunion.turret)
  
  if settings.global[d.enableBoostGlow].value then
    tunion.boostAnimation = SpawnBoostAnimation(tunion.turret)
  end

  tunion.foe = foe
end


export.UnBoost = function(tunion)
  if not global.boosted_to_tunion[tunion.tuID] then
    return
  end

  global.boosted_to_tunion[tunion.tuID] = nil
  local c = tunion.control
  if c then -- In some cases, other mods apparently can destroy our control entity...
    c.surface.create_entity{name = "spark-explosion", position = c.position}
    c.surface.create_entity{name = "spark-explosion", position = c.position}
    c.destroy()
  end

  tunion.control = nil
  tunion.foe = nil

  if tunion.boostAnimation then
    rendering.destroy(tunion.boostAnimation)
  end

  if tunion.boosted then
    DeamplifyRange(tunion)
  end
end


return export
