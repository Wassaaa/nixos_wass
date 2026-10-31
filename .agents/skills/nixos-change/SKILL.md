---
name: nixos-change
description: Change this NixOS flake safely: host variables, feature flags, module imports, system packages, and build verification.
---

# NixOS change

## Where a change belongs

1. Host-specific value or toggle: `hosts/<host>/variables.nix`.
2. Host wiring: `hosts/<host>/default.nix`, `hardware.nix`, `host-packages.nix`.
3. Driver choice: `profiles/<nvidia|intel|vm|wsl>/`.
4. System service or module: `modules/core/`, then gate it in
   `modules/core/features.nix`.
5. User package or dotfile: `modules/home/`, then gate it in
   `modules/home/features.nix`.

New features get a flag in every host's `variables.nix` and a
`lib.optionals cfg.enable <import>` entry. Do not import a feature module
unconditionally.

## Conventions

- Read host values with the existing pattern:
  `inherit (import "${flakeRoot}/hosts/${host}/variables.nix") enableDesktop ...`
- Use `${flakeRoot}` or relative paths; never hardcode `/home/wassaa/...`.
- Available `specialArgs`: `inputs`, `username`, `host`, `profile`, `flakeRoot`.
- Module shape is `options.<ns>.enable = mkEnableOption ...` plus
  `config = mkIf cfg.enable { ... }`.
- Reuse an existing module or package location before adding a new file.
- Keep GNOME and non-Hyprland sessions working when changing desktop code.
- Never put secrets in a `.nix` file. Use `config.sops.secrets.<name>.path`.
- Home Manager is wired in `modules/core/user.nix`; `modules/home/default.nix`
  loads `features.nix`, which gates the user feature modules.
- Profiles set drivers only (`drivers.<name>.enable`); everything else belongs
  to the host.

## New host

1. Create `hosts/<host>/variables.nix`, `default.nix` and `hardware.nix`; add
   `host-packages.nix` only for host-only packages.
2. Add the public host key as `hosts/<host>/ssh_host_ed25519_key.pub` and derive
   the age recipient with `ssh-to-age`.
3. Add the recipient to `.sops.yaml` under `keys` and `creation_rules`, then
   create `hosts/<host>/secrets.yaml`.
4. Add the host to `flake.nix` `nixosConfigurations` with `mkSystem` and select
   a profile.
5. Verify with `nix build .#nixosConfigurations.<host>... --dry-run`.

## Pitfalls

- Hardcoded paths instead of `${flakeRoot}`.
- Adding a package to core when a feature flag should gate it.
- Importing a feature module without enabling its flag in every host.
- Putting plaintext secrets in a `.nix` file.
- Changing `flake.lock` to make an unrelated build pass.

## Verify

The user applies changes; agents only evaluate.

```sh
git add <changed paths>
nix build .#nixosConfigurations.<host>.config.system.build.toplevel --dry-run --no-link
nixfmt <changed files>
statix check <changed files>
deadnix <changed files>
```

`fbd` is the host alias for the same dry-run build. If evaluation fails, read
the first error and fix that layer before changing anything else.
