for _, class in ipairs({ "pavucontrol", "nm-connection-editor", "blueman-manager", "lxqt-policykit-agent" }) do
  hl.window_rule({ name = "float-" .. class, match = { class = class }, float = true })
end
