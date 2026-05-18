# Hermes Fleet Implementation Plan

> **For Hermes:** This plan documents the target architecture and step-by-step rollout for running multiple Hermes gateways from one deterministic NixOS/WSL install. Execute incrementally; do not jump ahead to secrets or multi-service startup until the previous step is verified.

**Goal:** Run multiple isolated Hermes gateways (`hermes-admin`, `hermes-user`) from one shared Nix-installed Hermes package while keeping each gateway's runtime state mutable in its own home directory.

**Architecture:** NixOS declaratively installs the shared Hermes package and host tooling, creates dedicated Linux users, and eventually defines one systemd service per gateway. Each gateway runs as its own Unix user with its own `$HOME` and `$HERMES_HOME`, giving separate configs, sessions, memories, toolsets, env files, and OS filesystem permissions.

**Tech Stack:** NixOS modules in `/home/wsl/nixos_wass`, local Hermes flake input at `/home/wsl/hermes-agent`, systemd system services, mutable Hermes homes under `/home/<gateway-user>/.hermes`.

---

## Current Design Decisions

- Keep the shared Hermes package deterministic via `inputs.hermes-agent.packages.${pkgs.system}.default` in `modules/core/features/hermes/default.nix`.
- Keep runtime state mutable and outside Nix:
  - `/home/hermes-admin/.hermes`
  - `/home/hermes-user/.hermes`
- Do not set up SOPS/secrets yet.
- Do not put Discord tokens/API keys in Nix.
- Prefer separate Unix users over Hermes profiles for stronger filesystem isolation.
- Prefer system services running as specific users over `hermes gateway install` user units for server-style reproducibility.
- Roll out step by step on NixOS WSL first.

---

## Target Shape

```text
/run/current-system/sw/bin/hermes
  shared deterministic Hermes CLI/package

/home/hermes-admin/.hermes
  admin gateway config, env, auth, memory, sessions, skills

/home/hermes-user/.hermes
  restricted gateway config, env, auth, memory, sessions, skills
```

Eventually:

```text
systemd.services.hermes-gateway-admin
systemd.services.hermes-gateway-user
```

Each service runs the same Hermes binary but with different identity:

```text
User=hermes-admin
HOME=/home/hermes-admin
HERMES_HOME=/home/hermes-admin/.hermes
```

or:

```text
User=hermes-user
HOME=/home/hermes-user
HERMES_HOME=/home/hermes-user/.hermes
```

---

## Step 1: Create Gateway Users Only

**Objective:** Declaratively create `hermes-admin` and `hermes-user` with home directories, but do not start gateways yet.

**Files:**
- Modify or create under `modules/core/features/hermes/`
- Likely create: `modules/core/features/hermes/fleet.nix`
- Modify: `modules/core/features/hermes/default.nix` to import `fleet.nix`

**Implementation notes:**
- Create normal users:
  - `hermes-admin`
  - `hermes-user`
- Ensure homes are created:
  - `/home/hermes-admin`
  - `/home/hermes-user`
- Avoid adding them to `wheel` for now.
- Consider a shared group later, but don't add unnecessary access in Step 1.
- This step should not create or manage secrets.

**Verification after `fr`:**

```bash
id hermes-admin
id hermes-user
getent passwd hermes-admin
getent passwd hermes-user
sudo -u hermes-admin -H env | grep -E '^(HOME|USER)='
sudo -u hermes-user -H env | grep -E '^(HOME|USER)='
```

Optional Hermes smoke test after rebuild:

```bash
sudo -u hermes-admin -H hermes status
sudo -u hermes-user -H hermes status
```

Expected: users exist and Hermes can run as each user, though gateway platforms are not configured yet.

**Status:** Completed in commit `cf268fd` (`feat: add hermes fleet gateway users`).

---

## Step 2: Bootstrap Mutable Hermes Homes

**Objective:** Create minimal `$HERMES_HOME` directories and optional non-secret starter files for each gateway.

**Files:**
- Possibly add activation script in `modules/core/features/hermes/fleet.nix`
- Or add a helper script package first and keep homes manually initialized.

