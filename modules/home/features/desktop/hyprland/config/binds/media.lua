local exec = hl.dsp.exec_cmd
local locked = { locked = true }
local repeatable = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume", exec("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 6%+"), repeatable)
hl.bind("XF86AudioLowerVolume", exec("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 6%-"), repeatable)
hl.bind("XF86AudioMute", exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), locked)
hl.bind("XF86AudioMicMute", exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), locked)
hl.bind("XF86AudioPlay", exec("playerctl play-pause"), locked)
hl.bind("XF86AudioNext", exec("playerctl next"), locked)
hl.bind("XF86AudioPrev", exec("playerctl previous"), locked)
hl.bind("XF86MonBrightnessUp", exec("brightnessctl set +5%"), repeatable)
hl.bind("XF86MonBrightnessDown", exec("brightnessctl set 5%-"), repeatable)
