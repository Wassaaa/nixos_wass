---
name: sops-secret
description: Work with this repository's SOPS and age secrets: host files, recipients, age keys, and secret consumers.
---

# SOPS secrets

## Layout

- `.sops.yaml` — age recipients and `creation_rules` per host.
- `hosts/<host>/secrets.yaml` — encrypted values for one host.
- `hosts/<host>/ssh_host_ed25519_key.pub` — public host key; the age recipient
  is derived from it with `ssh-to-age`.
- Consumers use `config.sops.secrets.<name>.path`, for example
  `hashedPasswordFile = config.sops.secrets.password.path;`.

## Rules

- Never decrypt into the repository and never print a secret value.
- The user runs `sops hosts/<host>/secrets.yaml`; agents do not run `sops`
  writes or `sops updatekeys`.
- To add a host: add its age key to `.sops.yaml` under `keys:` and
  `creation_rules:`, create `hosts/<host>/secrets.yaml`, then run
  `sops updatekeys` yourself.
- Keep decrypted output, diagnostic dumps, and `journalctl` excerpts out of
  commits and chat.
- A secret with a new name also needs a matching
  `sops.secrets."<name>"` entry in the Nix module that consumes it.

Full setup notes are in `modules/core/sops/sops.nix`. Do not duplicate the key
material in documentation.
