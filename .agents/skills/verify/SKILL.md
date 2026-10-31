---
name: verify
description: Verification commands for this NixOS flake and how to triage the first failure.
---

# Verify

Run the narrowest check that covers the change. The user runs anything that
mutates the system.

## Commands

```sh
# Nix evaluation/build without switching
git add <changed paths>
nix build .#nixosConfigurations.<host>.config.system.build.toplevel --dry-run --no-link

# Formatting and lint (per touched file)
nixfmt <file>
statix check <file>
deadnix <file>

# Hyprland Lua
lua tests/hyprland-monitor-profiles.lua
lua tests/hyprland-theme.lua

# Repository Python
uv run python -m unittest discover -s tests
```

`fbd` is the host alias for the dry-run build. `nix build` and `nix eval` only
see files in the Git index, so `git add` first.

## Triage

- Read the first Nix error, not the last.
- `undefined variable` usually means a missing `inherit` or `specialArgs`.
- `attribute 'x' missing` usually means the option is gated by a feature flag
  that is off for this host.
- `path does not exist` usually means an untracked file or a wrong
  `flakeRoot`/relative path.
- Do not rerun a failing check unchanged; fix the cause or report it.

## Boundaries

- Never run `nh os switch|test|boot`, `nixos-rebuild`, `sudo`, or `sops`.
- Never update `flake.lock` to make a build pass.
- Tests are created on demand. Do not add tests that assert source text,
  formatting, wiring, or defaults.
