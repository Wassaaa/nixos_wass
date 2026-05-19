#!/usr/bin/env bash
set -euo pipefail

UNIT=${HERMES_WSL_UNIT:-hermes-gateway-wsl.service}
HERMES=${HERMES_BIN:?HERMES_BIN is not set}
PRESET_CONFIG=${HERMES_TOOLSET_PRESETS:?HERMES_TOOLSET_PRESETS is not set}
SYSTEMCTL=${SYSTEMCTL:-/run/current-system/sw/bin/systemctl}
JOURNALCTL=${JOURNALCTL:-/run/current-system/sw/bin/journalctl}
SUDO=${SUDO:-/run/wrappers/bin/sudo}

usage() {
  cat <<'EOF'
Usage: hermes-wsl <command>

Manage the main WSL Hermes gateway systemd service and Discord toolset preset.

Commands:
  status          Show service status
  logs [LINES]    Show recent logs
  follow          Follow logs
  start [PRESET]  Apply preset, then start the gateway (default: code)
  stop            Stop the gateway
  restart         Restart the gateway without changing preset
  enable          Enable autostart
  disable         Disable autostart
  unit            Show the systemd unit
  variants        List available toolset presets
  apply PRESET    Apply Discord toolset preset without restarting
  help            Show this help

Preset definitions come from modules/core/features/hermes/toolset-presets.nix.
EOF
}

variants() {
  jq -r '.presets | keys[]' "$PRESET_CONFIG"
}

require_preset() {
  local preset="$1"
  if ! jq -e --arg preset "$preset" '.presets[$preset] != null' "$PRESET_CONFIG" >/dev/null; then
    echo "unknown preset: $preset" >&2
    echo "available presets: $(variants | tr '\n' ' ')" >&2
    exit 2
  fi
}

apply_preset() {
  local preset="$1"
  require_preset "$preset"

  echo "Applying '$preset' Discord toolset preset for main WSL gateway"

  mapfile -t disable_toolsets < <(jq -r '.all[]' "$PRESET_CONFIG")
  mapfile -t enable_toolsets < <(jq -r --arg preset "$preset" '.presets[$preset][]' "$PRESET_CONFIG")

  "$HERMES" tools disable --platform discord "${disable_toolsets[@]}" >/dev/null || true
  "$HERMES" tools enable --platform discord "${enable_toolsets[@]}"

  echo "Config path: $("$HERMES" config path)"
  echo "Restart the gateway, or use: hermes-wsl start $preset"
}

main() {
  local cmd="${1:-status}"
  shift || true

  case "$cmd" in
    status)
      "$SYSTEMCTL" status "$UNIT" --no-pager
      ;;
    logs)
      "$JOURNALCTL" -u "$UNIT" -n "${1:-120}" --no-pager
      ;;
    follow|tail)
      "$JOURNALCTL" -u "$UNIT" -f
      ;;
    start)
      local preset="${1:-code}"
      apply_preset "$preset"
      exec "$SUDO" "$SYSTEMCTL" restart "$UNIT"
      ;;
    stop|restart|enable|disable)
      exec "$SUDO" "$SYSTEMCTL" "$cmd" "$UNIT"
      ;;
    unit|cat)
      "$SYSTEMCTL" cat "$UNIT" --no-pager
      ;;
    variants)
      variants
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
}

main "$@"
