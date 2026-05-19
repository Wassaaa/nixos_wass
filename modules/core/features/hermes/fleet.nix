{
  pkgs,
  inputs,
  username,
  ...
}:

let
  hermesPkg = inputs.hermes-agent.packages.${pkgs.system}.default.override {
    # Keep fleet services on the same Hermes runtime as the interactive install:
    # Discord gateway/voice deps plus ElevenLabs TTS live inside Hermes' sealed
    # Python env, while ffmpeg/libopus/etc. are provided through service PATH.
    extraDependencyGroups = [
      "messaging"
      "tts-premium"
    ];
  };
  fleetAdminUser = username;

  # Built-in/configurable toolsets managed by the fleet presets. Platform-scoped
  # or provider-specific tools can still be toggled manually from Discord later.
  allToolsets = [
    "web"
    "browser"
    "terminal"
    "file"
    "code_execution"
    "vision"
    "video"
    "image_gen"
    "video_gen"
    "x_search"
    "moa"
    "tts"
    "skills"
    "todo"
    "memory"
    "session_search"
    "clarify"
    "delegation"
    "cronjob"
    "messaging"
    "homeassistant"
    "spotify"
    "discord"
    "discord_admin"
    "yuanbao"
    "computer_use"
  ];

  fullToolsets = [
    "web"
    "browser"
    "terminal"
    "file"
    "code_execution"
    "vision"
    "video"
    "image_gen"
    "video_gen"
    "tts"
    "skills"
    "todo"
    "memory"
    "session_search"
    "clarify"
    "delegation"
    "cronjob"
    "messaging"
    "computer_use"
  ];

  devToolsets = [
    "web"
    "browser"
    "terminal"
    "file"
    "code_execution"
    "vision"
    "skills"
    "todo"
    "memory"
    "session_search"
    "clarify"
    "delegation"
    "cronjob"
  ];

  gatewayInstances = {
    admin = {
      user = "hermes-admin";
      description = "Hermes admin gateway user";
      home = "/home/hermes-admin";
      serviceName = "hermes-gateway-admin";
      variants = {
        full = fullToolsets;
        dev = devToolsets;
      };
    };

    user = {
      user = "hermes-user";
      description = "Hermes restricted gateway user";
      home = "/home/hermes-user";
      serviceName = "hermes-gateway-user";
      variants = {
        full = fullToolsets;
      };
    };
  };

  # Strip Nix-only/module-only fields from the helper's runtime config and render
  # the fleet data as JSON. The shell helper reads this instead of hardcoding
  # usernames, services, homes, or variants.
  helperInstances = builtins.mapAttrs (_name: cfg: {
    inherit (cfg)
      user
      home
      serviceName
      variants
      ;
  }) gatewayInstances;

  fleetConfigJson = pkgs.writeText "hermes-fleet.json" (
    builtins.toJSON {
      inherit allToolsets;
      instances = helperInstances;
    }
  );


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
              bashInteractive
              coreutils
              git
              curl
              jq
              ripgrep
              fd
              direnv
              ffmpeg
              imagemagick
              mediainfo
              exiftool
              sox
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
    dotenv_if_exists .env.local
  '';

  gatewayHermesMd = pkgs.writeText "hermes-gateway-hermes.md" ''
    # Hermes Fleet Gateway Workspace

    This home directory is the persistent workspace for this Hermes fleet gateway identity.

    ## Runtime model

    - Hermes itself is installed by NixOS as a shared, immutable package.
    - Mutable Hermes state lives in `~/.hermes` for this Unix user.
    - The gateway service starts from this home directory through `nix develop`.
    - This directory's `~/.hermes/devshell/flake.nix` controls the mutable devshell for terminal tools and helper projects.
    - This directory's `.envrc` is for interactive shells; the service enters the devshell directly with `nix develop`.

    ## Package policy

    When managing gateway packages/env, load the `hermes-gateway-devshell` skill if available.

    If a needed CLI/tool is missing:

    1. Prefer adding it to this gateway's `~/.hermes/devshell/flake.nix` devshell.
    2. Verify it with `nix develop --command bash -lc 'command -v <tool> && <tool> --version'`.
    3. Restart this gateway service when the running process needs to inherit the new PATH/env.
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
    - The main WSL account may have ACL browse/edit access for administration; do not assume other fleet homes are part of this workspace.
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

  gatewayRunnerForInstance = _name: cfg: pkgs.writeShellScript "${cfg.serviceName}-run" ''
    set -euo pipefail
    cd ${cfg.home}
    export HOME=${cfg.home}
    export HERMES_HOME=${cfg.home}/.hermes
    export NIX_CONFIG="experimental-features = nix-command flakes"
    exec ${pkgs.nix}/bin/nix develop ${cfg.home}/.hermes/devshell --command ${hermesPkg}/bin/hermes gateway run --replace
  '';

  hermesFleet = pkgs.writeShellApplication {
    name = "hermes-fleet";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      gnused
      jq
      systemd
    ];
    text = ''
      export HERMES_FLEET_CONFIG="${fleetConfigJson}"
      export HERMES_BIN="${hermesPkg}/bin/hermes"
      export HERMES_FLEET_SELF="$0"
      exec ${pkgs.bash}/bin/bash ${./hermes-fleet.sh} "$@"
    '';
  };

  tmpfilesForInstance = _name: cfg: [
    "d ${cfg.home}/.hermes 0700 ${cfg.user} users - -"
    "d ${cfg.home}/.hermes/logs 0700 ${cfg.user} users - -"
    "d ${cfg.home}/.hermes/sessions 0700 ${cfg.user} users - -"
    "d ${cfg.home}/tools 0750 ${cfg.user} users - -"
    "d ${cfg.home}/workspaces 0750 ${cfg.user} users - -"
    "d ${cfg.home}/.hermes/devshell 0700 ${cfg.user} users - -"
    "d ${cfg.home}/.hermes/skills 0700 ${cfg.user} users - -"
    "d ${cfg.home}/.hermes/skills/devops 0700 ${cfg.user} users - -"
    "d ${cfg.home}/.hermes/skills/devops/hermes-gateway-devshell 0700 ${cfg.user} users - -"
    "C ${cfg.home}/.hermes/skills/devops/hermes-gateway-devshell/SKILL.md 0600 ${cfg.user} users - ${gatewaySkill}"
    "C ${cfg.home}/.hermes/devshell/flake.nix 0600 ${cfg.user} users - ${gatewayWorkspaceFlake}"
    "C ${cfg.home}/.envrc 0644 ${cfg.user} users - ${gatewayEnvrc}"
    "C ${cfg.home}/.hermes.md 0644 ${cfg.user} users - ${gatewayHermesMd}"
  ];

  serviceForInstance = _name: cfg: {
    name = cfg.serviceName;
    value = {
      description = "Hermes Agent Gateway (${cfg.user})";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      # No wantedBy yet: these services are defined declaratively but manual-start
      # only until each bot token/env/config is ready.

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
        HOME = cfg.home;
        HERMES_HOME = "${cfg.home}/.hermes";
        NIX_CONFIG = "experimental-features = nix-command flakes";
        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.libopus ];
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = "users";
        WorkingDirectory = cfg.home;
        ExecStart = gatewayRunnerForInstance _name cfg;
        Restart = "always";
        RestartSec = 5;
        KillMode = "mixed";
        KillSignal = "SIGTERM";
        TimeoutStopSec = 210;
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };
  };

  userForInstance = _name: cfg: {
    name = cfg.user;
    value = {
      isNormalUser = true;
      inherit (cfg) description home;
      createHome = true;
      group = "users";
      extraGroups = [ ];
      shell = pkgs.bashInteractive;
    };
  };

  adminAclForInstance = _name: cfg: ''
    if ${pkgs.coreutils}/bin/id -u ${fleetAdminUser} >/dev/null 2>&1 && [ -d ${cfg.home} ]; then
      echo "Granting ${fleetAdminUser} admin ACL access to ${cfg.home}"
      ${pkgs.acl}/bin/setfacl -m u:${fleetAdminUser}:rwx ${cfg.home}
      ${pkgs.acl}/bin/setfacl -R -m u:${fleetAdminUser}:rwX ${cfg.home}
      ${pkgs.acl}/bin/setfacl -R -d -m u:${fleetAdminUser}:rwX ${cfg.home}
    fi
  '';

  adminAclScript = builtins.concatStringsSep "
