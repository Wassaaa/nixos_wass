{ pkgs, inputs, ... }:

let
  hermesPkg = inputs.hermes-agent.packages.${pkgs.system}.default;

  gatewayUsers = {
    hermes-admin = {
      description = "Hermes admin gateway user";
      home = "/home/hermes-admin";
      serviceName = "hermes-gateway-admin";
    };
    hermes-user = {
      description = "Hermes restricted gateway user";
      home = "/home/hermes-user";
      serviceName = "hermes-gateway-user";
    };
  };
in
{
  # Step 1 of the Hermes fleet rollout: create the gateway identities only.
  # Each user gets its own HOME and eventually its own mutable ~/.hermes state.
  # Do not add wheel/sudo/secrets/services here yet; those are later steps in
  # docs/plans/hermes-fleet.md.
  users.users = builtins.mapAttrs (_name: userCfg: {
    isNormalUser = true;
    inherit (userCfg) description home;
    createHome = true;
    group = "users";
    extraGroups = [ ];
    shell = pkgs.bashInteractive;
  }) gatewayUsers;

  # Step 2: bootstrap the mutable Hermes state directories. These directories
  # are intentionally state, not Nix-owned config: config.yaml, .env, auth.json,
  # sessions, memory, and installed skills remain editable by each gateway user.
  systemd.tmpfiles.rules = builtins.concatLists (
    builtins.attrValues (
      builtins.mapAttrs (_name: userCfg: [
        "d ${userCfg.home}/.hermes 0700 ${_name} users - -"
        "d ${userCfg.home}/.hermes/logs 0700 ${_name} users - -"
        "d ${userCfg.home}/.hermes/sessions 0700 ${_name} users - -"
      ]) gatewayUsers
    )
  );

  # Step 3: define gateway system services, but do not autostart them yet.
  # They are manually startable with `sudo systemctl start hermes-gateway-admin`
  # after each user's ~/.hermes/.env/config.yaml has been configured.
  systemd.services = builtins.listToAttrs (
    builtins.attrValues (
      builtins.mapAttrs (name: userCfg: {
        name = userCfg.serviceName;
        value = {
          description = "Hermes Agent Gateway (${name})";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];

          # No wantedBy yet: these services are defined declaratively but manual-start
          # only until each bot token/env/config is ready.

          path = with pkgs; [
            hermesPkg
            bashInteractive
            coreutils
            git
            ripgrep
            fd
            curl
            nodejs_24
            ffmpeg
            imagemagick
            mediainfo
            exiftool
            sox
          ];

          environment = {
            HOME = userCfg.home;
            HERMES_HOME = "${userCfg.home}/.hermes";
          };

          serviceConfig = {
            Type = "simple";
            User = name;
            Group = "users";
            WorkingDirectory = userCfg.home;
            ExecStart = "${hermesPkg}/bin/hermes gateway run --replace";
            Restart = "always";
            RestartSec = 5;
            KillMode = "mixed";
            KillSignal = "SIGTERM";
            TimeoutStopSec = 210;
            StandardOutput = "journal";
            StandardError = "journal";
          };
        };
      }) gatewayUsers
    )
  );
}
