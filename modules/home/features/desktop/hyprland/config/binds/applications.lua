local exec = hl.dsp.exec_cmd
keybindingsViewerShortcut = "SUPER + SHIFT + K"
-- Caelestia launcher is the primary trial launcher.
hl.bind("SUPER + R", hl.dsp.global("caelestia:launcher"), { description = "Open launcher" })
-- Keep Vicinae available as the secondary launcher/clipboard tool.
hl.bind("SUPER + SHIFT + R", exec("vicinae vicinae://toggle"), { description = "Open Vicinae" })
hl.bind("SUPER + V", exec("vicinae 'vicinae://launch/clipboard/history?toggle=true'"), { description = "Open clipboard history" })
hl.bind("SUPER + Return", exec(terminal), { description = "Open terminal" })
hl.bind("SUPER + E", exec("thunar"), { description = "Open file manager" })
hl.bind("SUPER + W", exec(browser), { description = "Open browser" })
hl.bind("SUPER + L", hl.dsp.global("caelestia:lock"), { description = "Lock screen" })
hl.bind("SUPER + N", hl.dsp.global("caelestia:sidebar"), { description = "Toggle sidebar" })
hl.bind("SUPER + K", hl.dsp.global("caelestia:showall"), { description = "Toggle shell panels" })
hl.bind("CTRL + ALT + Delete", hl.dsp.global("caelestia:session"), { description = "Open session menu" })
hl.bind("CTRL + ALT + C", hl.dsp.global("caelestia:clearNotifs"), { locked = true, description = "Clear notifications" })
hl.bind("SUPER + SHIFT + T", exec("wl-ocr"), { description = "Copy text from screen" })
hl.bind("SUPER + SHIFT + S", hl.dsp.global("caelestia:screenshotFreeze"), { description = "Capture and edit screen area" })
hl.bind("Print", exec("caelestia screenshot"), { description = "Capture focused monitor" })
hl.bind("CTRL + Print", exec("grimblast --notify copysave output"), { description = "Save and copy monitor screenshot" })
hl.bind("SUPER + SHIFT + CTRL + R", exec("grimblast --notify copysave output"), { description = "Save and copy monitor screenshot" })
hl.bind("SUPER + SHIFT + C", exec("hyprpicker -a"), { description = "Pick screen colour" })
hl.bind("SUPER + SHIFT + CTRL + Q", hl.dsp.exit(), { description = "Exit Hyprland" })
