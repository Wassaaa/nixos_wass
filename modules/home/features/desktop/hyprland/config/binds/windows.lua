hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "Close window" })
hl.bind("SUPER + F", hl.dsp.window.fullscreen(), { description = "Toggle fullscreen" })
hl.bind(
  "SUPER + SHIFT + F",
  hl.dsp.window.float({ action = "toggle" }),
  { description = "Toggle floating" }
)
hl.bind(
  "SUPER + SHIFT + I",
  hl.dsp.layout("togglesplit"),
  { description = "Toggle split direction" }
)
for _, direction in ipairs({ "left", "right", "up", "down" }) do
  hl.bind(
    "SUPER + " .. direction,
    hl.dsp.focus({ direction = direction }),
    { description = "Focus window " .. direction }
  )
  hl.bind(
    "SUPER + SHIFT + " .. direction,
    hl.dsp.window.move({ direction = direction }),
    { description = "Move window " .. direction }
  )
end
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Drag window" })
hl.bind(
  "SUPER + mouse:273",
  hl.dsp.window.resize(),
  { mouse = true, description = "Resize window" }
)
