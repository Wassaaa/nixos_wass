package.path = package.path .. ";./?.lua;./?/init.lua"

local smw = require("plugins.split-monitor-workspaces")

smw.setup({
  workspace_count = 10,
})

local mod = "SUPER"

-- Launcher and terminal
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + R", hl.dsp.exec_cmd("rofi-launcher"))
hl.bind(
  mod .. " + V",
  hl.dsp.exec_cmd("rofi -modi clipboard:clipvault_rofi.sh -show clipboard -show-icons")
)

-- Common apps
hl.bind(mod .. " + W", hl.dsp.exec_cmd(browser))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("pypr toggle nautilus"))
hl.bind(mod .. " + S", hl.dsp.exec_cmd("screenshootin"))
hl.bind(mod .. " + D", hl.dsp.exec_cmd("discord"))
hl.bind(mod .. " + O", hl.dsp.exec_cmd("obs"))
hl.bind(mod .. " + C", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(mod .. " + T", hl.dsp.exec_cmd("pypr toggle term"))
hl.bind(mod .. " + M", hl.dsp.exec_cmd("pavucontrol"))
hl.bind(mod .. " + P", hl.dsp.exec_cmd("pypr toggle volume"))

-- Window management
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + P", hl.dsp.window.pseudo())
hl.bind(mod .. " + SHIFT + I", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))

-- Focus
hl.bind(mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + j", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + l", hl.dsp.focus({ direction = "right" }))

-- Move windows
hl.bind(mod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + SHIFT + h", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + j", hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + SHIFT + k", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + l", hl.dsp.window.move({ direction = "right" }))

-- Per-monitor workspaces
-- On the left monitor, Super+1..9/0 selects workspaces 1..10 there.
-- On the right monitor, the same keys select that monitor's own 1..10.
for i = 1, smw.get_amount_of_workspaces() do
  local key = tostring(i)

  if key == "10" then
    key = "0"
  end

  hl.bind(mod .. " + " .. key, smw.workspace(key))
  hl.bind(
    mod .. " + SHIFT + " .. key,
    smw.move_to_workspace_silent(key)
  )
end

hl.bind(mod .. " + SHIFT + SPACE", hl.dsp.window.move({ workspace = "special" }))
hl.bind(mod .. " + SPACE", hl.dsp.workspace.toggle_special())
hl.bind(mod .. " + CONTROL + right", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + CONTROL + left", hl.dsp.focus({ workspace = "e-1" }))

-- Mouse
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media and hardware keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"), { locked = true, repeating = true })
