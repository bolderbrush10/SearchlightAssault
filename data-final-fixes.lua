-- This file's job is to grab any finalized data on turrets with a fire arc and make note of them in a run-time accessible way.
-- So, as a protype.
-- Yes, this is hacky.
-- No, there is no better way.
-- No, using mod settings to store this data won't work either.


log("henlo stinky world")
log(serpent.block(settings.startup["my-mod-test-setting"]))
log(settings.startup["my-mod-test-setting"].value)
log(settings.startup["my-mod-test-setting"].allowed_values)
log(settings.startup["my-mod-test-setting"].order)

settings.startup["my-mod-test-setting"].value = "b"
log(settings.startup["my-mod-test-setting"].value)

settings.startup["tttt-setting"] = "t"
log(serpent.block(settings))
log(serpent.block(settings.startup))
-- settings.insert("tttt-setting", "t")
-- log(settings.startup["tttt-setting"].value)