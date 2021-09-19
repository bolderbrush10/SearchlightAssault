script.on_event(defines.events.on_gui_opened, function(event)
  local player =  game.players[event.player_index]
  if player.opened and (player.opened.name == 'yourcombinator') do
    player.opened = nil
    local gui = player.center.add{'type=frame'} --etcpp, create your custom gui
    player.opened = gui
    end end)


game.print("hello world")
for key,value in pairs(o) do
    game.print("found member " .. key);
end


game.print(serpent.block(fluidTurret.fluidbox))


LuaGameScript
table_to_json(data) → string

json_to_table(json) → Any



script.on_event(defines.events.on_console_command,
function(event)
  DEBUGTOOL()
end)



-- Use the on_nth_tick(tick, f) to handle timer checking at a more reasonable, albiet less accurate rate (like, for checking if we should unboost turrets)

on_nth_tick(tick, f)

Register a handler to run every nth tick(s). When the game is on tick 0 it will trigger all registered handlers.

Parameters
tick :: uint or array of uint: The nth-tick(s) to invoke the handler on. Passing nil as the only parameter will unregister all nth-tick handlers.
f :: function(NthTickEvent): The handler to run. Passing nil will unregister the handler for the provided ticks.


==================

## Scraps to implement


```
-- !! So, since it seems impossible in base lua to iterate over a "chunk" of a dictionary,
--    we might have to implement something ourselves with just a stock array
-- TODO Inside the add/remove searchlight functions, increase or decrease sl_bucketSize
--      in proportion to how many turrets we want to check per tick when we reach milestones
local function check_turrets_on_tick(event)
  if not global.sl_onTick_turretIndex then
    global.sl_onTick_turretIndex = 0
    global.sl_bucketSize = 100
  end

  local tableSize = table_size(global.searchLights)
  local i = global.sl_onTick_turretIndex
  local max = global.sl_onTick_turretIndex + global.sl_bucketSize

  if max > tableSize then
    max = tableSize
  end

  while i < max do
    doStuff(global.searchLights[i])
    i = i + 1
  end

  global.turretIndex = global.turretIndex + global.sl_bucketSize
  if global.turretIndex >= table_size(global.searchLights)
    global.turretIndex = 0
  end
end
```


```
-- Klonan's iterator (similar to what we did for the grid-checker)
local function on_tick(event)
  for surface_name, surface_position_x in pairs(global.supportive_turrets) do
    for x, surface_position_y in pairs(surface_position_x) do
      if (x + game.tick) % 60 == 0 then
        for y, data in pairs(surface_position_y) do
          if (x + y + game.tick) % check_period == 0 then
            if not data.turret.valid then
              if data.unit.valid then
                data.unit.destroy()
              end
              global.supportive_turrets[surface_name][x][y] = nil
            end
          end
        end
      end
    end
  end
end
```



local piOverSix       = (math.pi / 6)
local piOverThree     = (math.pi / 3)
local twoPiOverThree  = (2  * math.pi / 3)
local fivePiOverSix   = (5  * math.pi / 6)
local sevenPiOverSix  = (7  * math.pi / 6)
local fourPiOverThree = (4  * math.pi / 3)
local fivePiOverThree = (5  * math.pi / 3)
local elevenPiOverSix = (11 * math.pi / 6)

function unitTestGetDirection()
    local posA = {x = 0, y = 0}
    local posB = {x = 2, y = 2}

    game.print("result (1): " .. getDirection(posA, posB))
    posB = {x=-2, y = 2}
    game.print("result (7): " .. getDirection(posA, posB))
    posB = {x=-2, y=-2}
    game.print("result (5): " .. getDirection(posA, posB))
    posB = {x = 2, y=-2}
    game.print("result (3): " .. getDirection(posA, posB))

    posB = {x = 0, y = 2}
    game.print("result (0): " .. getDirection(posA, posB))
    posB = {x = 2, y = 0}
    game.print("result (2): " .. getDirection(posA, posB))
    posB = {x = 0, y=-2}
    game.print("result (4): " .. getDirection(posA, posB))
    posB = {x=-2, y = 0}
    game.print("result (6): " .. getDirection(posA, posB))

--    northwest:  7
--    west:       6
--    southwest:  5
--    south:      4
--    southeast:  3
--    east:       2
--    northeast:  1
--    north:      0
end

