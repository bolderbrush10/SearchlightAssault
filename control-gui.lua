-- The strategy in this file is to split up GUI handling in two phases:
-- First, we build a skeleton GUI, only adding static details
-- Second, we update the GUI for real and fill out dynamic details
-- After that, we can change the dynamic details using various updateFunctions as relevant

local mod_gui = require("mod-gui")

local d = require "sl-defines"

local cgui = {}

local ENABLED = 1
local DISABLED = 2
local TEMPDISABLED = 3

local STATUS_ALARM = 1
local STATUS_WARN = 2
local STATUS_SAFE = 3
local STATUS_NOPOWER = 4

local GuardSignals =
{
  d.circuitSlots.dirXSlot,
  d.circuitSlots.dirYSlot,
}

local PatrolSignals =
{
  d.circuitSlots.rotateSlot,
  d.circuitSlots.radiusSlot,
  d.circuitSlots.minSlot,   
  d.circuitSlots.maxSlot,   
}

local OutputSignals =
{
  d.circuitSlots.ownPositionXSlot,
  d.circuitSlots.ownPositionYSlot,
  d.circuitSlots.warningSlot,     
  d.circuitSlots.alarmSlot,       
  d.circuitSlots.foePositionXSlot,
  d.circuitSlots.foePositionYSlot,
}

local SlotToName = {}
SlotToName[d.circuitSlots.dirXSlot] = "sl-x"
SlotToName[d.circuitSlots.dirYSlot] = "sl-y"
SlotToName[d.circuitSlots.rotateSlot] = "sl-rotation"
SlotToName[d.circuitSlots.radiusSlot] = "sl-radius"
SlotToName[d.circuitSlots.minSlot] = "sl-minimum"
SlotToName[d.circuitSlots.maxSlot] = "sl-maximum"
SlotToName[d.circuitSlots.ownPositionXSlot] = "sl-own-x"
SlotToName[d.circuitSlots.ownPositionYSlot] = "sl-own-y"
SlotToName[d.circuitSlots.warningSlot] = "sl-warn"
SlotToName[d.circuitSlots.alarmSlot] = "sl-alarm"
SlotToName[d.circuitSlots.foePositionXSlot] = "foe-x-position"
SlotToName[d.circuitSlots.foePositionYSlot] = "foe-y-position"


cgui.InitTables_GUI = function()
  -- GUIs are persisted in many circumstances,
  -- so we must manage many aspects of them.

  -- Map: playerIndex -> {gestaltID, GUI}
  global.pIndexToGUI = {}
end


local function addSignal(t, g, sigIndex, control)
  local count = control.get_signal(sigIndex).count

  local sigName = SlotToName[sigIndex]

  local text = t.add{name="sla_gui_" .. sigName,
                     type="textfield",
                     text=tostring(count),
                     numeric = true,
                     tags = {sigIndex = sigIndex},
                     allow_decimal = false,
                     allow_negative = true,
                     clear_and_focus_on_right_click = true,}

  t.add{type="sprite-button",
        name="sla_gui_signal_circuit_status" .. sigName,}

  t.add{type="sprite-button",
        name="sla_gui_signal_count_button" .. sigName,
        sprite="virtual-signal/" .. sigName,
        tooltip={"virtual-signal-name." .. sigName}}

  t.add{type="label", 
        caption={"sla.sla-gui-" .. sigName},}
end


local function addSigTable(flow, name, label)
  local label = flow.add{type="label",
                         caption=label,
                         style="sla_bold_label"}

  local sigDirectTable = flow.add{type="table",
                                  name=name,
                                  column_count=4,
                                  draw_vertical_lines=false,
                                  draw_horizontal_line=false,}
  return sigDirectTable
end


