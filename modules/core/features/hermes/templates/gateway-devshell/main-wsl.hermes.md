# Hermes Gateway Workspace

This home directory is the persistent workspace for this Hermes gateway identity.

## Runtime model

- Hermes itself is installed by NixOS as a shared, immutable package.
- Mutable Hermes state lives in `~/.hermes` for this Unix user.
- The systemd gateway service starts from this home directory through `nix develop`.
- This directory's `~/.hermes/devshell/flake.nix` controls the mutable devshell for terminal tools and helper projects.
- This directory's `.envrc` is for interactive shells; the service enters the devshell directly with `nix develop`.
- This main WSL user is intentionally treated like a temporary/special fleet-admin gateway identity for now; fleet members use the same devshell pattern.

## Package policy

When managing gateway packages/env, load the `hermes-gateway-devshell` skill if available.

If a needed CLI/tool is missing:

1. Prefer adding it to this gateway's `~/.hermes/devshell/flake.nix` devshell.
2. Verify it with `nix develop ~/.hermes/devshell --command bash -lc 'command -v <tool> && <tool> --version'`.
3. Restart the gateway service when the running gateway process needs to inherit the new PATH/env.
4. Do not install packages into the sealed Hermes/Nix store Python environment.
5. Do not use `sudo`, system package installation, or edits outside this home unless the user explicitly asks.

## Python and Node helper tools

- For Python scripts/tools that Hermes calls from the terminal, create project-local environments under `~/tools/<name>` or `~/workspaces/<name>` with `uv` or `.venv`.
- Do not `pip install` into Hermes' own runtime environment.
- If Hermes itself needs a Python import at process startup, that belongs in the shared Hermes Nix package override / `extraDependencyGroups`, not this devshell.
- For Node tools, prefer stable CLIs from the devshell. Project-specific npm dependencies can live under `~/tools/<name>` or `~/workspaces/<name>`.

## Secrets and env vars

- Gateway secrets, provider keys, and platform tokens normally live in `~/.hermes/.env`.
- Non-secret devshell env vars may live in `.envrc` or the devshell `shellHook`.
- Do not commit secrets into `flake.nix`, `.envrc`, scripts, or notes.
- If a required secret is missing, tell the user the exact env var name to add.

## Boundaries

- This gateway may modify files in its own home directory.
- It should not modify `/etc/nixos`, `/home/wsl/nixos_wass`, or other users' homes unless explicitly instructed.
- Fleet admin ACLs may allow browsing/editing from the main WSL account, but ownership boundaries still matter.
