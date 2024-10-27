local d = require "sl-defines"

-- Map: playerIndex -> {g, {LuaRenderObject}}
for pID, gAndRID in pairs(storage.tposRenders) do
	if type(gAndRID[2]) == "number" then
		storage.tposRenders[pID][2] = rendering.get_object_by_id(gAndRID[2])
	end
end

-- Map: gID -> 0/playerIndex -> {epochTick, {LuaRenderObject}}
for key, pIndMap in pairs(storage.slFOVRenders) do
	for pID, TickAndRID in pairs(pIndMap) do
		if type(TickAndRID[2]) == "number" then
			storage.slFOVRenders[key][pID][2] = rendering.get_object_by_id(TickAndRID[2])
		end
	end
end

local rwire = defines.wire_connector_id.circuit_red
local gwire = defines.wire_connector_id.circuit_green
local sigRadius  = {type="virtual", name="sl-radius"}
local sigRotate  = {type="virtual", name="sl-rotation"}
local sigMin     = {type="virtual", name="sl-minimum"}
local sigMax     = {type="virtual", name="sl-maximum"}
local sigDirectX = {type="virtual", name="sl-x"}
local sigDirectY = {type="virtual", name="sl-y"}
local sigOwnX    = {type="virtual", name="sl-own-x"}
local sigOwnY    = {type="virtual", name="sl-own-y"}
local sigWarn    = {type="virtual", name="sl-warn"}
local sigAlarm   = {type="virtual", name="sl-alarm"}
local sigFoeX    = {type="virtual", name="foe-x-position"}
local sigFoeY    = {type="virtual", name="foe-y-position"}

for gID, g in pairs(storage.check_power) do
  if g.light.valid and g.signal.valid then

	  local i = g.signal
	  local c = i.get_control_behavior().sections[1]

		local slots = {}
	  for n=1, 16 do
	  	local filt = c.get_slot(n)
	  	if filt and filt.value then
	  		slots[filt.value.name] = filt
	  	end
	  	c.clear_slot(n)
	  end

		if slots["sl-radius"     ] then c.set_slot(d.circuitSlots.radiusSlot			, slots["sl-radius"     ]) end
		if slots["sl-rotation"   ] then c.set_slot(d.circuitSlots.rotateSlot			, slots["sl-rotation"   ]) end
		if slots["sl-minimum"    ] then c.set_slot(d.circuitSlots.minSlot   			, slots["sl-minimum"    ]) end
		if slots["sl-maximum"    ] then c.set_slot(d.circuitSlots.maxSlot   			, slots["sl-maximum"    ]) end
		if slots["sl-x"          ] then c.set_slot(d.circuitSlots.dirXSlot  			, slots["sl-x"          ]) end
		if slots["sl-y"          ] then c.set_slot(d.circuitSlots.dirYSlot  			, slots["sl-y"          ]) end
		if slots["sl-own-x"      ] then c.set_slot(d.circuitSlots.ownPositionXSlot, slots["sl-own-x"      ]) end
		if slots["sl-own-y"      ] then c.set_slot(d.circuitSlots.ownPositionYSlot, slots["sl-own-y"      ]) end
		if slots["sl-warn"       ] then c.set_slot(d.circuitSlots.warningSlot     , slots["sl-warn"       ]) end
		if slots["sl-alarm"      ] then c.set_slot(d.circuitSlots.alarmSlot       , slots["sl-alarm"      ]) end
		if slots["foe-x-position"] then c.set_slot(d.circuitSlots.foePositionXSlot, slots["foe-x-position"]) end
		if slots["foe-y-position"] then c.set_slot(d.circuitSlots.foePositionYSlot, slots["foe-y-position"]) end

  end
end