local function addContentLeft(contentFlow, g)
  local leftFrame = contentFlow.add{type="frame",
                                    direction="vertical", 
                                    style="sla_signal_content_frame",}

  local control = g.signal.get_control_behavior()

  local sigDirectTable = addSigTable(leftFrame, "sla-gui-table-guard", {"sla.sla-gui-direct"})
  for _, s in pairs(GuardSignals) do
    addSignal(sigDirectTable, g, s, control)
  end

  leftFrame.add{type="line", style="sla_line"}

  local sigPatrolTable = addSigTable(leftFrame, "sla-gui-table-patrol", {"sla.sla-gui-patrol"})

  for _, s in pairs(PatrolSignals) do
    addSignal(sigPatrolTable, g, s, control)
  end

  leftFrame.add{type="line", style="sla_line"}

  local sigOutputTable = addSigTable(leftFrame, "sla-gui-table-output", {"sla.sla-gui-output"})

  for _, s in pairs(OutputSignals) do
    addSignal(sigOutputTable, g, s, control)
  end
end


local function addModeLabel(frame)
  local modeFrame = frame.add{type="frame", 
                              direction="vertical",}

  modeFrame.add{type="label",}
end


local function addContentRight(contentFlow, g)
  local frameRight = contentFlow.add{type="frame",
                                       direction="vertical", 
                                       style="sla_content_frame",}

  local contentRight = frameRight.add{type="flow",
                                      direction="vertical", 
                                      style="sla_content_flow",}

  local preview_frame = contentRight.add{type="frame", 
                                         direction="horizontal", 
                                         style="sla_deep_frame",}

  local sl_preview = preview_frame.add{type="entity-preview",
                                       style="sla_preview"}

  addModeLabel(contentRight)

  local camera_frame = contentRight.add{type="frame", 
                                        direction="horizontal", 
                                        style="sla_deep_frame",}
end


local function create(main_gui, g)
  local main_frame = main_gui.add{type="frame", name=d.guiName, direction="vertical",}
  main_frame.force_auto_center()

  local title_flow = main_frame.add{type = "flow", name = "titlebar",}
  title_flow.add{type = "label", style = "frame_title", caption = {"sla.sla-gui-main"},}
  title_flow.add{type = "empty-widget", style = "sla_titlebar_drag_handle",}
  title_flow.add{type = "sprite-button",
                 name = d.guiClose,
                 tooltip = {"gui.close-instruction"},
                 style = "frame_action_button",
                 sprite = "utility/close_white",
                 hovered_sprite = "utility/close_black",
                 clicked_sprite = "utility/close_black",}

  title_flow.children[1].drag_target = main_frame
  title_flow.children[2].drag_target = main_frame

  local contentFlow = main_frame.add{type="flow",
                                     direction="horizontal",}

  addContentLeft(contentFlow, g)
  addContentRight(contentFlow, g)

  return main_frame
end


local function fixFrameType(t, sigGUI, sigName, count)
  if sigGUI.type ~= "frame" then 
    local index = sigGUI.get_index_in_parent()
    sigGUI.destroy()

    local frame = t.add{name="sla_gui_" .. sigName,
                        type="frame", 
                        index=index,
                        direction="horizontal", 
                        style="sla_label_frame_disabled",}

    local text = frame.add{type="label", 
                           caption=count,
                           style="sla_signal_label_disabled",}

    return false
  end

  return true
end


local function fixFlowType(t, sigGUI, sigName)
  if sigGUI.type ~= "textfield" then 
    local parentIndex = sigGUI.get_index_in_parent()
    local tags = {sigIndex = sigGUI.tags.sigIndex}
    sigGUI.destroy()

    local text = t.add{name="sla_gui_" .. sigName,
                       type="textfield", 
                       tags=tags,
                       index=parentIndex,
                       tooltip={"sla.sla-overruled-by-guard-cmd"},
                       numeric = true,
                       allow_decimal = false,
                       allow_negative = true,
                       clear_and_focus_on_right_click = true,}

    return text
  end

  return sigGUI
end


