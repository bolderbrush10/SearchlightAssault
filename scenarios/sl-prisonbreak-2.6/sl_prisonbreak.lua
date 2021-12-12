local util = require("util")
local crash_site = require("crash-site")

--[[
                    Max super-  Biter Drop-  Biter Drop-  Rocket Silo           SuperSpawn/Pod
                   spawn sites   Pod Start   Pod Period   Attack Period(TODO)    Biter Types   
Difficulty 0/1:        2             30          6            x                    small
Difficulty 2:          3             20          6            20                   small
Difficulty 3:          4             15          3            15                  +spitter
Difficulty 4:          5             2           1            5                   +medium / behemoth
]]--

-- TODO 0/1: 
-- TODO 2:   biters now seek rocket silos every 20 minutes (Strech goal)
-- TODO 3:   
-- TODO 4:   rocket silo waves every 5 minutes

local created_items = function()
  return
  {
    ["iron-stick"] = 1,
    ["raw-fish"] = 4,
  }
end


local respawn_items = function()
 if game.tick < 36000 then
    return
    {
      ["iron-stick"] = 1,
      ["raw-fish"] = 1,
    }
  else
    return
    {
      ["raw-fish"] = 4,
      ["submachine-gun"] = 1,
      ["piercing-rounds-magazine"] = 10,
    }    
  end
end


local ship_parts = function()
  return crash_site.default_ship_parts()
end


local on_player_created = function(event)
  local player = game.get_player(event.player_index)
  util.insert_safe(player, created_items())
  
  if global.pbreakDifficulty == nil then
    global.pbreakDifficulty = 0
  end
  
  if global.rocketSilos == nil then
    -- Find the initial rocket silo we placed during map editing
    local silos = player.surface.find_entities_filtered{name="rocket-silo"}
    global.rocketSilos = {}
    global.rocketSilos[silos[1].unit_number] = silos[1]
  end
  
  if global.labsay == nil then
    global.labsay = {}
  end
  
  -- Disable the repair pack recipe so players feel tension about keeping vehicles in shape
  game.forces["player"].recipes["repair-pack"].enabled = false

  if not global.init_ran then
    --This is so that other mods and scripts have a chance to do remote calls before we do things like creating the crash site, etc.
    global.init_ran = true

    if not global.disable_crashsite then
      local surface = player.surface
      crash_site.create_crash_site(surface, {-5,-6}, util.copy(global.crashed_ship_items), util.copy(global.crashed_debris_items), util.copy(global.crashed_ship_parts))
      util.remove_safe(player, global.crashed_ship_items)
      util.remove_safe(player, global.crashed_debris_items)
      player.get_main_inventory().sort_and_merge()
      return
    end    
  end

  if not global.skip_intro then
    player.print({"description"})
  end

end


local on_player_respawned = function(event)
  local player = game.get_player(event.player_index)
  util.insert_safe(player, respawn_items())
end


local getRandTile = function(tries, area)
  local s = game.surfaces[1]
  
  for tries=1, tries do
    local randPos = nil
    
    if area == nil then
      local chunkPos = s.get_random_chunk()
      local tilePosX = math.random(0, 31)    
      local tilePosY = math.random(0, 31)
      randPos = {x=(chunkPos.x * 32 + tilePosX), y=(chunkPos.y * 32 + tilePosY)}
    else
      local tilePosX = math.random(area.left_top.x, area.right_bottom.x)
      local tilePosY = math.random(area.left_top.y, area.right_bottom.y)
      randPos = {x=tilePosX, y=tilePosY}
    end    
  
    if not s.get_tile(randPos).collides_with("player-layer") then
      return randPos
    end
  end
  
  return nil
end


local tryRandExpand = function(area)
  local randPos = getRandTile(10, area)
  
  if not randPos then
    return 0
  end
  
  local s = game.surfaces[1]
  local result = s.set_multi_command{command={type=defines.command.build_base, destination=randPos, ignore_planner=true}, unit_count=100}
  
  return result
end