**Implementation notes:**
- Create:
  - `/home/hermes-admin/.hermes`
  - `/home/hermes-user/.hermes`
- Ensure ownership:
  - `hermes-admin:hermes-admin`
  - `hermes-user:hermes-user`
- Do not write real `.env` secrets from Nix.
- Optional: create `.env.example` or README files explaining required manual setup.

**Verification:**

```bash
# Quote the command or use bash -lc so `~` expands as the target user, not the caller.
sudo -u hermes-admin -H bash -lc 'test -d ~/.hermes && echo admin-ok'
sudo -u hermes-user -H bash -lc 'test -d ~/.hermes && echo user-ok'
sudo -u hermes-admin -H hermes config path
sudo -u hermes-user -H hermes config path
```

**Status:** Implemented with `systemd.tmpfiles.rules`; verified both users resolve separate Hermes config paths under their own homes.

---

## Step 3: Add Declarative Gateway Services, Initially Manual Start

**Objective:** Define systemd system services for each gateway without necessarily enabling auto-start yet.

**Files:**
- Modify: `modules/core/features/hermes/fleet.nix`

**Implementation notes:**
- Define:
  - `systemd.services.hermes-gateway-admin`
  - `systemd.services.hermes-gateway-user`
- Each service should run as its matching Unix user.
- Use the shared package path, e.g. `${inputs.hermes-agent.packages.${pkgs.system}.default}/bin/hermes gateway run --replace`.
- Set:
  - `HOME=/home/<user>`
  - `HERMES_HOME=/home/<user>/.hermes`
  - `WorkingDirectory=/home/<user>`
- Use `Restart=always`.
- Prefer making services startable manually first before adding `wantedBy = [ "multi-user.target" ];`.

**Verification after `fr`:**

```bash
systemctl cat hermes-gateway-admin
systemctl cat hermes-gateway-user
systemctl is-enabled hermes-gateway-admin # expected: static or disabled; not enabled yet
systemctl is-enabled hermes-gateway-user  # expected: static or disabled; not enabled yet
```

When env/config is ready, test one service manually:

```bash
sudo systemctl start hermes-gateway-admin
sudo systemctl status hermes-gateway-admin --no-pager
sudo systemctl stop hermes-gateway-admin
```

Repeat for `hermes-user` after its config/env is ready.

**Status:** Implemented in Nix as manual-start services with empty `wantedBy`, exact Hermes package `ExecStart`, per-user `HOME`/`HERMES_HOME`, and a service PATH containing Hermes/media/runtime tools. Full WSL config evaluation succeeds.

---

## Step 4: Manual Gateway/Bot Setup Per User

**Objective:** Configure Discord/API credentials manually per gateway user after `fr`.

**Commands:**

```bash
sudo -u hermes-admin -H hermes gateway setup
sudo -u hermes-user -H hermes gateway setup
```

Or manually edit:

```text
/home/hermes-admin/.hermes/.env
/home/hermes-user/.hermes/.env
```

**Important:** Each Discord gateway should generally use a different Discord bot token. Do not run the same Discord token from multiple gateways simultaneously.

---

## Step 5: Enable Autostart Once Stable

**Objective:** Make gateways start automatically after rebuild/boot.

**Implementation notes:**
- Add `wantedBy = [ "multi-user.target" ];` once services are stable.
- Keep secrets mutable for now.

**Verification:**

```bash
fr
systemctl status hermes-gateway-admin --no-pager
systemctl status hermes-gateway-user --no-pager
```

---

## Later Ideas

- Add a small helper command such as `hermes-fleet-init admin` / `hermes-fleet-status`.
- Add module options like:

```nix
services.wass.hermesFleet = {
  enable = true;
  instances = {
    admin = {
      user = "hermes-admin";
      home = "/home/hermes-admin";
      autoStart = false;
    };
    user = {
      user = "hermes-user";
      home = "/home/hermes-user";
      autoStart = false;
    };
  };
};
```

- Add SOPS/agenix secrets later.
- Consider per-instance toolset templates.
- Consider more restrictive filesystem mounts/sandboxing for `hermes-user` after the basic user boundary works.
