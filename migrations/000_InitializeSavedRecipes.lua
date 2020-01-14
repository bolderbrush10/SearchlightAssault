for index, force in pairs(game.forces) do
    local technologies = force.technologies
    local recipes = force.recipes

    recipes["searchlight"].enabled = technologies["optics"].researched
end