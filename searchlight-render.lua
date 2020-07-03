-- 'def' for 'default color'
function renderSpotLight_def(position, sl, surface)
    return renderSpotLight(position, sl, surface, nil)
end

function renderSpotLight_yel(position, sl, surface)
    return renderSpotLight(position, sl, surface, yellowSpotlightColor)
end

function renderSpotLight_red(position, sl, surface)
    return renderSpotLight(position, sl, surface, redSpotlightColor)
end

function renderSpotLight(position, sl, surface, colorparam)
    return rendering.draw_light{target = position,
                                orientation = sl.orientation,
                                surface = surface,
                                sprite = "spotLightSprite",
                                scale = 2,
                                intensity = 0.3,
                                time_to_live = 5,
                                color = colorparam}
end
