local export = {}

export.scan =
{
  filename = "__SearchlightAssault__/audio/sl-scan.ogg",
  volume = 1.0,
  -- aggregation = {max_count = 1, count_already_playing = true, remove = false}
}

export.spotted =
{
  filename = "__SearchlightAssault__/audio/sl-spotted.ogg",
  volume = 1.0
}

export.working =
{
  filename = "__SearchlightAssault__/audio/sl-working.ogg",
  -- volume = 0.8,
  volume = 0.0,
  audible_distance_modifier = 0.3
}

return export