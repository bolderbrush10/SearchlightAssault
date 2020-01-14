    game.print("hello world")
    for key,value in pairs(o) do
        game.print("found member " .. key);
    end


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