# Caelestia desktop experiment

Replaces the fufexan shell and custom theme coordination while retaining the live-editable Hyprland Lua architecture, Foot, Vicinae, screenshots, OCR, monitor layout, and monitor-local workspace bindings.

## Ownership

Caelestia owns the shell UI, lock screen, idle handling and selected theme integrations. Hyprland remains configured through the repository's out-of-store Lua files. Caelestia's Home Manager module writes shell/CLI JSON only; it does not manage this repository's Hyprland Lua files. The Caelestia systemd user service starts with the Hyprland session and restarts on failure. During migration from Lua startup, the service skips starting if a shell instance already exists; start a fresh Hyprland session to complete the transition without duplicate shells.

## Theme system

Caelestia's CLI generates Material You-derived colours and applies terminal escape sequences, Hyprland Lua, GTK CSS/dconf settings, and Qt engine configuration. The integration enables terminal, Hyprland, GTK, and Qt integrations only; Discord, Spicetify, Chromium, editor, terminal-tool and other integrations remain disabled.

The editable Hyprland `config/theme.lua` reads Caelestia's generated `~/.config/hypr/scheme/current.lua` and applies its active and inactive border colours. A Caelestia theme post-hook reloads Hyprland after scheme or wallpaper changes; before the first generated scheme, the borders use Caelestia's default colours. Edit `config/theme.lua` to customize this mapping without rebuilding.

Qt applications use the Qt 6 `qtengine` platform theme and Darkly style in Hyprland. Caelestia generates their colour configuration at runtime. The Nixpkgs packages used here are Qt 6-only; Qt 5 applications may not follow this theme. A fresh Hyprland session is needed after changing the plugin setup.

Foot receives ANSI escape sequences rather than a Nix-managed colour file. To use wallpaper-derived colours, choose a wallpaper with the launcher's `>wallpaper` action, then choose the `dynamic` scheme using `>scheme`; subsequent wallpaper changes update the colours.

Foot retains JetBrains Mono Nerd Font, 12x12 padding, a beam cursor and a persistent server. Caelestia's own default uses 25x25 padding; that was reduced for readability. Vicinae remains installed as a secondary launcher and clipboard-history tool; Caelestia's launcher is bound to Super+R for the trial, while Vicinae remains on Super+Shift+R. Its clipboard history remains on Super+V.

## Locking and shortcuts

Caelestia locks after 15 minutes and turns displays off after 20 minutes, with no automatic suspend. It also locks before sleep. Hypridle and Hyprlock are not configured, so Caelestia is the only lock screen in this Hyprland setup. Before relying on it, verify password unlock in a fresh session with another TTY available.

Super+Shift+F toggles floating for the focused window. Super+Shift+S opens Caelestia's frozen picker and Swappy editor; Print uses Caelestia's focused-monitor screenshot, which copies to the clipboard and offers a save action. Super+Shift+T runs OCR, Super+Shift+C picks a colour, Super+N opens the sidebar, Super+K opens shell panels, and Ctrl+Alt+Delete opens the session menu. Super+Shift+Ctrl+Q exits Hyprland.

Swappy saves the edited image to `Pictures/Screenshots` and copies it to the clipboard when closed with Escape or the window close button. The Caelestia-specific wrapper reports failures to copy the image. Ctrl+W may bypass Swappy's save-on-close behavior.

Super+Shift+K opens the experimental Omarchy-derived visual shortcut viewer; Super+K remains unchanged. Its shortcut is editable as `keybindingsViewerShortcut` in `hyprland/config/binds/applications.lua`. It uses a separate Quickshell service and reads active Hyprland bindings. While open, it switches to an isolated submap so shortcuts can be inspected without running them; bindings marked `submap_universal` remain active. Close it with Escape or Super+Shift+K; if needed, restore normal bindings with `hyprctl dispatch 'hl.dsp.submap("reset")'`. Test opening, closing, and shortcut recovery on the host before relying on it. The initial viewer colours are static and do not yet follow Caelestia's wallpaper.

Thunar's managed "Open Terminal Here" action uses the configured XDG default terminal. Home Manager backs up an existing `Thunar/uca.xml` before replacing it, so any other custom Thunar actions need to be merged into this configuration. Activation can fail if the backup file already exists.

## Profile picture

Home Manager initializes `~/.face` from the bundled default only when it is absent. Caelestia's profile picker can then replace it with an image from anywhere, and later rebuilds preserve that choice. When absent, `~/.face.icon` and `~/.config/face.jpg` are linked to `~/.face` so other consumers can use the same picture. Existing files or links at those paths are preserved, so they may not follow the Caelestia picture. On migration, Home Manager removes its old managed links before these paths are initialized.

## 1Password dialogs

The picture-in-picture rule is separate from 1Password dialogs. [Omarchy's configuration](https://github.com/omacom/omarchy/blob/a9cedf93e0356d475411510e818e7e054a924d55/default/hypr/apps/1password.lua#L1-L3) matches both old and new 1Password app IDs and tags those windows for floating. No blanket rule is added without identifying the affected dialog; a fixed size can be inappropriate for a different prompt. If it happens again, record the affected window's class, title and dimensions from `hyprctl clients`, omitting any sensitive information.

## Removed

The fufexan-dotfiles shell source/service/configuration, custom Darkman coordination, custom desktop-theme command, custom patched hyprqt6engine build, and forced GTK theme have been removed.

## Compatibility and status

Caelestia's bar is configured for per-monitor display with ten workspaces; the split-monitor-workspaces setup works on both monitors. Qt application theming should be checked after a fresh login.

After making desktop changes, evaluate and build the affected host with `fb` or:

```sh
nix build .#nixosConfigurations.wassaa.config.system.build.toplevel --no-link
```

Switch with `fr` (or `frb` to apply at boot), then start a fresh Hyprland session. Select a wallpaper and scheme through Caelestia, then test light/dark switching, Hyprland border colours, Foot palette updates, a Qt 6 application's appearance, the audio control, lock and unlock, notifications, OSD, launcher, screenshots and OCR. Check `hyprctl configerrors`, `systemctl --user --failed`, and `journalctl --user` for Caelestia. Confirm GNOME still starts independently. Inspect clipboard secret exclusions before copying sensitive values. Use the previous NixOS generation for rollback.
