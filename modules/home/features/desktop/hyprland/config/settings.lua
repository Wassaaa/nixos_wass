hl.env("NIXOS_OZONE_WL", "1")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("SDL_VIDEODRIVER", "x11")
hl.env("MOZ_ENABLE_WAYLAND", "1")

hl.on("hyprland.start", function()
  hl.exec_cmd("lxqt-policykit-agent")
  hl.exec_cmd("nm-applet --indicator")
  hl.exec_cmd("waybar")
  hl.exec_cmd("pypr")
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
  hl.exec_cmd("killall -q swww-daemon; sleep .5 && swww-daemon")
end)

hl.config({
  input = {
    kb_layout = keyboardLayout,
    kb_options = { "grp:alt_caps_toggle" },
    numlock_by_default = true,
    repeat_delay = 300,
    follow_mouse = 1,
    sensitivity = 0,
    touchpad = {
      natural_scroll = true,
      disable_while_typing = true,
      scroll_factor = 0.8,
    },
  },

  general = {
    layout = "dwindle",
    gaps_in = 6,
    gaps_out = 8,
    border_size = 2,
    resize_on_border = true,
  },

  misc = {
    layers_hog_keyboard_focus = true,
    initial_workspace_tracking = 0,
    mouse_move_enables_dpms = true,
    key_press_enables_dpms = false,
  },

  dwindle = {
    pseudotile = true,
    preserve_split = true,
  },

  decoration = {
    rounding = 10,
    blur = {
      enabled = true,
      size = 5,
      passes = 3,
      ignore_opacity = false,
      new_optimizations = true,
    },
    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
      color = "rgba(1a1a1aee)",
    },
  },
})
