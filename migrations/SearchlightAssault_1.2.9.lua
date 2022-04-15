for gID, g in pairs(global.gestalts) do
  script.register_on_entity_destroyed(g.light)
end