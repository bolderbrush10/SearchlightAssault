local export = {}


export.working =
{
  filename = "__SearchlightAssault__/audio/sl-working.ogg",
  volume = 0.85,
  audible_distance_modifier = 0.3,
  fade_in_ticks = 4,
  fade_out_ticks = 20,
}


export.scan =
{
  filename = "__SearchlightAssault__/audio/sl-scan.ogg",
  volume = 1.0,
  audible_distance_modifier = 1.0,
  fade_in_ticks = 1,
  fade_out_ticks = 20,
}


export.spotted =
{
  filename = "__SearchlightAssault__/audio/sl-spotted.ogg",
  volume = 1.0,
  audible_distance_modifier = 0.8,
}


return export
