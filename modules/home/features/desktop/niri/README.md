# Niri Setup Guide

## What is Niri?

Niri is a scrollable-tiling Wayland compositor. Unlike traditional tiling window managers, windows are arranged in columns on an infinite horizontal strip. Opening new windows never causes existing windows to resize.

## Quick Start

### 1. Rebuild

Niri is now enabled at system level. Just rebuild:

```bash
fr  # or: nh os switch
```

### 2. Log Out and Select Niri

At GDM login screen, click the gear icon and select "Niri" session.

### 3. Customize (Optional)

Niri uses sensible defaults. To override with custom config, uncomment `./niri` in `modules/home/features/desktop/default.nix` and edit `modules/home/features/desktop/niri/niri.nix`, then rebuild.

At GDM login screen, click the gear icon and select "Niri" session.

## Basic Keybinds

All keybinds use `Super` (Windows key):

### Essential

- `Super + Enter` - Open terminal
- `Super + Q` - Close window
- `Super + Shift + Q` - Quit niri
- `Super + W` - Open browser
- `Super + R` - Rofi launcher

### Navigation (Vim-style)

- `Super + H/L` - Focus left/right column
- `Super + J/K` - Focus window down/up
- `Super + Left/Right/Up/Down` - Arrow key navigation

### Move Windows

- `Super + Shift + H/L/J/K` - Move window
- `Super + Shift + Arrows` - Move window with arrows

### Workspaces

- `Super + 1-9` - Switch to workspace
- `Super + Shift + 1-9` - Move window to workspace

### Window Management

- `Super + F` - Maximize column
- `Super + Shift + F` - Fullscreen window
- `Super + Comma` - Consume window into column (tab-like)
- `Super + Period` - Expel window from column

### Screenshots

- `Super + S` - Screenshot UI
- `Super + Shift + S` - Screenshot current window

## Key Differences from Hyprland

### What Works the Same

- **Rofi, Waybar, swaync** - All your GUI tools work
- **Applications** - Same apps, same terminal, same browser
- **Media keys** - Volume, brightness, playerctl all configured

### What's Different

- **No hypridle/hyprlock** - These are Hyprland-specific
  - Niri has built-in idle handling
  - You'll need a different lock screen (like swaylock)
- **Tiling behavior** - Scrollable columns vs. traditional tiling
- **Workspaces** - Dynamic (GNOME-style) instead of fixed
- **No pyprland** - Niri has its own window management

### What Niri Includes Built-in

- **Screenshot UI** - Press `Super + S` for built-in screenshot tool
- **Overview mode** - Like GNOME's overview
- **Screencasting** - Works via xdg-desktop-portal-gnome
- **Touchpad gestures** - Built-in gesture support

## Configuration

Niri config lives in: `~/.config/niri/config.kdl`

The NixOS-managed version is in: `modules/home/features/desktop/niri/niri.nix`

Changes to `niri.nix` require a rebuild, but niri supports **live config reload**:

```bash
niri msg reload-config
```

## Switching Between DEs

Just select "Hyprland" or "Niri" at the GDM login screen. Both are always available - no need to comment/uncomment anything!

## Customization

The current config uses:

- Your monitor layout (DP-3 + HDMI-A-1)
- Your terminal and browser from `variables.nix`
- Same keyboard layout (us,ee with alt+caps toggle)
- Gradient borders with your Stylix colors

To customize further, edit `modules/home/features/desktop/niri/niri.nix` and check the [official docs](https://yalter.github.io/niri/Configuration%3A-Overview.html).

## Troubleshooting

**Niri doesn't appear in GDM?**

- Make sure both system and home modules are enabled
- Rebuild with `fr`
- Check logs: `journalctl --user -u niri`

**Apps don't launch?**

- Niri uses same environment as Hyprland
- Check if the app works in Hyprland first

**Want to try niri in a window?**

```bash
niri --session
```

## Resources

- [Official Docs](https://yalter.github.io/niri/)
- [Configuration Guide](https://yalter.github.io/niri/Configuration%3A-Overview.html)
- [Matrix Chat](https://matrix.to/#/#niri:matrix.org)
- [awesome-niri](https://github.com/Vortriz/awesome-niri) - List of niri tools and configs