local initRandPositions = function()
  local flip = {-1, 1}
  global.randBiterPositions = {}
  
  for i=1, 30 do
    local pos = {x=0,y=0}
    pos.x = (math.random(2,5) + math.random() + 0.1) * flip[math.random(1,2)]
    pos.y = (math.random(3,6) + math.random() + 0.1) * flip[math.random(1,2)]
    global.randBiterPositions[i] = pos
  end
end


local spawnBiters = function(nest)
  if nest == nil or not nest.valid then
    return
  end
  
  local s = game.surfaces[1]

  local behemoth = math.random(1, 500)
  
  for i, offset in pairs(global.randBiterPositions) do
    local posX = nest.position.x + offset.x
    local posY = nest.position.y + offset.y
    
    if not s.get_tile({posX, posY}).collides_with("player-layer") then
      local e = nil
      if global.pbreakDifficulty > 2 and i % 2 == 0 then
        e = s.create_entity{name="small-spitter", position={posX, posY}}
      elseif global.pbreakDifficulty > 3 and i % 3 == 0 then
        if behemoth == 1 then        
          e = s.create_entity{name="behemoth-biter", position={posX, posY}}
          behemoth = 0
        elseif behemoth == 2 then
          e = s.create_entity{name="behemoth-spitter", position={posX, posY}}
          behemoth = 0
        else
          e = s.create_entity{name="medium-biter", position={posX, posY}}
        end
      else    
        e = s.create_entity{name="small-biter", position={posX, posY}}
      end
      e.release_from_spawner()
    end
  end
end


local lensquared = function(a, b)
  return (a.x - b.x)^2 + (a.y - b.y)^2
end


local compareNests = function(leftArea, rightArea)
  local pos = {0,0}
  local _, rocket = next(global.rocketSilos)
  if rocket then
    pos = rocket.position
  end
  
  return lensquared(leftArea.right_bottom, pos) < lensquared(rightArea.right_bottom, pos)
end


