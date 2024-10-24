for gID, g in pairs(storage.gestalts) do
  script.register_on_object_destroyed(g.light)
end