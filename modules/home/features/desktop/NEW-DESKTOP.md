# Caelestia desktop experiment

Replaces the fufexan shell and custom theme coordination while retaining the live-editable Hyprland Lua architecture, Foot, Vicinae, screenshots, OCR, monitor layout, and monitor-local workspace bindings.

## Ownership

Caelestia owns the shell UI and selected theme integrations. Hyprland remains configured through the repository's out-of-store Lua files. Caelestia's Home Manager module writes shell/CLI JSON only; it does not manage this repository's Hyprland Lua files. Caelestia is started from Hyprland with `caelestia shell`, with its own systemd startup disabled.

## Theme system

Caelestia's CLI generates Material You-derived colours and applies terminal escape sequences, Hyprland Lua, GTK CSS/dconf settings, and Qt engine configuration. The first trial enables terminal, Hyprland, GTK, and Qt integrations only; Discord, Spicetify, Chromium, editor, terminal-tool and other integrations remain disabled.

Foot receives ANSI escape sequences rather than a Nix-managed colour file. Hyprlock uses a blurred screenshot of the current desktop rather than a fixed wallpaper; blurred content may still be recognizable.

Foot retains JetBrains Mono Nerd Font, 12x12 padding, a beam cursor and a persistent server. Caelestia's own default uses 25x25 padding; that was reduced for readability. Vicinae remains installed as a secondary launcher and clipboard-history tool; Caelestia's launcher is bound to Super+R for the trial, while Vicinae remains on Super+Shift+R. Its clipboard history remains on Super+V.

## Removed

The fufexan-dotfiles shell source/service/configuration, custom Darkman coordination, custom desktop-theme command, custom patched hyprqt6engine build, forced GTK theme, and unused custom Hyprland palette loader have been removed.

## Compatibility and status

Caelestia's bar is configured for per-monitor display with ten workspaces, but compatibility with split-monitor-workspaces numbering is unverified and must be tested on both physical monitors. The shell launcher command is a trial integration and may require adjustment to Caelestia's current CLI/interface. Qt integration uses Caelestia's expected qtengine configuration; whether every Qt application follows it must be tested after a fresh login.

After making desktop changes, evaluate and build the affected host:

```sh
nix build .#nixosConfigurations.wassaa.config.system.build.toplevel --no-link
```

After switching, start a fresh Hyprland session. Select a wallpaper and scheme through Caelestia, then test light/dark switching, Foot palette updates, the audio control, lock and unlock, both monitors' workspaces, notifications, OSD, launcher, screenshots and OCR. Check `hyprctl configerrors`, `systemctl --user --failed`, and `journalctl --user` for Caelestia. Confirm GNOME still starts independently. Inspect clipboard secret exclusions before copying sensitive values. Use the previous NixOS generation for rollback.
