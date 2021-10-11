local d = require "sl-defines"

require "sl-entities"


local icon =
{
  filename = "__Searchlights__/graphics/spotlight-icon.png",
  icon_size = 64, icon_mipmaps = 4,
}


local item = {}
item.type = "item"
item.name = d.searchlightItemName
item.place_result = d.searchlightBaseName
item.subgroup = "defensive-structure"
item.order = "a[small-lamp]-a[searchlight]"
item.icon = icon.filename
item.icon_size = icon.icon_size
item.stack_size = 50


local ciItem = {}
ciItem.type = "item"
ciItem.name = d.searchlightSignalInterfaceName
ciItem.place_result = d.searchlightSignalInterfaceName
ciItem.flags = {"hidden"}
ciItem.icon = icon.filename
ciItem.icon_size = icon.icon_size
ciItem.stack_size = 50


local recipe = {}
recipe.type = "recipe"
recipe.name = d.searchlightRecipeName
recipe.result = d.searchlightItemName
recipe.order = "a[small-lamp]-a[searchlight]"
recipe.energy_required = 20
recipe.enabled = false
recipe.ingredients =
{
  {"radar",1},
  {"small-lamp",5},
  {"decider-combinator",2},
}


local t = {}
t.type = "technology"
t.name = d.searchlightTechnologyName
t.icon = icon.filename
t.icon_size = icon.icon_size
t.icon_mipmaps = 1
t.effects =
{
  {
    type = "unlock-recipe",
    recipe = d.searchlightRecipeName
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
data:extend{item, ciItem, recipe, t}
