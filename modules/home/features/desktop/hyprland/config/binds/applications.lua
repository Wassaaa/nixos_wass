local exec = hl.dsp.exec_cmd
-- Caelestia launcher is the primary trial launcher.
hl.bind("SUPER + R", exec("caelestia shell launcher"))
-- Keep Vicinae available as the secondary launcher/clipboard tool.
hl.bind("SUPER + SHIFT + R", exec("vicinae vicinae://toggle"))
hl.bind("SUPER + V", exec("vicinae 'vicinae://launch/clipboard/history?toggle=true'"))
hl.bind("SUPER + Return", exec(terminal))
hl.bind("SUPER + L", exec("loginctl lock-session"))
hl.bind("SUPER + O", exec("wl-ocr"))
hl.bind("Print", exec("grimblast --notify copysave area"))
hl.bind("CTRL + Print", exec("grimblast --notify copysave output"))
hl.bind("SUPER + SHIFT + CTRL + R", exec("grimblast --notify copysave output"))
hl.bind("SUPER + SHIFT + C", hl.dsp.exit())
