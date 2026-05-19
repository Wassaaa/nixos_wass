{
  pkgs,
  inputs,
  username,
  ...
}:

let
  hermesPkg = inputs.hermes-agent.packages.${pkgs.system}.default.override {
    # Keep local feature choices outside the Hermes upstream checkout so the
    # base repo can update cleanly. These groups add Discord/Telegram gateway
    # deps and ElevenLabs TTS support to the sealed Hermes Python env.
    extraDependencyGroups = [
      "messaging"
      "tts-premium"
    ];
  };

  gatewayWorkspaceFlake = pkgs.writeText "hermes-gateway-workspace-flake.nix" ''
    {
      description = "Mutable devshell for this Hermes gateway identity";

      inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

      outputs = { self, nixpkgs }:
        let
          system = "x86_64-linux";
          pkgs = import nixpkgs { inherit system; };
        in {
          devShells.''${system}.default = pkgs.mkShell {
            packages = with pkgs; [
              # Baseline shell/system tools
              bashInteractive
              coreutils
              git
              curl
              jq
              ripgrep
              fd
              direnv

              # Media/voice/document tools commonly used by Hermes skills
              ffmpeg
              imagemagick
              mediainfo
              exiftool
              sox

              # Language/package managers for gateway-owned helper tools
              nodejs_24
              python312
              uv
            ];

            shellHook = "export HERMES_GATEWAY_WORKSPACE=\"$PWD\"\nexport HERMES_MUTABLE_DEVSHELL=1\n";
          };
        };
    }
  '';

  gatewayEnvrc = pkgs.writeText "hermes-gateway-envrc" ''
    use flake ./.hermes/devshell

    export HERMES_GATEWAY_WORKSPACE="$PWD"
    export HERMES_MUTABLE_DEVSHELL=1

    # Optional non-committed per-workspace env for convenience. Keep real gateway
    # secrets in ~/.hermes/.env unless this user intentionally chooses otherwise.
    dotenv_if_exists .env.local
  '';

  gatewayHermesMd = pkgs.writeText "hermes-gateway-hermes.md" ''
    # Hermes Gateway Workspace

    This home directory is the persistent workspace for this Hermes gateway identity.

    ## Runtime model

    - Hermes itself is installed by NixOS as a shared, immutable package.
    - Mutable Hermes state lives in `~/.hermes` for this Unix user.
    - The systemd gateway service starts from this home directory through `nix develop`.
    - This directory's `~/.hermes/devshell/flake.nix` controls the mutable devshell for terminal tools and helper projects.
    - This directory's `.envrc` is for interactive shells; the service enters the devshell directly with `nix develop`.

    ## Package policy

    When managing gateway packages/env, load the `hermes-gateway-devshell` skill if available.

    If a needed CLI/tool is missing:

    1. Prefer adding it to this gateway's `~/.hermes/devshell/flake.nix` devshell.
    2. Verify it with `nix develop --command bash -lc 'command -v <tool> && <tool> --version'`.
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
  '';


  gatewaySkill = pkgs.writeText "hermes-gateway-devshell-SKILL.md" ''
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

    This gateway runs from a NixOS systemd service, but its Unix home directory is a mutable workspace. The service enters this home through `nix develop`, so the `~/.hermes/devshell/flake.nix` controls terminal tools available to Hermes after a gateway restart.

    Use this skill to decide where dependencies belong:

    - Hermes process Python imports: shared Hermes Nix package / `extraDependencyGroups`.
    - Terminal CLIs and helper runtimes: this gateway's mutable `~/.hermes/devshell/flake.nix` devshell.
    - Project-specific Python packages: local `uv` project or `.venv` under `~/tools` or `~/workspaces`.
    - Secrets/provider keys: `~/.hermes/.env`, not committed files.

    ## Workflow

    1. Check whether the missing capability is a CLI/tool or a Python import used inside Hermes itself.
    2. For CLIs, edit `~/.hermes/devshell/flake.nix` and add the package to `devShells.x86_64-linux.default.packages`.
    3. Verify with `nix develop --command bash -lc 'command -v TOOL && TOOL --version'`.
    4. Restart the gateway service when the running bot must inherit the new PATH/env.
    5. For ad-hoc Python code, create a local helper project with `uv` instead of touching Hermes' sealed runtime.

    ## Common Pitfalls

    - Do not `pip install` into the Nix store or Hermes package environment.
    - Do not use `sudo` or edit system NixOS config unless the user explicitly asks.
    - `.envrc` helps interactive shells, but the systemd gateway gets its runtime from `nix develop` and `~/.hermes/.env`.
    - If a package must be imported by Hermes at startup, adding it to the devshell may not be enough; add it to the shared Hermes package override instead.

    ## Verification Checklist

    - [ ] `nix develop --command command -v TOOL` finds the tool.
    - [ ] Secrets are only in `~/.hermes/.env` or another explicitly untracked secret file.
    - [ ] Helper package state lives under `~/tools` or `~/workspaces`.
    - [ ] Gateway service has been restarted if the running process needs the new environment.
  '';

  gatewayRunner = pkgs.writeShellScript "hermes-gateway-wsl-run" ''
    set -euo pipefail
    cd /home/${username}
    export HOME=/home/${username}
    export HERMES_HOME=/home/${username}/.hermes
    export NIX_CONFIG="experimental-features = nix-command flakes"
    exec ${pkgs.nix}/bin/nix develop /home/${username}/.hermes/devshell --command ${hermesPkg}/bin/hermes gateway run --replace
  '';
