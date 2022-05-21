local d = require "sl-defines"

-- Clean up all hidden entities & unum mappings that can't be back-traced to a gestalt
for _, s in pairs(game.surfaces) do
  hiddens = s.find_entities_filtered{name=d.spotterName}
  for _, hidden in pairs(hiddens) do
    local g = global.unum_to_g[hidden.unit_number]
    if g then
      if not (g.spotter 
              and g.spotter.valid 
              and g.spotter.unit_number == hidden.unit_number) then
        global.unum_to_g[hidden.unit_number] = nil
      end
    end

    if not global.unum_to_g[hidden.unit_number] then
      hidden.destroy()
    end
  end
end

for unum, g in pairs(global.unum_to_g) do
  if not g.light.valid then
    global.unum_to_g[unum] = nil
  else
    if not (   g.light.unit_number   == unum
            or g.signal.unit_number  == unum
            or g.spotter.unit_number == unum
            or g.turtle.unit_number  == unum) then
      global.unum_to_g[unum] = nil
    end
  end
end