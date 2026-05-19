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

  gatewayWorkspaceFlake = ./templates/gateway-devshell/flake.nix;
  gatewayEnvrc = ./templates/gateway-devshell/envrc;
  gatewayHermesMd = ./templates/gateway-devshell/main-wsl.hermes.md;
  gatewaySkill = ./templates/gateway-devshell/SKILL.md;

  gatewayRunner = pkgs.writeShellScript "hermes-gateway-wsl-run" ''
    set -euo pipefail
    cd /home/${username}
    export HOME=/home/${username}
    export HERMES_HOME=/home/${username}/.hermes
    export NIX_CONFIG="experimental-features = nix-command flakes"
    exec ${pkgs.nix}/bin/nix develop /home/${username}/.hermes/devshell --command ${hermesPkg}/bin/hermes gateway run --replace
  '';

  toolsetPresets = import ./toolset-presets.nix;
  toolsetPresetJson = pkgs.writeText "hermes-toolset-presets.json" (builtins.toJSON toolsetPresets);

  wslGatewayCtl = pkgs.writeShellApplication {
    name = "hermes-wsl";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      jq
      systemd
      sudo
    ];
    text = ''
      export HERMES_BIN="${hermesPkg}/bin/hermes"
      export HERMES_TOOLSET_PRESETS="${toolsetPresetJson}"
      exec ${pkgs.bash}/bin/bash ${./hermes-wsl.sh} "$@"
    '';
  };
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
    wslGatewayCtl

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

  # Bootstrap a per-user mutable devshell and gateway guidance for the main WSL
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
    "C /home/${username}/.hermes/devshell/.envrc 0600 ${username} users - ${gatewayEnvrc}"
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