function getDirection(a, b)
    -- theta: Angle from north, clockwise
    local theta_radians = math.atan2(b.x - a.x, a.y - b.y)
    if theta_radians < 0 then
        theta_radians = theta_radians + (math.pi * 2)
    end

    local player = game.players[1]
    --game.print("radians: " .. theta_radians)

    if theta_radians < piOverSix then
        return defines.direction.north
    elseif theta_radians < piOverThree then
        return defines.direction.northeast
    elseif theta_radians < twoPiOverThree then
        return defines.direction.east
    elseif theta_radians < fivePiOverSix then
        return defines.direction.southeast
    elseif theta_radians < sevenPiOverSix then
        return defines.direction.south
    elseif theta_radians < fourPiOverThree then
        return defines.direction.southwest
    elseif theta_radians < fivePiOverThree then
        return defines.direction.west
    elseif theta_radians < elevenPiOverSix then
        return defines.direction.northwest
    else
        return defines.direction.north
    end
end




function RushTurtle(turtle, waypoint)
  if global.turtle_to_waypoint[turtle.unit_number] == nil
     or global.turtle_to_waypoint[turtle.unit_number] ~= waypoint then

      global.turtle_to_waypoint[turtle.unit_number] = waypoint
      turtle.speed = searchlightTrackSpeed

      turtle.set_command({type = defines.command.go_to_location,
                          distraction = defines.distraction.none,
                          destination = waypoint,
                          pathfind_flags = {prefer_straight_paths = true, no_break = true,
                                            allow_destroy_friendly_entities = true,
                                            allow_paths_through_own_entities = true},
                          radius = 1
                         })
  end
end


------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------


function UpdateUnitsCommands(player_index)
        local player = game.players[player_index].character
        local pos = player.position
    local aggression_area = {{pos.x - agro_area_rad, pos.y - agro_area_rad}, {pos.x + agro_area_rad, pos.y + agro_area_rad}}
        if not player.surface.valid then return end
        local targets = player.surface.find_entities(aggression_area)
        local min_dist = agro_area_rad + 10;
        local closest_index = -1
        local surface = player.surface

        for index, target in ipairs(targets) do
                if target.health then
                        if target.force == game.forces.enemy and target.type ~= "turret" and target.type ~= "unit" then
                                local dist = GetDistance(target.position, pos)
                                if min_dist > dist then
                                        min_dist = dist
                                        closest_index = index
                                end
                        end
                end
        end

        local unit_count = 0
        if closest_index == -1 then

                local attOn = game.players[player_index].get_item_count("attractor-on")
                local attOff = game.players[player_index].get_item_count("attractor-off")
                local lastState = nil
                if global.evolution[game.players[player_index].name] and global.evolution[game.players[player_index].name].lastState then
                        lastState = global.evolution[game.players[player_index].name].lastState
                else
                        if global.evolution[game.players[player_index].name] == nil then
                                global.evolution[game.players[player_index].name] = {}
                        end
                        global.evolution[game.players[player_index].name].lastState = nil
                end

                if attOn > 0 and attOff == 0 then
                        if attOn > 1 then
                                game.players[player_index].removeitem({name = "attractor-on", count=(attOn - 1)})
                        end
                        lastState = "on"
                elseif attOn == 0 and attOff > 0 then
                        if attOff > 1 then
                                game.players[player_index].removeitem({name = "attractor-off", count=(attOff - 1)})
                        end
                        lastState = "off"
                elseif attOn > 0 and attOff > 0 then
                        if lastState ~= nil and lastState == "off" then
                                game.players[player_index].removeitem({name = "attractor-off", count = attOff})
                                if attOn > 1 then
                                        game.players[player_index].removeitem({name = "attractor-on", count=(attOn - 1)})
                                end
                                lastState = "on"
                        else
                                game.players[player_index].removeitem({name = "attractor-on", count = attOn})
                                if attOn > 1 then
                                        game.players[player_index].removeitem({name = "attractor-on", count=(attOn - 1)})
                                end
                                lastState = "off"
                        end
                else
                        lastState = "off"
                end
                global.evolution[game.players[player_index].name].lastState = lastState

                if lastState == "off" then return end
                local call_back_area = {{pos.x -  call_back_area_rad, pos.y -  call_back_area_rad}, {pos.x +  call_back_area_rad, pos.y +  call_back_area_rad}}
                local biters = surface.find_entities_filtered{area = call_back_area, type = "unit"}
                for index, biter in ipairs(biters) do
                        if biter.force == (player.force) then
                                biter.set_command({type = defines.command.go_to_location, destination = pos, radius = 10, distraction = defines.distraction.byanything});
                                unit_count = unit_count + 1

                        end
                        if unit_count > max_unit_count then return end
                end
        else
                local call_back_area = {{pos.x -  call_back_area_rad, pos.y -  call_back_area_rad}, {pos.x +  call_back_area_rad, pos.y +  call_back_area_rad}}
                local biters = player.surface.find_entities_filtered{area = call_back_area, type = "unit"}
                for index, biter in ipairs(biters) do
                        if biter.force == player.force then
                                biter.set_command({type = defines.command.attack, target = targets[closest_index], distraction = defines.distraction.byanything});
                                unit_count = unit_count + 1
                        end
                        if unit_count > max_unit_count then return end
                end
        end
