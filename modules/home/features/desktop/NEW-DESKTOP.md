# Quickshell desktop experiment

The shared Home Manager desktop module replaces the old Niri/Rofi/Waybar/SwayNC/Pypr desktop configuration for every host importing it. System-level alternative sessions remain installed.

## Shell and tools

Fufexan's Quickshell bar, notification overlay/server, OSD and sidebar come from the pinned fufexan-dotfiles source. Its primary-screen assumption is adapted to host monitor settings. Vicinae handles launcher and clipboard history; grimblast handles screenshots; wl-ocr recognizes English screen text.

## Coordinated styling

Foot is now the desktop terminal. Its actual pinned upstream module supplies both palettes, 90% opacity, blur request, padding, beam cursor and notifications. JetBrains Mono Nerd Font is installed explicitly. The generated Hyprland terminal variable overrides the older host terminal choice when Foot is enabled; Kitty remains installed by the core profile.

GTK uses Inter, Adwaita icons and adw-gtk3. Qt6 uses Fusion, Breeze light/dark schemes and a locally built hyprqt6engine. The engine source revision/hash and portal-follow patch match the pinned upstream configuration, but the source is fetched and patched normally: no references to upstream's private /nix/store tree. Its libraries are rebuilt with this package set's default compiler runtime. Qt5 and applications supplying their own themes may not follow the Qt6 engine.

Darkman coordinates changes with explicit application actions. Each fresh Hyprland session initializes dark mode. Run:

```sh
desktop-theme light
desktop-theme dark
desktop-theme toggle
desktop-theme refresh
```

The current choice is recorded under the XDG state directory. Hyprland's editable theme.lua reapplies that palette after a configuration reload. Quickshell watches the dconf color preference; the Qt patch follows the Settings portal. GTK3 updates through gsettings; applications that cache their GTK theme may need restarting. No GeoClue or new geographic schedule is configured. A previously cached Darkman location may need clearing before expecting strictly manual switching. Vicinae retains its own theme selection; extensions/custom launcher palettes are not configured here.

New logins receive Qt variables through Home Manager's session environment and Hyprland, with HM's systemd/DBus environment integration, not an assumed UWSM launch. Open applications need restarting to load the new platform plugin. Quickshell remains sourced from the pinned input, not vendored editable QML.

## Key bindings

Super+R launcher; Super+V clipboard; Super+Space special workspace; Super+Shift+Space send window there; Super+1..0 monitor-local workspace; Super+Shift+1..0 send window; Super+Return footclient; Super+L lock; Super+O OCR; Print or Super+Shift+R region screenshot; Ctrl+Print or Super+Shift+Ctrl+R output screenshot; Super+Shift+C immediate exit. Window and media bindings remain in config/binds.

## Status and deferred features

The initial shell commit built successfully according to the user. This follow-up is not Nix-evaluated, built or graphically tested by the assistant. It does not update flake.lock or unrelated inputs. The gcc15Stdenv overrides in qt.nix were checked against the repository's locked nixpkgs; revisit those arguments if updating nixpkgs to a different compiler generation.

Still deferred: Hyprexpo, additional dialog/authentication rules, recording UI, Vicinae extensions, geographic scheduling and DDC/CI integration for external monitor brightness. Legacy unused files/host styling variables remain references, not active Stylix dependencies.

Before activation, reconcile local edits, pull, and build:

```sh
nix build .#nixosConfigurations.wassaa.config.system.build.toplevel --no-link
```

After switching, start a fresh Hyprland session. Verify footclient, both monitors' workspace switching, desktop-theme toggle, Qt applications, notifications, screenshots and OCR. Check hyprctl configerrors and the user services quickshell, foot, darkman, desktop-theme-sync and vicinae. Inspect clipboard secret exclusions before copying sensitive values. Use the previous NixOS generation if rollback is needed.
