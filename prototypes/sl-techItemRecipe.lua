require "sl-defines"
require "sl-entities"


local icon =
{
  filename = "__Searchlights__/graphics/terrible2.png",
  icon_size = 80
}


-- Item
local item = {}
item.type = "item"
item.stack_size = 50
item.name = searchlightItemName
item.subgroup = "defensive-structure"
item.order = "a[small-lamp]-a[searchlight]"
item.place_result = searchlightBaseName
item.icon = icon.filename
item.icon_size = icon.icon_size


-- Recipe
local recipe = {}
recipe.type = "recipe"
recipe.name = searchlightRecipeName
recipe.result = searchlightItemName
recipe.order = "a[small-lamp]-a[searchlight]"
recipe.energy_required = 20
recipe.enabled = false
recipe.ingredients =
{
  {"radar",1},
  {"small-lamp",5},
  {"decider-combinator",2},
}


-- Technology
local t = {}
t.type = "technology"
t.name = searchlightTechnologyName
t.icon = icon.filename
t.icon_size = icon.icon_size
t.icon_mipmaps = 1
t.effects =
{
  {
    type = "unlock-recipe",
    recipe = searchlightRecipeName
  }
}
t.prerequisites = {"optics", "circuit-network"}
t.unit =
{
  count = 125,
  ingredients =
  {
    {"automation-science-pack", 1},
    {"logistic-science-pack", 1}
  },
  time = 15
}
t.order = "s-o-a"


-- Add definitions to game
data:extend{item, recipe, t}
