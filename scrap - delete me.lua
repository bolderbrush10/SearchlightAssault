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
-- TODO maybe do a subtle shaft of light effect as a beam 'attack'?
turretEntity.attack_parameters = {
    type = "beam",
    cooldown = 100,
    range = searchlightOuterRange,
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
                                                  max_distance = searchlightOuterRange}

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
    -- x = origin.x + math.random(-searchlightOuterRange, searchlightOuterRange)
    -- y = origin.y + math.random(-searchlightOuterRange, searchlightOuterRange)

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




{
    type = "electric-turret",
    name = "laser-turret",
    icon = "__base__/graphics/icons/laser-turret.png",
    icon_size = 32,
    flags = { "placeable-player", "placeable-enemy", "player-creation"},
    minable = { mining_time = 0.5, result = "laser-turret" },
    max_health = 1000,
    collision_box = {{ -0.7, -0.7}, {0.7, 0.7}},
    selection_box = {{ -1, -1}, {1, 1}},
    rotation_speed = 0.01,
    preparing_speed = 0.05,
    dying_explosion = "medium-explosion",
    corpse = "laser-turret-remnants",
    folding_speed = 0.05,
    energy_source =
    {
      type = "electric",
      buffer_capacity = "801kJ",
      input_flow_limit = "9600kW",
      drain = "24kW",
      usage_priority = "primary-input"
    },
    folded_animation =
    {
      layers =
      {
        laser_turret_extension{frame_count=1, line_length = 1},
        laser_turret_extension_shadow{frame_count=1, line_length=1},
        laser_turret_extension_mask{frame_count=1, line_length=1}
      }
    },
    preparing_animation =
    {
      layers =
      {
        laser_turret_extension{},
        laser_turret_extension_shadow{},
        laser_turret_extension_mask{}
      }
    },
    prepared_animation =
    {
      layers =
      {
        laser_turret_shooting(),
        laser_turret_shooting_shadow(),
        laser_turret_shooting_mask()
      }
    },
    --attacking_speed = 0.1,
    energy_glow_animation = laser_turret_shooting_glow(),
    glow_light_intensity = 0.5, -- defaults to 0
    folding_animation =
    {
      layers =
      {
        laser_turret_extension{run_mode = "backward"},
        laser_turret_extension_shadow{run_mode = "backward"},
        laser_turret_extension_mask{run_mode = "backward"}
      }
    },
    base_picture =
    {
      layers =
      {
        {
          filename = "__base__/graphics/entity/laser-turret/laser-turret-base.png",
          priority = "high",
          width = 70,
          height = 52,
          direction_count = 1,
          frame_count = 1,
          shift = util.by_pixel(0, 2),
          hr_version =
          {
            filename = "__base__/graphics/entity/laser-turret/hr-laser-turret-base.png",
            priority = "high",
            width = 138,
            height = 104,
            direction_count = 1,
            frame_count = 1,
            shift = util.by_pixel(-0.5, 2),
            scale = 0.5
          }
        },
        {
          filename = "__base__/graphics/entity/laser-turret/laser-turret-base-shadow.png",
          line_length = 1,
          width = 66,
          height = 42,
          draw_as_shadow = true,
          direction_count = 1,
          frame_count = 1,
          shift = util.by_pixel(6, 3),
          hr_version =
          {
            filename = "__base__/graphics/entity/laser-turret/hr-laser-turret-base-shadow.png",
            line_length = 1,
            width = 132,
            height = 82,
            draw_as_shadow = true,
            direction_count = 1,
            frame_count = 1,
            shift = util.by_pixel(6, 3),
            scale = 0.5
          }
        }
      }
    },
    vehicle_impact_sound =  { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },

    attack_parameters =
    {
      type = "beam",
      cooldown = 40,
      range = 24,
      source_direction_count = 64,
      source_offset = {0, -3.423489 / 4},
      damage_modifier = 2,
      ammo_type =
      {
        category = "laser-turret",
        energy_consumption = "800kJ",
        action =
        {
          type = "direct",
          action_delivery =
          {
            type = "beam",
            beam = "laser-beam",
            max_length = 24,
            duration = 40,
            source_offset = {0, -1.31439 }
          }
        }
      }
    },

    call_for_help_radius = 40
  },







  =====================================================================



  local laser_beam_blend_mode = "additive"