local function updateSignal(t, connected, control, gSig, sigIndex, inputState)
  local signal = control.get_signal(sigIndex)
  local sigName = signal.signal.name
  local localCount = signal.count
  local networkCount = gSig.get_merged_signal(signal.signal)
  local totalCount = localCount

  local sigGUI = t["sla_gui_" .. sigName]

  if inputState == DISABLED then
    if fixFrameType(t, sigGUI, sigName, localCount) then
      sigGUI.children[1].caption = localCount
    end
  elseif inputState == TEMPDISABLED then
    sigGUI = fixFlowType(t, sigGUI, sigName, localCount)
    sigGUI.tooltip = {"sla.sla-overruled-by-guard-cmd"}
    sigGUI.style = "sla_signal_textfield_tempdisable"
  else
    sigGUI = fixFlowType(t, sigGUI, sigName, localCount)
    sigGUI.tooltip = {"sla.sla-right-click-to-clear"}
    sigGUI.style = "sla_signal_textfield"
  end

  -- Circuit Status Sprite
  local css = t["sla_gui_signal_circuit_status" .. sigName]

  if connected and networkCount ~= localCount then
    totalCount = networkCount
    css.sprite = "utility/circuit_network_panel_white"
    css.tooltip = {"sla.sla-gui-sig-modified"}
  elseif connected then
    css.sprite = "utility/circuit_network_panel_black"
    css.tooltip = {"sla.sla-gui-sig-not-altered"}
  else
    css.sprite = "utility/hand_black"
    css.tooltip = {"sla.sla-gui-sig-manual"}
  end

  local sigButton = t["sla_gui_signal_count_button" .. sigName]
  sigButton.number = totalCount
end


local function updateSigTables(leftFlow, g)
  local connected = (g.signal.get_circuit_network(defines.wire_type.red)
                  or g.signal.get_circuit_network(defines.wire_type.green))

  local gSig = g.signal
  local control = gSig.get_control_behavior()
  local xSignal = control.get_signal(d.circuitSlots.dirXSlot)
  local ySignal = control.get_signal(d.circuitSlots.dirYSlot)
  local xMerged = gSig.get_merged_signal(xSignal.signal)
  local yMerged = gSig.get_merged_signal(ySignal.signal)

  local disablePatrol = TEMPDISABLED
  if      xSignal.count == 0 and xMerged == 0 
      and ySignal.count == 0 and yMerged == 0 then
    disablePatrol = ENABLED
  end

  local sigTable = leftFlow["sla-gui-table-guard"]
  for _, s in pairs(GuardSignals) do
    updateSignal(sigTable, connected, control, gSig, s, ENABLED)
  end

  sigTable = leftFlow["sla-gui-table-patrol"]
  for _, s in pairs(PatrolSignals) do
    updateSignal(sigTable, connected, control, gSig, s, disablePatrol)
  end

  sigTable = leftFlow["sla-gui-table-output"]
  for _, s in pairs(OutputSignals) do
    updateSignal(sigTable, connected, control, gSig, s, DISABLED)
  end
end


local function updateCamera(cam, g)
  local turtle = g.turtle
  cam.entity = turtle
end


local function checkStatus(g)
  local control = g.signal.get_control_behavior()
  local alarmSig = control.get_signal(d.circuitSlots.alarmSlot)
  local warnSig = control.get_signal(d.circuitSlots.warningSlot)

  if g.light.energy <= 0 then
    return STATUS_NOPOWER
  elseif alarmSig.count > 0 then
    return STATUS_ALARM
  elseif warnSig.count > 0 then
    return STATUS_WARN
  else
    return STATUS_SAFE
  end
end


