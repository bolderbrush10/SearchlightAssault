local d = require "sl-defines"

-- We'll add a shortcut to detect when a searchlight is clicked on.
-- As far as I can tell, this doesn't interfere with other hotkeys/shortcuts.
-- We'll also link our GUI to the main game's gui-close controls.
data:extend({
  {
    type = "custom-input",
    name = d.openSearchlightGUI,
    key_sequence = "",
    linked_game_control = "open-gui",
    include_selected_prototype = true,
  },
  {
    type = "custom-input",
    name = d.closeSearchlightGUI,
    key_sequence = "",
    linked_game_control = "confirm-gui",
    include_selected_prototype = false,
  },
  {
    type = "custom-input",
    name = d.closeSearchlightGUIalt,
    key_sequence = "",
    linked_game_control = "toggle-menu",
    include_selected_prototype = false,
  },
})