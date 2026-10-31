# AGENTS.md

Cross-tool entry point for AI agents working in this repository. The repository
map and hard rules are here; the project-specific procedures live in
[`.agents/skills/`](.agents/skills). Read the matching skill before changing the
flake.

## Hard rules

- The user runs `nh os build|test|switch|boot`, `nixos-rebuild`, `sudo`, and
  `sops` writes. Never run them or embed them in generated scripts.
- Verify with read-only commands only:
  `nix build .#nixosConfigurations.<host>.config.system.build.toplevel --dry-run --no-link`.
  Lint the files you touched with `nixfmt --check <file>`,
  `statix check <file>` and `deadnix <file>`.
- Nix only sees files in the Git index. Run `git add <path>` before evaluating
  or building.
- Never write secrets into Nix files. Read them through
  `config.sops.secrets.<name>.path`.
- Change one layer at a time: host variables, then feature imports, then the
  module, then packages.
- Do not update `flake.lock` unless the task is an input update.
- Commit only when asked; the user controls how commits are published.

## Repository map

- `hosts/<host>/variables.nix` — feature flags, monitors, browser, terminal,
  shell, keyboard, git identity.
- `hosts/<host>/default.nix` — host wiring; `hardware.nix`; `host-packages.nix`.
- `profiles/` — driver presets: `nvidia`, `intel`, `vm`, `wsl`.
- `modules/core/features.nix` — conditional system imports.
- `modules/home/features.nix` — conditional Home Manager imports.
- `modules/core/` — system modules; `modules/home/` — Home Manager modules.
- `modules/home/features/desktop/hyprland/config/` — out-of-store Lua.
- `docs/` — research notes; [`docs/README.md`](docs/README.md) is the index.

## Verification

- Nix: `nixfmt <file>`, then `statix check <file>` and `deadnix <file>` on
  touched files. The repository has pre-existing lint and formatting findings.
- Python: `uv run python -m unittest discover -s tests`.
- Hyprland Lua: `lua tests/hyprland-monitor-profiles.lua` and
  `lua tests/hyprland-theme.lua`.
- Tests are added on demand. Do not add tests for wiring, source text, or
  incidental formatting.

## Skills

Read `.agents/skills/<name>/SKILL.md` before the matching change:

- `nixos-change` — hosts, feature flags, modules, packages.
- `hyprland-lua` — Hyprland config, keybinds, monitors, theme.
- `sops-secret` — host secrets, recipients, age keys.
- `verify` — commands and failure triage.
