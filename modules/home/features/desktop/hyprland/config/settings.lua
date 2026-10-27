hl.on("hyprland.start", function()
  hl.exec_cmd("lxqt-policykit-agent")
  hl.exec_cmd("nm-applet --indicator")
  hl.exec_cmd("systemctl --user start --no-block vscode-insiders-update-check.service")
end)
hl.config({
  input = {
    kb_layout = keyboardLayout,
    kb_options = "grp:alt_caps_toggle",
    numlock_by_default = true,
    repeat_delay = 300,
    follow_mouse = 1,
    touchpad = { natural_scroll = true, disable_while_typing = true, scroll_factor = 0.8 },
  },
  general = {
    layout = "dwindle",
    gaps_in = 4,
    gaps_out = 8,
    border_size = 1,
    resize_on_border = true,
  },
  decoration = {
    rounding = 10,
    rounding_power = 2.5,
    dim_inactive = true,
    dim_strength = 0.1,
    blur = {
      enabled = true,
      brightness = 1.0,
      contrast = 1.0,
      noise = 0.01,
      vibrancy = 0.2,
      vibrancy_darkness = 0.5,
      passes = 4,
      size = 7,
      popups = true,
      popups_ignorealpha = 0.2,
    },
    shadow = {
      enabled = true,
      color = "rgba(00000055)",
      offset = { 0, 15 },
      range = 100,
      render_power = 2,
      scale = 0.97,
    },
  },
  animations = { enabled = true },
  dwindle = { preserve_split = true },
  misc = {
    mouse_move_enables_dpms = true,
    key_press_enables_dpms = true,
    initial_workspace_tracking = 0,
    focus_on_activate = true,
  },
})