in
{
  imports = [
    ./fleet.nix
  ];

  # Shared Hermes feature: install the Hermes CLI/package and host-side tools the
  # agent can call from terminal/tools/skills. Runtime state intentionally stays
  # mutable in each gateway user's HOME (~/.hermes); secrets, auth.json,
  # sessions, memory, and user-installed skills are not Nix-managed.
  environment.systemPackages = with pkgs; [
    hermesPkg

    # Agent/media/video generation runtime tools
    ffmpeg
    imagemagick
    mediainfo
    exiftool
    sox

    # Audio/TTS/build/runtime libraries
    libopus
    portaudio
    espeak-ng

    # JS/browser-ish tooling commonly needed by Hermes skills/plugins
    nodejs_24
    uv
    direnv
  ];

  # Bootstrap a home-root mutable devshell and gateway guidance for the main WSL
  # identity. `C` copies only when the destination is absent, so the gateway/user
  # can freely edit these files after the first activation.
  systemd.tmpfiles.rules = [
    "d /home/${username}/.hermes 0700 ${username} users - -"
    "d /home/${username}/tools 0750 ${username} users - -"
    "d /home/${username}/workspaces 0750 ${username} users - -"
    "d /home/${username}/.hermes/devshell 0700 ${username} users - -"
    "d /home/${username}/.hermes/skills 0700 ${username} users - -"
    "d /home/${username}/.hermes/skills/devops 0700 ${username} users - -"
    "d /home/${username}/.hermes/skills/devops/hermes-gateway-devshell 0700 ${username} users - -"
    "C /home/${username}/.hermes/skills/devops/hermes-gateway-devshell/SKILL.md 0600 ${username} users - ${gatewaySkill}"
    "C /home/${username}/.hermes/devshell/flake.nix 0600 ${username} users - ${gatewayWorkspaceFlake}"
    "C /home/${username}/.envrc 0644 ${username} users - ${gatewayEnvrc}"
    "C /home/${username}/.hermes.md 0644 ${username} users - ${gatewayHermesMd}"
  ];

  # Declarative replacement for the mutable `hermes gateway install` user unit
  # used by the main WSL account. Runtime state stays mutable in
  # /home/${username}/.hermes; Nix owns the service and baseline package, while
  # /home/${username}/.hermes/devshell/flake.nix owns the gateway's mutable devshell.
  # Manual-start for now so it does not race the existing user unit that uses the
  # same Discord bot token. After migration, add wantedBy = [ "multi-user.target" ].
  systemd.services.hermes-gateway-wsl = {
    description = "Hermes Agent Gateway (${username})";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    path = with pkgs; [
      nix
      hermesPkg
      bashInteractive
      coreutils
      git
      ripgrep
      fd
      curl
      jq
      direnv
      nodejs_24
      uv
      ffmpeg
      imagemagick
      mediainfo
      exiftool
      sox
    ];

    environment = {
      HOME = "/home/${username}";
      HERMES_HOME = "/home/${username}/.hermes";
      NIX_CONFIG = "experimental-features = nix-command flakes";
      LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.libopus ];
    };

    serviceConfig = {
      Type = "simple";
      User = username;
      Group = "users";
      WorkingDirectory = "/home/${username}";
      ExecStart = gatewayRunner;
      Restart = "always";
      RestartSec = 5;
      KillMode = "mixed";
      KillSignal = "SIGTERM";
      TimeoutStopSec = 210;
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };
}