function make_laser_beam(sound)
  local result =
  {
    type = "beam",
    flags = {"not-on-map"},
    width = 0.5,
    damage_interval = 20,
    random_target_offset = true,
    action_triggered_automatically = false,
    action =
    {
      type = "direct",
      action_delivery =
      {
        type = "instant",
        target_effects =
        {
          {
            type = "damage",
            damage = { amount = 10, type = "laser"}
          }
        }
      }
    },
    head =
    {
      filename = "__base__/graphics/entity/laser-turret/hr-laser-body.png",
      flags = beam_non_light_flags,
      line_length = 8,
      width = 64,
      height = 12,
      frame_count = 8,
      scale = 0.5,
      animation_speed = 0.5,
      blend_mode = laser_beam_blend_mode
    },
    tail =
    {
      filename = "__base__/graphics/entity/laser-turret/hr-laser-end.png",
      flags = beam_non_light_flags,
      width = 110,
      height = 62,
      frame_count = 8,
      shift = util.by_pixel(11.5, 1),
      scale = 0.5,
      animation_speed = 0.5,
      blend_mode = laser_beam_blend_mode
    },
    body =
    {
      {
        filename = "__base__/graphics/entity/laser-turret/hr-laser-body.png",
        flags = beam_non_light_flags,
        line_length = 8,
        width = 64,
        height = 12,
        frame_count = 8,
        scale = 0.5,
        animation_speed = 0.5,
        blend_mode = laser_beam_blend_mode
      }
    },

    light_animations =
    {
      head =
      {
        filename = "__base__/graphics/entity/laser-turret/hr-laser-body-light.png",
        line_length = 8,
        width = 64,
        height = 12,
        frame_count = 8,
        scale = 0.5,
        animation_speed = 0.5,
      },
      tail =
      {
        filename = "__base__/graphics/entity/laser-turret/hr-laser-end-light.png",
        width = 110,
        height = 62,
        frame_count = 8,
        shift = util.by_pixel(11.5, 1),
        scale = 0.5,
        animation_speed = 0.5,
      },
      body =
      {
        {
          filename = "__base__/graphics/entity/laser-turret/hr-laser-body-light.png",
          line_length = 8,
          width = 64,
          height = 12,
          frame_count = 8,
          scale = 0.5,
          animation_speed = 0.5,
        }
      }
    },

    ground_light_animations =
    {
      head =
      {
        filename = "__base__/graphics/entity/laser-turret/laser-ground-light-head.png",
        line_length = 1,
        width = 256,
        height = 256,
        repeat_count = 8,
        scale = 0.5,
        shift = util.by_pixel(-32, 0),
        animation_speed = 0.5,
        tint = {0.5, 0.05, 0.05}
      },
      tail =
      {
        filename = "__base__/graphics/entity/laser-turret/laser-ground-light-tail.png",
        line_length = 1,
        width = 256,
        height = 256,
        repeat_count = 8,
        scale = 0.5,
        shift = util.by_pixel(32, 0),
        animation_speed = 0.5,
        tint = {0.5, 0.05, 0.05}
      },
      body =
      {
        filename = "__base__/graphics/entity/laser-turret/laser-ground-light-body.png",
        line_length = 1,
        width = 64,
        height = 256,
        repeat_count = 8,
        scale = 0.5,
        animation_speed = 0.5,
        tint = {0.5, 0.05, 0.05}
      }
    }
  }

  if sound then
    result.working_sound =
    {
      sound =
      {
        filename = "__base__/sound/fight/electric-beam.ogg",
        volume = 1
      },
      max_sounds_per_type = 4
    }
    result.name = "laser-beam"
  else
    result.name = "laser-beam-no-sound"
  end
  return result;
end

data:extend(
{
  make_laser_beam(true)
}
)


  =====================================================================

turretEntity.attack_parameters = {
    type = "beam",
    range = searchlightOuterRange,
    cooldown = 40,
    source_direction_count = 64,
    source_offset = {0, -3.423489 / 4},
    ammo_type =
    {
      category = "laser-turret",
      action =
      {
          type = "direct",
          action_delivery =
          {
            type = "beam",
            beam = "spotlight-beam",
            max_length = 24,
            duration = 40,
            source_offset = {0, -1.31439 }
          }
        }
    }
    -- Optional properties
    -- source_direction_count
    -- source_offset
}


  =====================================================================

