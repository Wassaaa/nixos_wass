local exec = hl.dsp.exec_cmd
local function locked(description)
  return { locked = true, description = description }
end
local function repeatable(description)
  return { locked = true, repeating = true, description = description }
end
hl.bind(
  "XF86AudioRaiseVolume",
  exec("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 6%+"),
  repeatable("Raise volume")
)
hl.bind(
  "XF86AudioLowerVolume",
  exec("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 6%-"),
  repeatable("Lower volume")
)
hl.bind(
  "XF86AudioMute",
  exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
  locked("Toggle audio mute")
)
hl.bind(
  "XF86AudioMicMute",
  exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
  locked("Toggle microphone mute")
)
hl.bind("XF86AudioPlay", exec("playerctl play-pause"), locked("Play or pause media"))
hl.bind("XF86AudioNext", exec("playerctl next"), locked("Next track"))
hl.bind("XF86AudioPrev", exec("playerctl previous"), locked("Previous track"))
hl.bind("XF86MonBrightnessUp", exec("brightnessctl set +5%"), repeatable("Increase brightness"))
hl.bind("XF86MonBrightnessDown", exec("brightnessctl set 5%-"), repeatable("Decrease brightness"))