end

function GetNearest( objects, point )
	if #objects == 0 then
		return nil
	end

	local maxDist = math.huge
	local nearest = objects[1]
	for _, tile in ipairs(objects) do
		local dist = DistanceSqr(point, tile.position)
		if dist < maxDist then
			maxDist = dist
			nearest = tile
		end
	end

	return nearest
end

local function OnGameInit()
	radar_system = RadarSystem.CreateActor()
	radar_system:Init()
	mod_has_init = true
end

local function OnGameSave()
	glob.radar_system = radar_system
end

local function OnGameLoad()
	if not mod_has_init and glob.radar_system then
		radar_system = RadarSystem.CreateActor(glob.radar_system)
		radar_system:OnLoad()
		mod_has_init = true
	end
end

local function OnPlayerCreated( playerindex )
	local player = game.players[playerindex]
end

local function OnEntityBuilt( entity, playerindex )
	local player
	if playerindex then
		player = game.players[playerindex]
	end

	if entity.name == "radar" and player then
		radar_system:OnRadarBuilt(entity, player)
	end
end

local function OnEntityDestroy( entity, playerindex )
	local player
	if playerindex then
		player = game.players[playerindex]
	end

	if entity.name == "radar" and player then
		radar_system:OnRadarDestroy(entity, player)
	end
end

local function OnTick()
	ResumeRoutines()
	radar_system:OnTick()
end

game.oninit(OnGameInit)
game.onload(OnGameLoad)
game.onsave(OnGameSave)
game.onevent(defines.events.onbuiltentity, function(event) OnEntityBuilt(event.createdentity, event.playerindex) end)
game.onevent(defines.events.onrobotbuiltentity, function(event) OnEntityBuilt(event.createdentity) end)
game.onevent(defines.events.onentitydied, function(event) OnEntityDestroy(event.entity) end)
game.onevent(defines.events.onpreplayermineditem, function(event) OnEntityDestroy(event.entity, event.playerindex) end)
game.onevent(defines.events.onrobotpremined, function(event) OnEntityDestroy(event.entity) end)
game.onevent(defines.events.onplayercreated, function(event) OnPlayerCreated(event.playerindex) end)
game.onevent(defines.events.ontick, OnTick)


------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------


blank = {
     filename = "__Searchlights__/graphics/transparent_pixel.png",
     priority = "extra-high",
     width = 1,
     height = 1
}

graphicOn = {
    filename = "__Searchlights__/graphics/terribleLight.png",
    priority = "extra-high",
    width = 95,
    height = 82
}

graphicOff = {
    filename = "__Searchlights__/graphics/terrible-off.png",
    priority = "extra-high",
    width = 95,
    height = 82
}

light = {
    color = {
      b = 1,
      g = 1,
      r = 1
    },
    intensity = 0.8,
    size = 12
}

spotlight = {
    type = "oriented",
    picture =
    {
        filename = "__Searchlights__/graphics/spotlight.png",
        priority = "extra-high",
        flags = { "light" },
        scale = 2,
        width = 200,
        height = 200
    },
    minimum_darkness = 0.8,
    shift = {0, 0},
    size = 1,
    intensity = 0.8,
    color = {r = 1.0, g = 1.0, b = 1.0}
}

--
-- lightEntity; a hidden entity to make the spotlight effect on ground
--
local lightEntity = table.deepcopy(data.raw["lamp"]["small-lamp"])

table.deepcopy(data.raw["lamp"]["small-lamp"])

