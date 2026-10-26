hl.window_rule({
  name = "float-pavucontrol",
  match = { class = "pavucontrol" },
  float = true,
})

hl.window_rule({
  name = "float-nm-connection-editor",
  match = { class = "nm-connection-editor" },
  float = true,
})

hl.window_rule({
  name = "float-blueman",
  match = { class = "blueman-manager" },
  float = true,
})

hl.window_rule({
  name = "float-polkit",
  match = { class = "lxqt-policykit-agent" },
  float = true,
})

hl.window_rule({
  name = "picture-in-picture",
  match = { title = "Picture-in-Picture" },
  float = true,
  pin = true,
  move = "72% 7%",
})
