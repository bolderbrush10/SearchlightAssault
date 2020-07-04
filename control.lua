require "searchlight-defines"
require "searchlight-render"

local searchLights = {}
local dummies = {}

script.on_event(defines.events.on_tick, function(event)
    for surfaceName, surface in pairs(game.surfaces) do
        searchLights = surface.find_entities_filtered{name = "searchlight"}

        for index, sl in pairs(searchLights) do
            LightUpFoes(sl, surface)
        end
    end
end)

-- 'sl' for 'SearchLight'
function LightUpFoes(sl, surface)
    -- Instantly find foes within the inner range
    local foe = sl.shooting_target

    if foe ~= nil then
        --renderSpotLight_red(foe.position, sl, surface)
    else
        sl.shooting_target = SpawnDummy(sl.position, surface)
        -- renderSpotLight_red(sl.position, sl, surface)
    end

end

function SpawnDummy(position, surface)
    local newPos = position
    newPos.x = newPos.x + 5
    return surface.create_entity{name = "DummyEntity",
                                 position = position,
                                 force = searchlightFoe}
end