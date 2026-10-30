for _, class in ipairs({ "pavucontrol", "nm-connection-editor", "blueman-manager", "lxqt-policykit-agent" }) do
  hl.window_rule({ name = "float-" .. class, match = { class = class }, float = true })
end

hl.window_rule({
  name = "1password-quick-access",
  match = { initial_title = "^(Quick Access — 1Password)$" },
  pin = true,
  stay_focused = true,
})
