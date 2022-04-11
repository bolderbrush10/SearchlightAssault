data:extend(
{
  {
    type = "font",
    name = "sla-semibold-outline",
    from = "default-semibold",
    size = 18,
    border = true,
    border_color = {0, 0, 0},
  },
})

local styles = data.raw["gui-style"].default

local safeGreenColor = {220/255, 255/255, 200/255}

styles["sla_titlebar_drag_handle"] = {
  type = "empty_widget_style",
  parent = "draggable_space",
  left_margin = 4,
  right_margin = 4,
  height = 24,
  horizontally_stretchable = "on",
}

styles["sla_signal_content_frame"] = {
    type = "frame_style",
    parent = "inside_shallow_frame_with_padding",
    vertically_stretchable = "on",
    vertical_align = "center",
}

styles["sla_content_frame"] = {
    type = "frame_style",
    parent = "inside_shallow_frame_with_padding",
    vertically_stretchable = "on",
    vertical_align = "center",
    top_padding = 0,
    bottom_padding = 0,
}

styles["sla_content_flow"] = {
    type = "vertical_flow_style",
    vertically_stretchable = "on",
    vertical_align = "center",
    padding = 0,
}

styles["sla_deep_frame"] = {
    type = "frame_style",
    parent = "deep_frame_in_shallow_frame",
    vertically_stretchable = "off",
    horizontally_stretchable = "off",
    top_margin = 8,
    left_margin = 8,
    right_margin = 8,
    bottom_margin = 4,
}

styles["sla_cam"] = {
  type = "camera_style",
  width=250,
  height=250,
  effect = "compilatron-hologram",
  -- fun fact: setting effect_opacity < 1 results in making the compilatron-hologram effect wobble like crazy
}

styles["sla_minimap"] = {
  type = "minimap_style",
  width=250,
  height=250,
}

styles["sla_preview"] = {
  type = "empty_widget_style",
  width=250,
  height=250,
}

styles["sla_line"] = {
    type = "line_style",
    top_margin = 4,
}

styles["sla_bold_label"] = {
    type = "label_style",
    parent = "bold_label",
    bottom_margin = 4,
}

styles["sla_signal_textfield"] = {
    type = "textbox_style",
    width = 80,
}

styles["sla_signal_textfield_tempdisable"] = {
    type = "textbox_style",
    width = 80,
    parent="console_input_textfield",
    font = "default",
}

styles["sla_label_frame_disabled"] = {
    type = "frame_style",
    parent = "bordered_frame",
    vertically_stretchable = "off",
    horizontally_stretchable = "off",
    right_padding = 5,
    left_padding = 5,
    top_padding = 3,
    bottom_padding = 3,
}

styles["sla_signal_label_disabled"] = {
    type = "label_style",
    width = 62,
}

styles["sla_circuit_icon"] = {
    type = "image_style",
    size = 24,
}

styles["sla_safe_frame"] = {
    type = "frame_style",
    parent = "unlocked_achievement_frame",
    width = 250,
    padding = 0,
    left_padding = 4,
    top_margin = 4,
    left_margin = 8,
    right_margin = 8,
}

styles["sla_safe_label"] = {
    type = "label_style",
    font = "default-large-semibold",
    parent = "achievement_percent_label",
    font_color = safeGreenColor,
}

styles["sla_warn_frame"] = {
    type = "frame_style",
    parent = "locked_achievement_frame",
    width = 250,
    padding = 0,
    left_padding = 4,
    top_margin = 4,
    left_margin = 8,
    right_margin = 8,
}

styles["sla_warn_label"] = {
    type = "label_style",
    font = "default-large-semibold",
    parent = "orange_label",
}

styles["sla_alarm_frame"] = {
    type = "frame_style",
    parent = "failed_achievement_frame",
    width = 250,
    padding = 0,
    left_padding = 4,
    top_margin = 4,
    left_margin = 8,
    right_margin = 8,
}

styles["sla_alarm_label"] = {
    type = "label_style",
    font = "sla-semibold-outline",
    font_color = {1, 0, 0},
    parent = "bold_red_label",
}

styles["sla_no_power_frame"] = {
    type = "frame_style",
    parent = "map_details_frame",
    width = 250,
    padding = 4,
    left_padding = 8,
    top_margin = 4,
    left_margin = 8,
    right_margin = 8,
}

styles["sla_no_power_label"] = {
    type = "label_style",
    font = "default-large-semibold",
    parent = "tooltip_heading_label_category",
}