lightEntity.name = "searchlight-hidden"
lightEntity.flags = {"placeable-off-grid", "not-on-map"}
lightEntity.selectable_in_game = false
lightEntity.collision_box = {{-0.0, -0.0}, {0.0, 0.0}}
lightEntity.selection_box = {{-0.0, -0.0}, {0.0, 0.0}}
lightEntity.collision_mask = {"not-colliding-with-itself"}

-- We dont' intend to leave a corpse at all, but if the worst happens...
lightEntity.corpse = "small-scorchmark"
lightEntity.energy_source = {
 type = "void",
 usage_priority = "lamp"
}
lightEntity.light = spotlight
lightEntity.light_when_colored = spotlight
lightEntity.picture_off = blank
lightEntity.picture_on = blank


-- Basically we just want the turret to point itself at things, not have any real effect. We're going to just use draw_light calls in control.lua for the actual effect.
turretEntity.attack_parameters = {
    type = "beam",
    cooldown = 100,
    range = searchlightRange,
    use_shooter_direction = true,
    ammo_type = table.deepcopy(data.raw["electric-turret"]["laser-turret"]["attack_parameters"]["ammo_type"])
    ammo_type =
    {
        category = "laser-turret",
        target_type = "position",
        action =
        {
            type = "area",
            radius = 2.0,
            action_delivery =
            {
                type = "beam",
                beam = "spotlight-beam",
                duration = 10,
                --starting_speed = 0.3
            }
        }
    }
}


local beaconEntity = table.deepcopy(data.raw["beacon"])
local spotlightAnimation = beaconEntity.animation

local spotlightBeam = table.deepcopy(data.raw["beam"]["laser-beam"])

spotlightBeam.name = "spotlight-beam"
spotlightBeam.head = spotlightAnimation




-- spotLightHiddenEnt; A simple hidden entity for the spotlight to target while no enemies are present
local spotLightHiddenEnt = table.deepcopy(data.raw["unit"]["small-biter"])
spotLightHiddenEnt.name = "SpotlightShine"
spotLightHiddenEnt.collision_box = {{0, 0}, {0, 0}} -- enable noclip
spotLightHiddenEnt.collision_mask = {"not-colliding-with-itself"}
spotLightHiddenEnt.selectable_in_game = false
spotLightHiddenEnt.selection_box = {{-0.0, -0.0}, {0.0, 0.0}}


data:extend{spotlightBeam, turretEntity, spotLightSprite, spotLightHiddenEnt}
data:extend{turretEntity, spotLightSprite, spotLightHiddenEnt}
data:extend{spotlightAnimation, spotlightBeam}




-- 'sl' for 'SearchLight'
function LightUpFoes(sl, surface)
    -- Instantly find foes within the inner range
    local nearestFoe = surface.find_nearest_enemy{position = sl.position,
                                                  max_distance = searchlightInnerRange}

    if nearestFoe ~= nil then
        local lightID = renderSpotLight_red(nearestFoe.position, sl, surface)

        sl.shooting_target = nearestFoe
        return
    end

    -- If we're not directly shining on a foe, make up a random waypoint to track the light towards

    local wanderPos = makeWanderWaypoint(sl.position)
    local lightID = renderSpotLight_def(wanderPos, sl, surface)
end