local function updateModeStatus(rightContent, g)
  local status = checkStatus(g)

  local rightFrame = rightContent.children[1]
  local modeFrame = rightFrame.children[2]
  local label = modeFrame.children[1]

  if status == STATUS_NOPOWER then
    modeFrame.style   = "sla_no_power_frame"
    modeFrame.tooltip = {"sla.sla-gui-status-unpowered-tt"}
    label.tooltip     = {"sla.sla-gui-status-unpowered-tt"}
    label.caption     = {"sla.sla-gui-status-unpowered"}
    label.style       = "sla_no_power_label"
  elseif status == STATUS_ALARM then
    modeFrame.style   = "sla_alarm_frame"
    modeFrame.tooltip = {"sla.sla-gui-status-alarm-tt"}
    label.tooltip     = {"sla.sla-gui-status-alarm-tt"}
    label.caption     = {"sla.sla-gui-status-alarm"}
    label.style       = "sla_alarm_label"
  elseif status == STATUS_WARN then
    modeFrame.style   = "sla_warn_frame"
    modeFrame.tooltip = {"sla.sla-gui-status-warn-tt"}
    label.tooltip     = {"sla.sla-gui-status-warn-tt"}
    label.caption     = {"sla.sla-gui-status-warn"}
    label.style       = "sla_warn_label"
  else
    if g.light.name == d.searchlightSafeName then
      modeFrame.style   = "sla_safe_frame"
    else
      modeFrame.style   = "sla_warn_frame"
    end
    modeFrame.tooltip = {"sla.sla-gui-status-safe-tt"}
    label.tooltip     = {"sla.sla-gui-status-safe-tt"}
    label.caption     = {"sla.sla-gui-status-safe"}
    label.style       = "sla_safe_label"
  end

  local camFrame = rightFrame.children[3]
  local cam = camFrame.children[1]

  if      (status == STATUS_SAFE or status == STATUS_NOPOWER) 
      and (not cam or cam.type ~= "minimap") then
    if cam then
      cam.destroy()
    end

    cam = camFrame.add{name="sla_map", 
                       type="minimap",
                       zoom=1.25,
                       position=g.light.position,
                       surface=g.light.surface,
                       style="sla_minimap",}
  elseif  (status == STATUS_WARN or status == STATUS_ALARM) 
      and (not cam or cam.type ~= "camera") then
    if cam then
      cam.destroy()
    end

    local turtle = g.turtle

    cam = camFrame.add{name="sla_camera", 
                       type="camera",
                       zoom=0.75,
                       position=turtle.position,
                       surface=turtle.surface,
                       style="sla_cam",}

    updateCamera(cam, g)
  end
end


local function readSignals(t, control)
  for _, child in pairs(t.children) do
    if child.type == "textfield" then
      local signal = control.get_signal(child.tags.sigIndex)
      signal.count = tonumber(child.text) or 0
      control.set_signal(child.tags.sigIndex, signal)
    end
  end
end


local function updateEntitiesInGUI(g, GUI)
  local contentFlow = GUI.children[2]
  local rightFrame = contentFlow.children[2]
  local rightContent = rightFrame.children[1]

  local previewFrame = rightContent.children[1]
  local preview = previewFrame.children[1]
  preview.entity = g.light

  local camFrame = rightContent.children[3]
  local cam = camFrame.children[1]
  if cam.type == "camera" then
    updateCamera(cam, g)
  end
end


local function updateForTextFieldInGUI(g, GUI)
  local contentFlow = GUI.children[2]
  local leftFlow = contentFlow.children[1]

  local control = g.signal.get_control_behavior()

  readSignals(leftFlow["sla-gui-table-guard"], control)
  readSignals(leftFlow["sla-gui-table-patrol"], control)

  updateSigTables(leftFlow, g)
end


local function updateForRotation(g, GUI)
  local contentFlow = GUI.children[2]
  local leftFlow = contentFlow.children[1]

  local control = g.signal.get_control_behavior()
  local rotateSig = control.get_signal(d.circuitSlots.rotateSlot)

  local rotateText = leftFlow["sla-gui-table-patrol"]["sla_gui_" .. rotateSig.signal.name]
  rotateText.text = tostring(rotateSig.count)

  local dirXSig = control.get_signal(d.circuitSlots.dirXSlot)
  local dirYSig = control.get_signal(d.circuitSlots.dirYSlot)

  local dirXText = leftFlow["sla-gui-table-guard"]["sla_gui_" .. dirXSig.signal.name]
  dirXText.text = tostring(dirXSig.count)
  local dirYText = leftFlow["sla-gui-table-guard"]["sla_gui_" .. dirYSig.signal.name]
  dirYText.text = tostring(dirYSig.count)
end


cgui.validateGUI = function(GUI)
  if GUI and GUI.valid and GUI.name == d.guiName then
    return true
  else
    return false
  end
end


cgui.validatePlayerAndLight = function(pIndex, gID)
  return game.players[pIndex] and game.players[pIndex].valid and global.gestalts[gID]
end


-- validity checked by caller
cgui.updateOnTick = function(g, GUI)
  local contentFlow = GUI.children[2]
  local leftContent = contentFlow.children[1]
  local rightContent = contentFlow.children[2]

  updateSigTables(leftContent, g)
  updateModeStatus(rightContent, g)
end


