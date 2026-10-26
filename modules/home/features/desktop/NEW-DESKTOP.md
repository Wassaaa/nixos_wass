# Quickshell desktop experiment

Replaces the Home Manager desktop stack for all hosts importing this desktop module. System-level GNOME/Niri sessions remain installed, but the old Home Manager Niri configuration is no longer imported.

## Adopted

- Actual fufexan Quickshell bar, notification server/overlay, OSD and sidebar, from revision ffc567f8f3530ccc877c52fb26fa4a577f1794f2. The upstream license remains in the source input.
- Primary-monitor override replaces the upstream eDP-1 assumption, with a connected-screen fallback.
- Vicinae service, launcher and clipboard history.
- grimblast region/output screenshots and English OCR using grim/slurp/Tesseract.
- Upstream-inspired GTK styling, borders, shadows and spring animations.
- Existing host-generated keyboard/monitor settings and ten monitor-local workspace slots.

## Bindings

Super+R launcher; Super+V clipboard; Super+Space special workspace; Super+Shift+Space send window there; Super+1..0 monitor-local workspace; Super+Shift+1..0 send window; Super+Return terminal; Super+L lock; Super+O OCR; Print or Super+Shift+R area screenshot; Ctrl+Print or Super+Shift+Ctrl+R output screenshot; Super+Shift+C exits Hyprland immediately (save work first). Super+Q close; Super+F fullscreen; Super+T floating; Super+P pseudo; Super+Shift+I split; Super+arrows focus; Super+Shift+arrows move.

## Removed from active configuration

Stylix input/module imports, Rofi, Waybar, SwayNC, cliphist watchers, Pypr scratchpads, old desktop scripts, wlogout, Noctalia and Catppuccin desktop imports. Unused old files and old host styling variables remain as references, not active dependencies. The old Stylix-named GNOME patch-filter helper in core/system.nix remains inert with respect to Stylix itself. Legacy alternative configs must be modernized before re-enabling them.

## Deliberate differences and deferred work

Qt retains the known adwaita-dark/gtk3 baseline rather than copying upstream's custom patched hyprqt6engine toolchain. Dark mode is fixed initially. No Hyprexpo, new 1Password/dialog rules, recording UI, automatic dark/light scheduling or Vicinae extensions are added. Quickshell comes from a pinned source input rather than a local editable copy. Adjust the adapter or vendor the QML for further customization. Desktop monitor brightness may require DDC/CI integration; the upstream backlight widget is primarily laptop-oriented.

## Build status and first activation

Not Nix-evaluated, built or graphically tested by the authoring assistant. flake.lock is intentionally not fabricated: after pulling, run `nix flake lock` to lock the added source and prune unused Stylix nodes, then review and commit the resulting lock file. Existing unrelated flake inputs are retained.

Run `nix build .#nixosConfigurations.wassaa.config.system.build.toplevel --no-link` before switching. Local uncommitted configuration edits must be reconciled before pulling. After a successful switch, log out and into a fresh Hyprland session; the old session may still have manually spawned Waybar/Pypr/cliphist processes.

Check `hyprctl configerrors`, `systemctl --user status quickshell`, `systemctl --user status vicinae`, and `journalctl --user -u quickshell -b`. Verify icon fonts, both monitors' workspace switching, screenshots, notification actions and volume OSD. Inspect Vicinae clipboard exclusions/password handling before using it with sensitive copied values.

Rollback: use the previous NixOS generation and revert this commit if needed. Do not assume an untested configuration is a known-good boot environment.
