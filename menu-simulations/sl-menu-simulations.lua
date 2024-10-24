data.raw["utility-constants"]["default"].main_menu_simulations.sl_sweep =
{
  checkboard = false,
  save = "__SearchlightAssault__/menu-simulations/sl-map-sweep.zip",
  length = 60 * 9,
  init =
  [[
    local logo = game.surfaces.nauvis.find_entities_filtered{name = "factorio-logo-11tiles", limit = 1}[1]
    logo.destructible = false
    game.simulation.camera_position = {logo.position.x, logo.position.y+9.75}
    center = {logo.position.x, logo.position.y+9.75}
    game.simulation.camera_zoom = 1
    game.tick_paused = false
    game.surfaces.nauvis.daytime = 0.4
  ]]
}