data.raw["unit"]["small-biter"] =
{
  ai_settings = {
    allow_try_return_to_spawner = true,
    destroy_when_commands_fail = true
  },
  attack_parameters = {
    ammo_type = {
      action = {
        action_delivery = {
          target_effects = {
            damage = {
              amount = 7,
              type = "physical"
            },
            type = "damage"
          },
          type = "instant"
        },
        type = "direct"
      },
      category = "melee",
      target_type = "entity"
    },
    animation = {
      layers = {
        {
          animation_speed = 0.4,
          direction_count = 16,
          filenames = {
            "__base__/graphics/entity/biter/biter-attack-01.png",
            "__base__/graphics/entity/biter/biter-attack-02.png",
            "__base__/graphics/entity/biter/biter-attack-03.png",
            "__base__/graphics/entity/biter/biter-attack-04.png"
          },
          frame_count = 11,
          height = 176,
          hr_version = {
            animation_speed = 0.4,
            direction_count = 16,
            filenames = {
              "__base__/graphics/entity/biter/hr-biter-attack-01.png",
              "__base__/graphics/entity/biter/hr-biter-attack-02.png",
              "__base__/graphics/entity/biter/hr-biter-attack-03.png",
              "__base__/graphics/entity/biter/hr-biter-attack-04.png"
            },
            frame_count = 11,
            height = 348,
            line_length = 16,
            lines_per_file = 4,
            scale = 0.25,
            shift = {
              0,
              -0.390625
            },
            slice = 11,
            width = 356
          },
          line_length = 16,
          lines_per_file = 4,
          scale = 0.5,
          shift = {
            -0.03125,
            -0.40625
          },
          slice = 11,
          width = 182
        },
        {
          animation_speed = 0.4,
          direction_count = 16,
          filenames = {
            "__base__/graphics/entity/biter/biter-attack-mask1-01.png",
            "__base__/graphics/entity/biter/biter-attack-mask1-02.png",
            "__base__/graphics/entity/biter/biter-attack-mask1-03.png",
            "__base__/graphics/entity/biter/biter-attack-mask1-04.png"
          },
          flags = {
            "mask"
          },
          frame_count = 11,
          height = 144,
          hr_version = {
            animation_speed = 0.4,
            direction_count = 16,
            filenames = {
              "__base__/graphics/entity/biter/hr-biter-attack-mask1-01.png",
              "__base__/graphics/entity/biter/hr-biter-attack-mask1-02.png",
              "__base__/graphics/entity/biter/hr-biter-attack-mask1-03.png",
              "__base__/graphics/entity/biter/hr-biter-attack-mask1-04.png"
            },
            frame_count = 11,
            height = 282,
            line_length = 16,
            lines_per_file = 4,
            scale = 0.25,
            shift = {
              -0.015625,
              -0.640625
            },
            slice = 11,
            tint = {
              a = 1,
              b = 0.50999999999999996,
              g = 0.57999999999999998,
              r = 0.6
            },
            width = 360
          },
          line_length = 16,
          lines_per_file = 4,
          scale = 0.5,
          shift = {
            0,
            -0.65625
          },
          slice = 11,
          tint = nil,
          width = 178
        },
        {
          animation_speed = 0.4,
          direction_count = 16,
          filenames = {
            "__base__/graphics/entity/biter/biter-attack-mask2-01.png",
            "__base__/graphics/entity/biter/biter-attack-mask2-02.png",
            "__base__/graphics/entity/biter/biter-attack-mask2-03.png",
            "__base__/graphics/entity/biter/biter-attack-mask2-04.png"
          },
          flags = {
            "mask"
          },
          frame_count = 11,
          height = 144,
          hr_version = {
            animation_speed = 0.4,
            direction_count = 16,
            filenames = {
              "__base__/graphics/entity/biter/hr-biter-attack-mask2-01.png",
              "__base__/graphics/entity/biter/hr-biter-attack-mask2-02.png",
              "__base__/graphics/entity/biter/hr-biter-attack-mask2-03.png",
              "__base__/graphics/entity/biter/hr-biter-attack-mask2-04.png"
            },
            frame_count = 11,
            height = 282,
            line_length = 16,
            lines_per_file = 4,
            scale = 0.25,
            shift = {
              -0.015625,
              -0.640625
            },
            slice = 11,
            tint = {
              a = 1,
              b = 0.54000000000000004,
              g = 0.82999999999999989,
              r = 0.9
            },
            width = 358
          },
          line_length = 16,
          lines_per_file = 4,
          scale = 0.5,
          shift = {
            -0.03125,
            -0.65625
          },
          slice = 11,
          tint = nil,
          width = 182
        },
        {
          animation_speed = 0.4,
          direction_count = 16,
          draw_as_shadow = true,
          filenames = {
            "__base__/graphics/entity/biter/biter-attack-shadow-01.png",
            "__base__/graphics/entity/biter/biter-attack-shadow-02.png",
            "__base__/graphics/entity/biter/biter-attack-shadow-03.png",
            "__base__/graphics/entity/biter/biter-attack-shadow-04.png"
          },
          frame_count = 11,
          height = 128,
          hr_version = {
            animation_speed = 0.4,
            direction_count = 16,
            draw_as_shadow = true,
            filenames = {
              "__base__/graphics/entity/biter/hr-biter-attack-shadow-01.png",
              "__base__/graphics/entity/biter/hr-biter-attack-shadow-02.png",
              "__base__/graphics/entity/biter/hr-biter-attack-shadow-03.png",
              "__base__/graphics/entity/biter/hr-biter-attack-shadow-04.png"
            },
            frame_count = 11,
            height = 258,
            line_length = 16,
            lines_per_file = 4,
            scale = 0.25,
            shift = {
              0.484375,
              -0.015625
            },
            slice = 11,
            width = 476
          },
          line_length = 16,
          lines_per_file = 4,
          scale = 0.5,
          shift = {
            0.46875,
            0
          },
          slice = 11,
          width = 240
        }
      }
    },
    cooldown = 35,
    range = 0.5,
    sound = {
      {
        filename = "__base__/sound/creatures/biter-roar-1.ogg",
        volume = 0.4
      },
      {
        filename = "__base__/sound/creatures/biter-roar-2.ogg",
        volume = 0.4
      },
      {
        filename = "__base__/sound/creatures/biter-roar-3.ogg",
        volume = 0.4
      },
      {
        filename = "__base__/sound/creatures/biter-roar-4.ogg",
        volume = 0.4
      },
      {
        filename = "__base__/sound/creatures/biter-roar-5.ogg",
        volume = 0.4
      },
      {
        filename = "__base__/sound/creatures/biter-roar-6.ogg",
        volume = 0.4
      }
    },
    type = "projectile"
  },
  collision_box = {
    {
      -0.2,
      -0.2
    },
    {
      0.2,
      0.2
    }
  },
  corpse = "small-biter-corpse",
  distance_per_frame = 0.125,
  distraction_cooldown = 300,
  dying_explosion = "blood-explosion-small",
  dying_sound = {
    {
      filename = "__base__/sound/creatures/biter-death-1.ogg",
      volume = 0.4
    },
    {
      filename = "__base__/sound/creatures/biter-death-2.ogg",
      volume = 0.4
    },
    {
      filename = "__base__/sound/creatures/biter-death-3.ogg",
      volume = 0.4
    },
    {
      filename = "__base__/sound/creatures/biter-death-4.ogg",
      volume = 0.4
    },
    {
      filename = "__base__/sound/creatures/biter-death-5.ogg",
      volume = 0.4
    }
  },
  flags = {
    "placeable-player",
    "placeable-enemy",
    "placeable-off-grid",
    "not-repairable",
    "breaths-air"
  },
  healing_per_tick = 0.01,
  icon = "__base__/graphics/icons/small-biter.png",
  icon_size = 32,
  max_health = 15,
  max_pursue_distance = 50,
  min_pursue_time = 600,
  movement_speed = 0.2,
  name = "small-biter",
  order = "b-b-a",
  pollution_to_join_attack = 4,
  resistances = {},
  run_animation = {
    layers = {
      {
        direction_count = 16,
        filenames = {
          "__base__/graphics/entity/biter/biter-run-01.png",
          "__base__/graphics/entity/biter/biter-run-02.png",
          "__base__/graphics/entity/biter/biter-run-03.png",
          "__base__/graphics/entity/biter/biter-run-04.png"
        },
        frame_count = 16,
        height = 158,
        hr_version = {
          direction_count = 16,
          filenames = {
            "__base__/graphics/entity/biter/hr-biter-run-01.png",
            "__base__/graphics/entity/biter/hr-biter-run-02.png",
            "__base__/graphics/entity/biter/hr-biter-run-03.png",
            "__base__/graphics/entity/biter/hr-biter-run-04.png"
          },
          frame_count = 16,
          height = 310,
          line_length = 8,
          lines_per_file = 8,
          scale = 0.25,
          shift = {
            -0.015625,
            -0.078125
          },
          slice = 8,
          width = 398
        },
        line_length = 8,
        lines_per_file = 8,
        scale = 0.5,
        shift = {
          -0.03125,
          -0.09375
        },
        slice = 8,
        width = 202
      },
      {
        direction_count = 16,
        filenames = {
          "__base__/graphics/entity/biter/biter-run-mask1-01.png",
          "__base__/graphics/entity/biter/biter-run-mask1-02.png",
          "__base__/graphics/entity/biter/biter-run-mask1-03.png",
          "__base__/graphics/entity/biter/biter-run-mask1-04.png"
        },
        flags = {
          "mask"
        },
        frame_count = 16,
        height = 94,
        hr_version = {
          direction_count = 16,
          filenames = {
            "__base__/graphics/entity/biter/hr-biter-run-mask1-01.png",
            "__base__/graphics/entity/biter/hr-biter-run-mask1-02.png",
            "__base__/graphics/entity/biter/hr-biter-run-mask1-03.png",
            "__base__/graphics/entity/biter/hr-biter-run-mask1-04.png"
          },
          frame_count = 16,
          height = 182,
          line_length = 8,
          lines_per_file = 8,
          scale = 0.25,
          shift = {
            -0.015625,
            -0.578125
          },
          slice = 8,
          tint = nil,
          width = 238
        },
        line_length = 8,
        lines_per_file = 8,
        scale = 0.5,
        shift = {
          0,
          -0.59375
        },
        slice = 8,
        tint = nil,
        width = 118
      },
      {
        direction_count = 16,
        filenames = {
          "__base__/graphics/entity/biter/biter-run-mask2-01.png",
          "__base__/graphics/entity/biter/biter-run-mask2-02.png",
          "__base__/graphics/entity/biter/biter-run-mask2-03.png",
          "__base__/graphics/entity/biter/biter-run-mask2-04.png"
        },
        flags = {
          "mask"
        },
        frame_count = 16,
        height = 92,
        hr_version = {
          direction_count = 16,
          filenames = {
            "__base__/graphics/entity/biter/hr-biter-run-mask2-01.png",
            "__base__/graphics/entity/biter/hr-biter-run-mask2-02.png",
            "__base__/graphics/entity/biter/hr-biter-run-mask2-03.png",
            "__base__/graphics/entity/biter/hr-biter-run-mask2-04.png"
          },
          frame_count = 16,
          height = 184,
          line_length = 8,
          lines_per_file = 8,
          scale = 0.25,
          shift = {
            0,
            -0.59375
          },
          slice = 8,
          tint = nil,
          width = 232
        },
        line_length = 8,
        lines_per_file = 8,
        scale = 0.5,
        shift = {
          -0.03125,
          -0.59375
        },
        slice = 8,
        tint = nil,
        width = 120
      },
      {
        direction_count = 16,
        draw_as_shadow = true,
        filenames = {
          "__base__/graphics/entity/biter/biter-run-shadow-01.png",
          "__base__/graphics/entity/biter/biter-run-shadow-02.png",
          "__base__/graphics/entity/biter/biter-run-shadow-03.png",
          "__base__/graphics/entity/biter/biter-run-shadow-04.png"
        },
        frame_count = 16,
        height = 144,
        hr_version = {
          direction_count = 16,
          draw_as_shadow = true,
          filenames = {
            "__base__/graphics/entity/biter/hr-biter-run-shadow-01.png",
            "__base__/graphics/entity/biter/hr-biter-run-shadow-02.png",
            "__base__/graphics/entity/biter/hr-biter-run-shadow-03.png",
            "__base__/graphics/entity/biter/hr-biter-run-shadow-04.png"
          },
          frame_count = 16,
          height = 292,
          line_length = 8,
          lines_per_file = 8,
          scale = 0.25,
          shift = {
            0.125,
            -0.015625
          },
          slice = 8,
          width = 432
        },
        line_length = 8,
        lines_per_file = 8,
        scale = 0.5,
        shift = {
          0.125,
          0
        },
        slice = 8,
        width = 216
      }
    }
  },
  selection_box = {
    {
      -0.4,
      -0.7
    },
    {
      0.7,
      0.4
    }
  },
  subgroup = "enemies",
  type = "unit",
  vision_distance = 30,
  working_sound = {
    {
      filename = "__base__/sound/creatures/biter-call-1.ogg",
      volume = 0.3
    },
    {
      filename = "__base__/sound/creatures/biter-call-2.ogg",
      volume = 0.3
    },
    {
      filename = "__base__/sound/creatures/biter-call-3.ogg",
      volume = 0.3
    },
    {
      filename = "__base__/sound/creatures/biter-call-4.ogg",
      volume = 0.3
    },
    {
      filename = "__base__/sound/creatures/biter-call-5.ogg",
      volume = 0.3
    }
  }
}

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