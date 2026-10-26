-- Floating utility windows
hl.windowrule({ match = { class = "pavucontrol" }, float = true, center = true })
hl.windowrule({ match = { class = "nm-connection-editor" }, float = true })
hl.windowrule({ match = { class = "blueman-manager" }, float = true })
hl.windowrule({ match = { class = "org.gnome.Nautilus" }, tag = "file-manager" })
hl.windowrule({ match = { class = "kitty" }, tag = "terminal" })
hl.windowrule({ match = { class = "Brave-browser" }, tag = "browser" })

-- Picture-in-picture
hl.windowrule({
  match = { title = "Picture-in-Picture" },
  float = true,
  pin = true,
  move = "72% 7%",
})

-- Polkit prompts
hl.windowrule({
  match = { class = "lxqt-policykit-agent" },
  float = true,
  center = true,
  size = "30% 25%",
})