" (
    builtins.map (name: adminAclForInstance name gatewayInstances.${name}) (
      builtins.attrNames gatewayInstances
    )
  );
in
{
  # Step 1 of the Hermes fleet rollout: create the gateway identities only.
  # Each user gets its own HOME and eventually its own mutable ~/.hermes state.
  # Do not add wheel/sudo/secrets/services here yet; those are later steps in
  # docs/plans/hermes-fleet.md.
  users.users = builtins.listToAttrs (
    builtins.map (name: userForInstance name gatewayInstances.${name}) (
      builtins.attrNames gatewayInstances
    )
  );

  environment.systemPackages = [
    hermesFleet
    pkgs.acl
  ];

  # Fleet gateway services enter their per-user devshells with `nix develop`, so
  # the Nix daemon must allow those non-login service users to talk to the store.
  nix.settings.allowed-users = [
    fleetAdminUser
  ] ++ builtins.map (name: gatewayInstances.${name}.user) (
    builtins.attrNames gatewayInstances
  );

  # This is a single-user/admin WSL host: the normal `wsl` account is allowed to
  # browse and edit every Hermes fleet user's full home from VS Code. Ownership
  # remains with each gateway user, and future files inherit the ACL.
  system.activationScripts.hermesFleetAdminHomeAcls.text = adminAclScript;

  # Step 2: bootstrap the mutable Hermes state directories. These directories
  # are intentionally state, not Nix-owned config: config.yaml, .env, auth.json,
  # sessions, memory, and installed skills remain editable by each gateway user.
  systemd.tmpfiles.rules = builtins.concatLists (
    builtins.map (name: tmpfilesForInstance name gatewayInstances.${name}) (
      builtins.attrNames gatewayInstances
    )
  );

  # Step 3: define gateway system services, but do not autostart them yet.
  # They are manually startable with `sudo systemctl start hermes-gateway-admin`
  # after each user's ~/.hermes/.env/config.yaml has been configured.
  systemd.services = builtins.listToAttrs (
    builtins.map (name: serviceForInstance name gatewayInstances.${name}) (
      builtins.attrNames gatewayInstances
    )
  );
}
