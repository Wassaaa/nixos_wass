---
name: hyprland-lua
description: Edit this repository's Hyprland Lua configuration, keybinds, monitor profiles, and Caelestia theme integration.
---

# Hyprland Lua

## Layout

- `modules/home/features/desktop/hyprland/config/` is the live configuration.
  It is linked out of the Nix store, so Lua edits do not need a rebuild.
- `config/settings.lua`, `animations.lua`, `rules.lua`, `theme.lua`,
  `monitor-profiles.lua`, `binds.lua`.
- `config/binds/` groups keybindings by topic; `config/rules/` groups window
  rules.
- `hosts/<host>/variables.nix` supplies `monitors`, `monitorProfiles`,
  `browser`, `terminal`, `keyboardLayout`.

## Rules

- Keep the existing `hl.bind(...)` style. Multi-line calls are fine; do not
  reformat unrelated binds.
- Caelestia owns the shell, lock screen, idle handling, and selected theme
  integrations. Do not add Hyprlock or Hypridle.
- Vicinae remains the secondary launcher and clipboard history provider.
- `config/theme.lua` reads Caelestia's generated scheme. Do not hardcode colors.
- Monitor changes go through the host's `monitors`/`monitorProfiles` lists, not
  ad-hoc `monitor=` lines, unless the user asks for the escape hatch.
- The Lua API stubs are generated into `.direnv/hyprland-lua` for LuaLS. Do not
  commit them.

## Verify

```sh
lua tests/hyprland-monitor-profiles.lua
lua tests/hyprland-theme.lua
```

Runtime behavior still needs a Hyprland session; say so instead of claiming it
was tested. Read `modules/home/features/desktop/NEW-DESKTOP.md` before changing
Caelestia ownership or shortcuts.
