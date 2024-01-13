----------------------------------------------------------------
  -- forward declarations
  local CopyCombinatorToSignalInterface
----------------------------------------------------------------


local pastableSignals =
{
  d.circuitSlots.radiusSlot,
  d.circuitSlots.rotateSlot,
  d.circuitSlots.minSlot   ,
  d.circuitSlots.maxSlot   ,
  d.circuitSlots.dirXSlot  ,
  d.circuitSlots.dirYSlot  ,
}


script.on_event(defines.events.on_entity_settings_pasted,
function(event)
  local source = event.source
  local dest = event.destination

  if not source.valid and not source.unit_number then
    return
  end

  if not dest.valid and not dest.unit_number then
    return
  end

  local gDest = global.unum_to_g[dest.unit_number]

  if not gDest then
    return
  end

  if source.name == "constant-combinator" then
    CopyCombinatorToSignalInterface(source.get_control_behavior(), 
                                    gDest.signal.get_control_behavior())
  else
    local gSource = global.unum_to_g[source.unit_number]

    if not gSource then
      return
    end

    local sourceC = gSource.signal.get_control_behavior()
    local destC = gDest.signal.get_control_behavior()
    for _, slotNum in pairs(pastableSignals) do
      destC.set_signal(slotNum, sourceC.get_signal(slotNum))
    end      
  end
end)


function CopyCombinatorToSignalInterface(source, dest)
  local sourceParams = source.parameters

  for _, slotNum in pairs(pastableSignals) do
    local currSig = dest.get_signal(slotNum)
    currSig.count = 0
    
    for _, p in pairs(sourceParams) do
      if p.signal.name == currSig.signal.name and p.count then
        currSig.count = currSig.count + p.count
      end
    end

    dest.set_signal(slotNum, currSig)
  end
end


----------------------------------------------------------------
  local public = {}
  public.CopyCombinatorToSignalInterface = CopyCombinatorToSignalInterface
  return public
----------------------------------------------------------------
