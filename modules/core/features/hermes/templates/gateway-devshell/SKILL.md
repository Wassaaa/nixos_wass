---
name: hermes-gateway-devshell
description: Use when a NixOS-managed Hermes gateway needs to add tools, env vars, or helper runtimes to its own mutable home-root devshell without mutating the sealed Hermes package.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [hermes, nixos, gateway, devshell, fleet]
    related_skills: [hermes-agent]
---

# Hermes Gateway Devshell

## Overview

This gateway runs from a NixOS systemd service, but its Unix home directory is a mutable workspace. The service enters this home through `nix develop`, so `~/.hermes/devshell/flake.nix` controls terminal tools available to Hermes after a gateway restart.

Use this skill to decide where dependencies belong:

- Hermes process Python imports: shared Hermes Nix package / `extraDependencyGroups`.
- Terminal CLIs and helper runtimes: this gateway's mutable `~/.hermes/devshell/flake.nix` devshell.
- Project-specific Python packages: local `uv` project or `.venv` under `~/tools` or `~/workspaces`.
- Secrets/provider keys: `~/.hermes/.env`, not committed files.

## Workflow

1. Check whether the missing capability is a CLI/tool or a Python import used inside Hermes itself.
2. For CLIs, edit `~/.hermes/devshell/flake.nix` and add the package to `devShells.x86_64-linux.default.packages`.
3. Verify with `nix develop ~/.hermes/devshell --command bash -lc 'command -v TOOL && TOOL --version'`.
4. Restart the gateway service when the running bot must inherit the new PATH/env.
5. For ad-hoc Python code, create a local helper project with `uv` instead of touching Hermes' sealed runtime.

## Common Pitfalls

- Do not `pip install` into the Nix store or Hermes package environment.
- Do not use `sudo` or edit system NixOS config unless the user explicitly asks.
- `~/.hermes/devshell/.envrc` helps interactive maintenance shells, but the systemd gateway gets its runtime from `nix develop` and `~/.hermes/.env`.
- If a package must be imported by Hermes at startup, adding it to the devshell may not be enough; add it to the shared Hermes package override instead.
- Keep the devshell flake under `~/.hermes/devshell`, not directly at `~/flake.nix`; home-root flakes make Nix scan the entire home tree and can fail on private app data.

## Verification Checklist

- [ ] `nix develop ~/.hermes/devshell --command command -v TOOL` finds the tool.
- [ ] Secrets are only in `~/.hermes/.env` or another explicitly untracked secret file.
- [ ] Helper package state lives under `~/tools` or `~/workspaces`.
- [ ] Gateway service has been restarted if the running process needs the new environment.
