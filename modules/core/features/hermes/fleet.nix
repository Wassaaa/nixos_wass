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

  # Shared toolset presets for every Hermes gateway helper. Add/edit presets in
  # toolset-presets.nix; helpers consume the resulting attrset/JSON dynamically.
  toolsetPresets = import ./toolset-presets.nix;
  allToolsets = toolsetPresets.all;

  gatewayInstances = {
    admin = {
      user = "hermes-admin";
      description = "Hermes admin gateway user";
      home = "/home/hermes-admin";
      serviceName = "hermes-gateway-admin";
      variants = toolsetPresets.presets;
    };

    user = {
      user = "hermes-user";
      description = "Hermes restricted gateway user";
      home = "/home/hermes-user";
      serviceName = "hermes-gateway-user";
      variants = toolsetPresets.presets;
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

  gatewayWorkspaceFlake = ./templates/gateway-devshell/flake.nix;
  gatewayEnvrc = ./templates/gateway-devshell/envrc;
  gatewayHermesMd = ./templates/gateway-devshell/fleet.hermes.md;
  gatewaySkill = ./templates/gateway-devshell/SKILL.md;

  gatewayRunnerForInstance =
    _name: cfg:
    pkgs.writeShellScript "${cfg.serviceName}-run" ''
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
    "C ${cfg.home}/.hermes/devshell/.envrc 0600 ${cfg.user} users - ${gatewayEnvrc}"
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
  ]
  ++ builtins.map (name: gatewayInstances.${name}.user) (builtins.attrNames gatewayInstances);

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
