require "defines"
require "entities"

local icon =
{
  filename = "__Searchlights__/graphics/terrible2.png",
  icon_size = 80
}

-- Item
local item = table.deepcopy(data.raw["item"]["small-lamp"])

item.name = "searchlight"
item.order = "a[small-lamp]-a[searchlight]"
item.place_result = searchlightBaseName
item.icon = icon.filename
item.icon_size = icon.icon_size

-- Recipe
local recipe = table.deepcopy(data.raw.recipe["small-lamp"])
recipe.enabled = true
recipe.name = "searchlight"
recipe.result = "searchlight"
recipe.result_count = 1
recipe.icon = icon.filename
recipe.icon_size = icon.icon_size
recipe.ingredients = {{"radar",1},{"small-lamp",5}}

-- Add definitions to game
data:extend{item, recipe}

-- Technology
table.insert(
  data.raw["technology"]["optics"].effects,
  {
    type = "unlock-recipe",
    recipe = "searchlight"
  }
)