-- TODO interpolate from wander position to nearest foe instead of snapping over, etc
-- TODO destroy hidden entities when sl is destroyed / removed etc
-- TODO spotlight should probably only wander a 180degree arc around its inital placement
-- TODO disable when no electricity / reduce range according to electric satisfaction
-- 'sl' for 'SearchLight'
function LightUpFoes(sl, surface)
    -- Instantly find foes within the inner range
    local nearestFoe = surface.find_nearest_enemy{position = sl.position,
                                                  max_distance = searchlightRange}

    if nearestFoe ~= nil then
        local lightID = renderSpotLight_red(nearestFoe.position, sl, surface)
        lightEntities[sl.unit_number] = {lightID = lightID,
                                         position = nearestFoe.position,
                                         waypoint = nearestFoe.position}
        sl.shooting_target = nearestFoe
        -- TODO move light entity to this foe's location
        return
    else
        return
    end

    -- If we're not directly shining on a foe, make up a random waypoint to track the light towards

    if lightEntities[sl.unit_number] == nil then
        local wanderPos = makeWanderWaypoint(sl.position)
        local lightID = renderSpotLight_def(wanderPos, sl, surface)
        lightEntities[sl.unit_number] = {lightID = lightID,
                                         position = makeLightStartLocation(sl),
                                         waypoint = wanderPos}

        -- flicker the spotlight at the new location so we can see what we're doing
        -- TODO remove this flicker when development is done
        renderSpotLight_red(lightEntities[sl.unit_number].waypoint, sl, surface)
        return
    end

    -- If the light has gotten close enough to waypoint, make a new waypoint
    -- (Using distances smaller than 3 will fail.
    --  The game engine's pathfinding for entities is a 'close enough' kind of thing)
    if len(lightEntities[sl.unit_number].position,
           lightEntities[sl.unit_number].waypoint) < 3 then
        lightEntities[sl.unit_number].waypoint = makeWanderWaypoint(sl.position)

        if lightEntities[sl.unit_number].entity then
            lightEntities[sl.unit_number].entity.set_command(makeMoveCommand(lightEntities[sl.unit_number].waypoint))
        end

        -- flicker the spotlight at the new location so we can see what we're doing
        -- TODO remove this flicker when done developing
        renderSpotLight_red(lightEntities[sl.unit_number].waypoint, sl, surface)
    end

    local newPosition = moveTowards(lightEntities[sl.unit_number].position,
                                    lightEntities[sl.unit_number].waypoint,
                                    searchlightTrackSpeed)

    if lightEntities[sl.unit_number].entity == nil then
        -- TODO invisible target w/ noclip or something

        -- TODO Why the heck were we doing this?
        -- Just to move ourselves out of the turret, right?
        local positionCopyTEMP = newPosition
        positionCopyTEMP.x = positionCopyTEMP.x + 4

        local newEnt = surface.create_entity{name = "SpotlightShine",
                                             position = positionCopyTEMP,
                                             force = searchlightFoe}

        sl.shooting_target = newEnt

        lightEntities[sl.unit_number].entity = newEnt
        newEnt.set_command(makeMoveCommand(lightEntities[sl.unit_number].waypoint))
    end

    -- TODO this line crashes if the hidden entity is killed, so make sure its invulnerable and cleaned up properly
    local lightID = renderSpotLight_def(lightEntities[sl.unit_number].entity.position, sl, surface)
    lightEntities[sl.unit_number].lightID = lightID
    lightEntities[sl.unit_number].position = lightEntities[sl.unit_number].entity.position
end

function makeLightStartLocation(sl)
    -- TODO get the orientation of the light and stick this slightly in front
    --      also figure out how to deal with the unfolding animation
    return sl.position
end

function makeWanderWaypoint(origin)
    -- make it easier to find the light for now
    -- x = origin.x + math.random(-searchlightRange, searchlightRange)
    -- y = origin.y + math.random(-searchlightRange, searchlightRange)

    local waypoint = {x = origin.x + math.random(-searchlightInnerRange, searchlightInnerRange),
                      y = origin.y + math.random(-searchlightInnerRange, searchlightInnerRange)}

    return waypoint
end

-- TODO Test speed on this vs engine pathfinder w/ noclip
-- TODO This seems buggy as heck, test it
function moveTowards(currPos, destPos, speed)
    local vec = {x = destPos.x - currPos.x,
                 y = destPos.y - currPos.y}

    local distance = len(currPos, destPos)

    local norm = {x = 0, y = 0}

    if distance ~= 0 then
        norm.x = vec.x / distance
        norm.y = vec.y / distance
    end

    -- TODO stop overshooting
    local newPos = {x = currPos.x + (speed * norm.x),
                    y = currPos.y + (speed * norm.y)}

    return newPos
end

function makeMoveCommand(destination)
    local newCommand = defines.command
    newCommand.type = defines.command.go_to_location
    newCommand.destination = destination
    return newCommand
end


-- TODO trade accuracy for speed
function len(a, b)
    return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2)
end


========================================================================

  local laser_beam_blend_mode = "additive"

  =====================================================================


  =====================================================================


