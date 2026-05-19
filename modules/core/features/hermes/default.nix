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

  codeToolsets = [
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

  wslGatewayCtl = pkgs.writeShellApplication {
    name = "hermes-wsl";
    runtimeInputs = with pkgs; [
      coreutils
      systemd
      sudo
    ];
    text = ''
            set -euo pipefail

            unit="hermes-gateway-wsl.service"
            hermes=${hermesPkg}/bin/hermes
            all_toolsets="${builtins.concatStringsSep " " allToolsets}"
            full_toolsets="${builtins.concatStringsSep " " fullToolsets}"
            code_toolsets="${builtins.concatStringsSep " " codeToolsets}"

            usage() {
              cat <<'EOF'
      Usage: hermes-wsl <command>

      Manage the main WSL Hermes gateway systemd service and Discord toolset preset.

      Commands:
        status          Show service status
        logs [LINES]    Show recent logs
        follow          Follow logs
        start [PRESET]  Apply preset, then start the gateway
        stop            Stop the gateway
        restart         Restart the gateway without changing preset
        enable          Enable autostart
        disable         Disable autostart
        unit            Show the systemd unit
        variants        List available toolset presets
        apply PRESET    Apply Discord toolset preset without restarting
        help            Show this help

      Presets:
        full            Broad tool access for admin work
        code            Coding/dev-focused tools
      EOF
            }

            toolsets_for() {
              case "$1" in
                full) printf '%s\n' "$full_toolsets" ;;
                code) printf '%s\n' "$code_toolsets" ;;
                *) echo "unknown preset: $1" >&2; echo "available presets: full code" >&2; exit 2 ;;
              esac
            }

            apply_preset() {
              preset="$1"
              enable_toolsets="$(toolsets_for "$preset")"
              echo "Applying '$preset' Discord toolset preset for main WSL gateway"
              # shellcheck disable=SC2086
              "$hermes" tools disable --platform discord $all_toolsets >/dev/null || true
              # shellcheck disable=SC2086
              "$hermes" tools enable --platform discord $enable_toolsets
              echo "Config path: $("$hermes" config path)"
              echo "Restart the gateway, or use: hermes-wsl start $preset"
            }

            cmd="''${1:-status}"
            shift || true
            case "$cmd" in
              status)
                systemctl status "$unit" --no-pager
                ;;
              logs)
                journalctl -u "$unit" -n "''${1:-120}" --no-pager
                ;;
              follow|tail)
                journalctl -u "$unit" -f
                ;;
              start)
                preset="''${1:-code}"
                apply_preset "$preset"
                exec sudo systemctl restart "$unit"
                ;;
              stop|restart|enable|disable)
                exec sudo systemctl "$cmd" "$unit"
                ;;
              unit|cat)
                systemctl cat "$unit" --no-pager
                ;;
              variants)
                printf '%s\n' "full" "code"
                ;;
              apply)
                [[ $# -eq 1 ]] || { usage >&2; exit 2; }
                apply_preset "$1"
                ;;
              help|-h|--help)
                usage
                ;;
              *)
                echo "unknown command: $cmd" >&2
                usage >&2
                exit 2
                ;;
            esac
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
