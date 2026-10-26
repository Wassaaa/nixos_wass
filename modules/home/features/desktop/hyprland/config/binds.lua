local mod = "SUPER"

-- Launcher and terminal
hl.bind({ mods = mod, key = "Return", dispatcher = "exec", arg = terminal })
hl.bind({ mods = mod, key = "R", dispatcher = "exec", arg = "rofi-launcher" })
hl.bind({
  mods = mod,
  key = "V",
  dispatcher = "exec",
  arg =
  "rofi -modi clipboard:clipvault_rofi.sh -show clipboard -show-icons"
})

-- Common apps
hl.bind({ mods = mod, key = "W", dispatcher = "exec", arg = browser })
hl.bind({ mods = mod, key = "E", dispatcher = "exec", arg = "pypr toggle nautilus" })
hl.bind({ mods = mod, key = "S", dispatcher = "exec", arg = "screenshootin" })
hl.bind({ mods = mod, key = "D", dispatcher = "exec", arg = "discord" })
hl.bind({ mods = mod, key = "O", dispatcher = "exec", arg = "obs" })
hl.bind({ mods = mod, key = "C", dispatcher = "exec", arg = "hyprpicker -a" })
hl.bind({ mods = mod, key = "T", dispatcher = "exec", arg = "pypr toggle term" })
hl.bind({ mods = mod, key = "M", dispatcher = "exec", arg = "pavucontrol" })
hl.bind({ mods = mod, key = "P", dispatcher = "exec", arg = "pypr toggle volume" })

-- Window management
hl.bind({ mods = mod, key = "Q", dispatcher = "killactive" })
hl.bind({ mods = mod .. " SHIFT", key = "P", dispatcher = "pseudo" })
hl.bind({ mods = mod .. " SHIFT", key = "I", dispatcher = "togglesplit" })
hl.bind({ mods = mod, key = "F", dispatcher = "fullscreen" })
hl.bind({ mods = mod .. " SHIFT", key = "F", dispatcher = "togglefloating" })

-- Focus
for _, pair in ipairs({
  { "left", "l" }, { "down", "d" }, { "up", "u" }, { "right", "r" },
  { "h",    "l" }, { "j", "d" }, { "k", "u" }, { "l", "r" },
}) do
  hl.bind({
    mods = mod,
    key = pair[1],
    dispatcher = "movefocus",
    arg = pair[2],
  })
end

-- Move windows
for _, pair in ipairs({
  { "left", "l" }, { "down", "d" }, { "up", "u" }, { "right", "r" },
  { "h",    "l" }, { "j", "d" }, { "k", "u" }, { "l", "r" },
}) do
  hl.bind({
    mods = mod .. " SHIFT",
    key = pair[1],
    dispatcher = "movewindow",
    arg = pair[2],
  })
end

-- Workspaces
for i = 1, 9 do
  hl.bind({
    mods = mod,
    key = tostring(i),
    dispatcher = "exec",
    arg = "hyprsome workspace " .. i,
  })

  hl.bind({
    mods = mod .. " SHIFT",
    key = tostring(i),
    dispatcher = "exec",
    arg = "hyprsome move " .. i,
  })
end

hl.bind({ mods = mod .. " SHIFT", key = "SPACE", dispatcher = "movetoworkspace", arg = "special" })
hl.bind({ mods = mod, key = "SPACE", dispatcher = "togglespecialworkspace" })
hl.bind({ mods = mod .. " CONTROL", key = "right", dispatcher = "workspace", arg = "e+1" })
hl.bind({ mods = mod .. " CONTROL", key = "left", dispatcher = "workspace", arg = "e-1" })

-- Mouse
hl.bind({ mods = mod, key = "mouse:272", dispatcher = "movewindow" })
hl.bind({ mods = mod, key = "mouse:273", dispatcher = "resizewindow" })

-- Media and hardware keys
hl.bind({ mods = "", key = "XF86AudioRaiseVolume", dispatcher = "exec", arg = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+" })
hl.bind({ mods = "", key = "XF86AudioLowerVolume", dispatcher = "exec", arg = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" })
hl.bind({ mods = "", key = "XF86AudioMute", dispatcher = "exec", arg = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" })
hl.bind({ mods = "", key = "XF86AudioPlay", dispatcher = "exec", arg = "playerctl play-pause" })
hl.bind({ mods = "", key = "XF86AudioNext", dispatcher = "exec", arg = "playerctl next" })
hl.bind({ mods = "", key = "XF86AudioPrev", dispatcher = "exec", arg = "playerctl previous" })
hl.bind({ mods = "", key = "XF86MonBrightnessDown", dispatcher = "exec", arg = "brightnessctl set 5%-" })
hl.bind({ mods = "", key = "XF86MonBrightnessUp", dispatcher = "exec", arg = "brightnessctl set +5%" })