-- validity should be checked by caller when GUI specified
cgui.updateOnEntity = function(g, GUI)
  if GUI then
    updateEntitiesInGUI(g, GUI)
    return
  end

  for pIndex, gAndGUI in pairs(global.pIndexToGUI) do
    if g.gID == gAndGUI[1] then
      if cgui.validatePlayerAndLight(pIndex, g.gID) and cgui.validateGUI(gAndGUI[2]) then
        updateEntitiesInGUI(g, gAndGUI[2])
      else
        cgui.CloseSearchlightGUI(pIndex)
      end
    end
  end
end


-- validity checked by caller
cgui.updateOnTextInput = function(g, GUI)
  for _, gAndGUI in pairs(global.pIndexToGUI) do
    if g.gID == gAndGUI[1] then
      updateForTextFieldInGUI(g, gAndGUI[2])
    end
  end
end


-- validity checked here
cgui.Rotated = function(g)
  for pIndex, gAndGUI in pairs(global.pIndexToGUI) do
    if g.gID == gAndGUI[1] then
      if cgui.validatePlayerAndLight(pIndex, g.gID) and cgui.validateGUI(gAndGUI[2]) then
        updateForRotation(g, gAndGUI[2])
      else
        cgui.CloseSearchlightGUI(pIndex)
      end
    end
  end
end


-- Don't open a GUI if the player is holding a non-item in cursor,
-- or if they're holding a wire (in which case, connect it to the signal interface),
-- or if they're holding a repair pack / capsule / blueprint / etc
-- (Basically, mirror the behavior of opening a gui for vanilla entities)
cgui.OpenSearchlightGUI = function(pIndex, cursor_pos)
  local player = game.players[pIndex]

  -- Ignore players in map mode, etc
  if player.render_mode ~= defines.render_mode.game then
    return
  end

  local sl = player.selected
  if not sl then
    local res = player.surface.find_entities_filtered{position=cursor_pos, type="turret", force=player.force, limit=1}
    if res then
      sl = res[1]
    end
  end

  if not sl then
    return
  end

  local g = global.unum_to_g[sl.unit_number]

  if not g then
    return
  end

  if global.pIndexToGUI[pIndex] and global.pIndexToGUI[pIndex][1] == g.gID then
    return -- GUI for this searchlight was already open
  end

  -- We'll be splitting up the cursorStack logic to better replicate the
  -- vanilla entity-gui behavior where holding a capsule, etc,
  -- doesn't trigger flying text about can't reach, etc
  local cursorStack = player.cursor_stack
  if      cursorStack 
      and cursorStack.valid
      and cursorStack.valid_for_read then

    local iPrototype = cursorStack.prototype

    if     iPrototype.place_result
        or iPrototype.has_flag("only-in-cursor") -- these flags are pretty good for
        or iPrototype.has_flag("spawnable")      -- spotting the blueprint-like tools
        or iPrototype.type == "repair-tool"
        or iPrototype.type == "capsule" then
      return
    end
  else
    cursorStack = nil
  end

  if player.force ~= sl.force then
      local pos = sl.position
      player.create_local_flying_text{text={"cant-open-enemy-structures"}, 
                                      position=pos,}
    return
  end

  if not player.can_reach_entity(sl) then
    if sl.name ~= d.searchlightSignalInterfaceName then
      local pos = sl.position
      player.create_local_flying_text{text={"cant-reach"}, 
                                      position=pos,}
    end
    return
  end

  if cursorStack and
       (cursorStack.name == "red-wire"
     or cursorStack.name == "green-wire") then
        player.selected = g.signal
        player.drag_wire{position=g.signal.position}
    return
  end

  local main_gui = player.gui.screen
  main_gui.clear()

  local main_frame = create(main_gui, g)

  player.opened = main_frame
  global.pIndexToGUI[pIndex] = {g.gID, main_frame}

  cgui.updateOnTick(g, main_frame)
  cgui.updateOnEntity(g, main_frame)

  player.play_sound{path="entity-open/constant-combinator"}
end


cgui.CloseSearchlightGUI = function(pIndex)
  local pGUI = global.pIndexToGUI[pIndex]

  if pGUI then
    pGUI[2].destroy()
    global.pIndexToGUI[pIndex] = nil
  end

  local player = game.players[pIndex]
  if player and player.valid then
    player.play_sound{path="entity-close/constant-combinator"}
  end
end


return cgui