local Turtle =
{
  type = "unit",
  name = "searchlight-turtle",
  flags =
  {
    "placeable-off-grid",
    "not-on-map",
    "not-blueprintable",
    "not-deconstructable",
    "hidden",
    "not-flammable",
    "no-copy-paste",
    "not-selectable-in-game",
  },
  collision_mask = {"not-colliding-with-itself"},
  collision_box = {{0, 0}, {0, 0}}, -- enable noclip
  selectable_in_game = false,
  selection_box = {{-0.0, -0.0}, {0.0, 0.0}},
  -- We don't intend to leave a corpse at all, but if the worst happens...
  corpse = "small-scorchmark",
  ai_settings = biter_ai_settings,
  movement_speed = searchlightTrackSpeed,
  distance_per_frame = 1,
  pollution_to_join_attack = 5000,
  distraction_cooldown = 1,
  vision_distance = 1,
  attack_parameters =
  {
    type = "projectile",
    range = 1,
    cooldown = 100,
    ammo_type = make_unit_melee_ammo_type(1),
    animation = Layer_transparent_pixel,
  },
  run_animation = Layer_transparent_pixel,
}



==============================================================
==============================================================
==============================================================
==============================================================



function Boost(oldT, surface, foe)
  if game.entity_prototypes[oldT.name .. boostSuffix] == nil then
    return nil
  end

  local foeLenSq = lensquared(foe.position, oldT.position)

  -- Foes any closer probably don't merit any boosting
  if foeLenSq <= square(12) then
    return nil

  elseif foeLenSq <= square(LookupRange(oldT)) and oldT.shooting_target ~= nil then
    return nil

  elseif oldT.type == "electric-turret" and foeLenSq >= square(elecBoost) then
    return nil

  elseif oldT.type == "ammo-turret" and foeLenSq >= square(ammoBoost) then
    return nil

  elseif foeLenSq >= square(fluidBoost) then
    return nil

  elseif not IsPositionWithinTurretArc(foe.position, oldT) then
    return nil
  end


end


--
-- Manually render spotlight range on mouseover / held in cursor
--

local renderID = nil

script.on_event(defines.events.on_selected_entity_changed,
function(event)

  local player = game.players[event.player_index]
  if player.selected and not renderID then
    renderID = renderRange(player, player.selected)
    game.print("rendering " .. renderID)
  elseif renderID then
    game.print("destroying " .. renderID)
    rendering.destroy(renderID)
    renderID = nil
  end

end)

script.on_event(defines.events.on_player_cursor_stack_changed,
function(event)

  local player = game.players[event.player_index]
  if player.cursor_stack.valid_for_read then
    -- and player.cursor_stack.name == searchlightItemName

    renderRange(game.players[event.player_index], player.cursor_position)
  end

end)


-- target can either be a position or an entity
function renderRange(player, target)

  return rendering.draw_circle{color={0.8, 0.1, 0.1, 0.5},
                               radius=5,
                               filled=true,
                               target=target,
                               target_offset={0,0},
                               surface=player.surface,
                               time_to_live=0,
                               players={player},
                               draw_on_ground=true}

end



-- Manual debug tool, triggered by typing anything into the console
-- TODO remove
script.on_event(defines.events.on_console_command,
function (event)
  p = game.players[1]
  if p.selected then
    entities = p.surface.find_entities_filtered{position=p.selected.position, radius=5}
    if entities then
      game.print("count: " .. #entities)
      for i, e in pairs(entities) do
        if e.type == "unit" and e.spawner then
          game.print("ename: " .. e.name .. " and spawner: " .. e.spawner.name)
        else
          game.print("ename: " .. e.name .. " but no spawner")
        end
      end

    else
      game.print("nil")
    end
  else
    game.print("nothing selected")
  end
end)


local turt = nil
-- Automatic debug tool, triggered every tick
-- TODO remove
function DEBUGTOOL(tick)
  if not turt then
    p = game.players[1]
    res = p.surface.find_entities_filtered{name=turtleName}
    if res[1] then
      turt = res[1]
    else
      return
    end
  end

  if turt.command then
    game.print("turt command: " .. turt.command.type)
    if turt.command.type == defines.command.attack then
      game.print("target: " .. turt.command.target.name)
    end
  else
    game.print("no command")
  end
  if turt.distraction_command then
    game.print("turt distraction: " .. turt.distraction_command.type)
    if turt.distraction_command.type == defines.command.attack then
      game.print("target: " .. turt.distraction_command.target.name)
    end
  else
    game.print("no distraction")
  end





  if game.players[1].selected then
    rendering.draw_circle{color={0.8, 0.1, 0.1, 0.5}, radius=5, filled=true, target=game.players[1].selected, target_offset={0,0}, surface=game.players[1].surface, time_to_live=2, players={game.players[1]}, draw_on_ground=true}
  end
end