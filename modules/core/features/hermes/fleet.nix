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

  hermesFleet = pkgs.writeShellScriptBin "hermes-fleet" ''
    set -euo pipefail

    HERMES="${hermesPkg}/bin/hermes"
    SYSTEMCTL="/run/current-system/sw/bin/systemctl"
    SUDO="/run/wrappers/bin/sudo"

    usage() {
      cat <<'EOF'
    Usage:
      hermes-fleet variants [admin|user]
      hermes-fleet apply <admin|user> <full|dev>
      hermes-fleet start <admin|user> <full|dev>
      hermes-fleet status [admin|user]

    Notes:
      apply  = set Discord toolsets for the gateway user, do not start service
      start  = apply toolset preset, then restart the gateway service
      status = show systemd state and the Hermes config path for each gateway

    Current variants:
      admin: full, dev
      user:  full
    EOF
    }

    if [[ $# -lt 1 ]]; then
      usage
      exit 2
    fi

    cmd="$1"
    shift || true

    # apply/start need to modify another user's Hermes config and control systemd.
    if [[ "$cmd" == "apply" || "$cmd" == "start" ]]; then
      if [[ "''${EUID}" -ne 0 ]]; then
        exec "$SUDO" "$0" "$cmd" "$@"
      fi
    fi

    gateway_account() {
      case "$1" in
        admin) echo "hermes-admin" ;;
        user) echo "hermes-user" ;;
        *) echo "Unknown gateway '$1' (expected admin or user)" >&2; exit 2 ;;
      esac
    }

    gateway_service() {
      case "$1" in
        admin) echo "hermes-gateway-admin" ;;
        user) echo "hermes-gateway-user" ;;
        *) echo "Unknown gateway '$1' (expected admin or user)" >&2; exit 2 ;;
      esac
    }

    variants_for() {
      case "$1" in
        admin) echo "full dev" ;;
        user) echo "full" ;;
        *) echo "Unknown gateway '$1' (expected admin or user)" >&2; exit 2 ;;
      esac
    }

    # Built-in/configurable toolsets we manage as presets. Platform-scoped or
    # provider-specific tools can still be toggled manually from Discord later.
    ALL_TOOLSETS="web browser terminal file code_execution vision video image_gen video_gen x_search moa tts skills todo memory session_search clarify delegation cronjob messaging homeassistant spotify discord discord_admin yuanbao computer_use"

    preset_toolsets() {
      gateway="$1"
      variant="$2"
      case "$gateway:$variant" in
        admin:full)
          echo "web browser terminal file code_execution vision video image_gen video_gen tts skills todo memory session_search clarify delegation cronjob messaging computer_use"
          ;;
        admin:dev)
          echo "web browser terminal file code_execution vision skills todo memory session_search clarify delegation cronjob"
          ;;
        user:full)
          echo "web browser terminal file code_execution vision video image_gen video_gen tts skills todo memory session_search clarify delegation cronjob messaging computer_use"
          ;;
        *)
          echo "Variant '$variant' is not defined for gateway '$gateway'. Available: $(variants_for "$gateway")" >&2
          exit 2
          ;;
      esac
    }

    apply_variant() {
      gateway="$1"
      variant="$2"
      account="$(gateway_account "$gateway")"
      toolsets="$(preset_toolsets "$gateway" "$variant")"

      echo "Applying '$variant' Discord toolset preset for $account"
      "$SUDO" -u "$account" -H "$HERMES" tools disable --platform discord $ALL_TOOLSETS >/dev/null || true
      "$SUDO" -u "$account" -H "$HERMES" tools enable --platform discord $toolsets
      echo "Config path: $($SUDO -u "$account" -H "$HERMES" config path)"
    }

    show_status() {
      gateway="$1"
      account="$(gateway_account "$gateway")"
      service="$(gateway_service "$gateway")"
      echo "== $gateway ($account / $service) =="
      "$SYSTEMCTL" is-active "$service" 2>/dev/null || true
      "$SYSTEMCTL" is-enabled "$service" 2>/dev/null || true
      "$SUDO" -u "$account" -H "$HERMES" config path
      "$SUDO" -u "$account" -H "$HERMES" tools list --platform discord | ${pkgs.gnused}/bin/sed -n '1,80p'
    }

    case "$cmd" in
      variants)
        if [[ $# -eq 0 ]]; then
          echo "admin: $(variants_for admin)"
          echo "user:  $(variants_for user)"
        else
          echo "$1: $(variants_for "$1")"
        fi
        ;;
      apply)
        [[ $# -eq 2 ]] || { usage; exit 2; }
        apply_variant "$1" "$2"
        ;;
      start)
        [[ $# -eq 2 ]] || { usage; exit 2; }
        apply_variant "$1" "$2"
        service="$(gateway_service "$1")"
        "$SYSTEMCTL" reset-failed "$service" || true
        "$SYSTEMCTL" restart "$service"
        "$SYSTEMCTL" status "$service" --no-pager
        ;;
      status)
        if [[ $# -eq 0 ]]; then
          show_status admin
          echo
          show_status user
        else
          show_status "$1"
        fi
        ;;
      -h|--help|help)
        usage
        ;;
      *)
        usage
        exit 2
        ;;
    esac
  '';
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

  environment.systemPackages = [
    hermesFleet
  ];

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