local updateSuperNests = function()
  local s = game.surfaces[1]
  
  if global.biterAreas == nil then
    global.biterAreas = {s.get_script_area("central-biters").area,
                         s.get_script_area("northeast-biters").area,
                         s.get_script_area("north-biters").area,
                         s.get_script_area("west-biters").area,
                         s.get_script_area("south-biters").area,
                         s.get_script_area("southeast-biters").area,
                         s.get_script_area("east-biters").area,
                         s.get_script_area("rocket-biters").area,
                        }
                        
    global.superSpawnNests = {}
  end

  -- Perodically cycle super-spawning through new nests so bunches of biters don't clump up too badly
  local tickmod = game.tick % (60*60)
  if tickmod == 0 then
    global.superSpawnNests = {}    
    table.sort(global.biterAreas, compareNests)
  end
    
  local max = global.pbreakDifficulty + 1
  if max == 1 then max = 2 end -- treat difficulty 0 as 1
  if max == 5 then max = #global.biterAreas end
      
  -- We want to assign only one super-spawner nest per area, priortizing the ones closest to the rocket / center of the map
  -- (If a super spawner nest gets destroyed, there's a chance there'll be multiple super-spawner nests
  --  in an area until the perodic reset of all super spawn nests is done every minute, but that's fine)
  for _, area in pairs(global.biterAreas) do
    for i = 1, max do     
    
      if global.superSpawnNests[i] == nil or not global.superSpawnNests[i].valid then
        local nests = s.find_entities_filtered{area=area, type="unit-spawner", force="enemy", limit=10}
        if #nests > 0 then
          global.superSpawnNests[i] = nests[math.random(1, #nests)]
          break
        end
      end
      
    end
  end

  for i = 1, max do
    spawnBiters(global.superSpawnNests[i])
  end  
end


local aggressiveBiterExpand = function()  
  if global.randBiterPositions == nil then
    initRandPositions()
  end
  
  updateSuperNests()
    
  local count = 0
  for i, area in pairs(global.biterAreas) do
    for tries=1, 3 do
      count = count + tryRandExpand(area)
    end
  end
  
  for tries=1, 5 do
    count = count + tryRandExpand()
    if count > 1200 then
      return
    end
  end  
end


local loottable_common = 
{
  {name = "fusion-reactor-equipment",         count = "1"},
  {name = "battery-equipment",                count = "1"},
  {name = "exoskeleton-equipment",            count = "1"},
  {name = "personal-roboport-equipment",      count = "1"},
  {name = "night-vision-equipment",           count = "1"},
  {name = "energy-shield-equipment",          count = "1"},
  {name = "personal-laser-defense-equipment", count = "1"},
  {name = "discharge-defense-equipment",      count = "1"},
  {name = "discharge-defense-remote",         count = "1"},
  {name = "construction-robot",               count = "1"},
  {name = "repair-pack",                      count = "2"},
  {name = "explosive-rocket",                 count = "16"},
}

local loottable_rare = 
{
  {name = "battery-mk2-equipment",            count = "1"},
  {name = "energy-shield-mk2-equipment",      count = "1"},
  {name = "belt-immunity-equipment",          count = "1"},
  {name = "personal-roboport-mk2-equipment",  count = "1"},
}

local insertPodBonusItem = function(pod)
  for i=1, math.random(1, 5) do
    local roll = math.random(1, #loottable_common + 1)
    if roll > #loottable_common then
      pod.get_inventory(defines.inventory.chest).insert(loottable_rare[math.random(1, #loottable_rare)])
    else
      pod.get_inventory(defines.inventory.chest).insert(loottable_common[roll])
    end
  end
end


-- 60 ticks per second * 60 seconds per min * X minutes
local dropStarts = 
{
  60 * 60 * 30,
  60 * 60 * 20,
  60 * 60 * 15,
  60 * 60 * 2 
}

local dropPeriods = 
{
  60 * 60 * 6,
  60 * 60 * 6,
  60 * 60 * 3,
  60 * 60 * 1 
}


local dropBiterCapsules = function()  
  local t = game.tick
  
  local difficulty = global.pbreakDifficulty
  if difficulty == 0 then difficulty = 1 end
  
  if t < dropStarts[difficulty] or t % dropPeriods[difficulty] ~= 0 then
    return
  end
  
  local s = game.surfaces[1]
  
  for i=1, #game.forces["Smugglers"].players + 1 do
    local randPos = getRandTile(100)
      
    firepos = randPos
    firepos.x = firepos.x - 0.3
    pos = randPos
    pos.y = pos.y + 0.6
    
    s.create_entity{name = "crash-site-fire-flame", position = firepos}
    s.create_entity{name = "crash-site-fire-smoke", position = firepos}
    s.create_entity{name = "big-artillery-explosion", position = pos}
    chest = s.create_entity{name = "crash-site-chest-1", position = randPos, force = "Smugglers"}
    
    insertPodBonusItem(chest)  
    game.forces["Smugglers"].add_chart_tag(1, {position = randPos, text="specimen pod"})

    local box = chest.bounding_box
    for k, entity in pairs (s.find_entities_filtered{area = box, collision_mask = "player-layer"}) do
      if entity.valid and entity ~= chest then
          entity.die()
      end
    end
    
    box.left_top.x = box.left_top.x - 1.2
    box.left_top.y = box.left_top.y - 1.2
    box.right_bottom.x = box.right_bottom.x + 1.2
    box.right_bottom.y = box.right_bottom.y + 1.2
    for k, entity in pairs (s.find_entities_filtered{area = box, collision_mask = "player-layer"}) do
      if entity.valid then
        entity.damage(120, "neutral")
      end
    end
       
    spawnBiters(chest)    
  end
end


local siloWaveStartDifficulty2 = 60 * 60 * 20
--local siloWaveStartDifficulty4 = sendRocketSiloWave should already only be getting called every 5 minutes 

-- TODO Stretch goal
local sendRocketSiloWave = function()
  local t = game.tick
  if global.pbreakDifficulty < 2 then
    return
  elseif global.pbreakDifficulty < 4 and t % siloWaveStartDifficulty2 ~= 0 then
    return
  end
    
  -- Prefer to attack the rocket with the most progress
  local maxSilo = nil
  for unit_num, silo in pairs(global.rocketSilos) do
    if not silo.valid then
      global.rocketSilos[unit_num] = nil
    elseif maxSilo == nil or silo.rocket_parts > maxSilo.rocket_parts then
      maxSilo = silo
    end
  end
  
  if not maxSilo then
    return
  end
  
  -- TODO create unit groups from existing biters or spawn some in just for this?
  --      Unit groups are less trivial to create from existing sources than I'd hoped...
end


local checkForBuiltRocketSilo = function(event)
  local entity = nil
  if event.created_entity then
    entity = event.created_entity
  else
    entity = event.entity
  end
  
  if entity.name ~= "rocket-silo" then
    return
  end
  
  global.rocketSilos[entity.unit_number] = entity
end


local inArea = function(p, a)
  if p.x < a.left_top.x then
    return false
  end
  if p.y < a.left_top.y then
    return false
  end
  if p.x > a.right_bottom.x then
    return false
  end
  if p.y > a.right_bottom.y then
    return false
  end
  
  return true
end


local labAccesses = nil
local labAreas = nil


local checkAccessGranted = function(player)
  if labAccesses == nil then
    local s = game.surfaces[1]
    
    labAccesses = {}
    labAccesses[1] = s.get_script_area("CombatLabAccess").area
    labAccesses[2] = s.get_script_area("ControlLabAccess").area
    labAccesses[3] = s.get_script_area("RocketLabAccess").area
  end
  
  for i, area in pairs(labAccesses) do
    if inArea(player.position, area) then
      if global.labsay[i .. player.name] == nil then
        global.labsay[i .. player.name] = true
        game.print("Facility Emergency Access Granted: " .. player.name)
      end
      
      player.force = "Wardens"
      return
    end
  end
end


local checkAccessRevoked = function(player)
  if labAreas == nil then  
    local s = game.surfaces[1]
    
    labAreas = {}    
    labAreas[1] = s.get_script_area("CombatLabAccess").area
    labAreas[2] = s.get_script_area("RocketLabAccess").area
    labAreas[3] = s.get_script_area("ControlLab1").area
    labAreas[4] = s.get_script_area("ControlLab2").area
    labAreas[5] = s.get_script_area("ControlLab3").area
    labAreas[6] = s.get_script_area("ControlLab4").area
  end
  
  for _, area in pairs(labAreas) do
    if inArea(player.position, area) then
      return  
    end
  end
  
  -- TODO reenable when done testing
  --player.force = "player"
end


local checkLabAccess = function(event)
  for _, p in pairs(game.players) do
    if p.force.name == "Wardens" then
      checkAccessRevoked(p)      
    elseif p.force.name == "player" then
      checkAccessGranted(p)      
    end    
  end
end


local on_entity_died = function(event)
  if event.entity.name ~= "compilatron" then
    return
  end
  
  global.pbreakDifficulty = global.pbreakDifficulty + 1
  
  if global.pbreakDifficulty == 1 then
    game.print("Danger! Dead Compilatron units are unable to help calm biter aggression.\n" ..
               "Further destruction of Compilatron units will result in increased difficulty of escape!\n" ..
               "Level 1: Difficulty acceptable for 1-2 prisoners.\n"..
               "Level 2: Difficulty acceptable for 3-6 prisoners.\n"..
               "Level 3: Difficulty acceptable for ~12 prisoners.\n"..
               "Level 4: All Compilatron calming units destroyed. Survival unlikely.\n")
  end
  
  if global.pbreakDifficulty == 4 then
    game.print("Difficulty level: Brutal")
  else
    game.print("Difficulty level: " .. global.pbreakDifficulty)
  end      
end


local on_cutscene_waypoint_reached = function(event)
  return 
end


local skip_crash_site_cutscene = function(event)
  return
end


local on_cutscene_cancelled = function(event)
  return
end


local on_player_display_refresh = function(event)
  crash_site.on_player_display_refresh(event)
end


local pbreak_interface =
{
  get_created_items = function()
    return global.created_items
  end,
  set_created_items = function(map)
    global.created_items = map or error("Remote call parameter to freeplay set created items can't be nil.")
  end,
  get_respawn_items = function()
    return global.respawn_items
  end,
  set_respawn_items = function(map)
    global.respawn_items = map or error("Remote call parameter to freeplay set respawn items can't be nil.")
  end,
  set_skip_intro = function(bool)
    global.skip_intro = bool
  end,
  get_skip_intro = function()
    return global.skip_intro
  end,
  set_chart_distance = function(value)
    global.chart_distance = tonumber(value) or error("Remote call parameter to freeplay set chart distance must be a number")
  end,
  get_disable_crashsite = function()
    return global.disable_crashsite
  end,
  set_disable_crashsite = function(bool)
    global.disable_crashsite = bool
  end,
  get_init_ran = function()
    return global.init_ran
  end,
  get_ship_items = function()
    return global.crashed_ship_items
  end,
  set_ship_items = function(map)
    global.crashed_ship_items = map or error("Remote call parameter to freeplay set created items can't be nil.")
  end,
  get_debris_items = function()
    return global.crashed_debris_items
  end,
  set_debris_items = function(map)
    global.crashed_debris_items = map or error("Remote call parameter to freeplay set respawn items can't be nil.")
  end,
  get_ship_parts = function()
    return global.crashed_ship_parts
  end,
  set_ship_parts = function(parts)
    global.crashed_ship_parts = parts or error("Remote call parameter to freeplay set ship parts can't be nil.")
  end
}


if not remote.interfaces["pbreak"] then
  remote.add_interface("pbreak", pbreak_interface)
end


local is_debug = function()
  local surface = game.surfaces.nauvis
  local map_gen_settings = surface.map_gen_settings
  return map_gen_settings.width == 50 and map_gen_settings.height == 50
end


local pbreak = {}


pbreak.events =
{
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_player_respawned] = on_player_respawned,
  [defines.events.on_cutscene_waypoint_reached] = on_cutscene_waypoint_reached,
  ["crash-site-skip-cutscene"] = skip_crash_site_cutscene,
  [defines.events.on_player_display_resolution_changed] = on_player_display_refresh,
  [defines.events.on_player_display_scale_changed] = on_player_display_refresh,
  [defines.events.on_cutscene_cancelled] = on_cutscene_cancelled,
  [defines.events.on_entity_died] = on_entity_died,
  [defines.events.on_tick] = checkLabAccess,
  
  [defines.events.on_built_entity          ] = checkForBuiltRocketSilo,
  [defines.events.on_robot_built_entity    ] = checkForBuiltRocketSilo,
  [defines.events.script_raised_built      ] = checkForBuiltRocketSilo,
  [defines.events.script_raised_revive     ] = checkForBuiltRocketSilo,
  [defines.events.on_trigger_created_entity] = checkForBuiltRocketSilo,
}


pbreak.on_nth_tick =
{
  [300] = aggressiveBiterExpand,
  [3600] = dropBiterCapsules,
  [18000] = sendRocketSiloWave,
}


pbreak.on_configuration_changed = function()
  global.created_items = global.created_items or created_items()
  global.respawn_items = global.respawn_items or respawn_items()
  global.crashed_ship_items = global.crashed_ship_items or ship_items()
  global.crashed_debris_items = global.crashed_debris_items or debris_items()
  global.crashed_ship_parts = global.crashed_ship_parts or ship_parts()

  if not global.init_ran then
    -- migrating old saves.
    global.init_ran = #game.players > 0
  end
end


pbreak.on_init = function()
  global.created_items = created_items()
  global.respawn_items = respawn_items()
  global.crashed_ship_items = {}
  global.crashed_debris_items = {}
  global.crashed_ship_parts = ship_parts()

  if is_debug() then
    global.skip_intro = true
    global.disable_crashsite = true
  end

end


return pbreak
