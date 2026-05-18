#!/usr/bin/env bash
set -euo pipefail

CONFIG=${HERMES_FLEET_CONFIG:?HERMES_FLEET_CONFIG is not set}
HERMES=${HERMES_BIN:?HERMES_BIN is not set}
SELF=${HERMES_FLEET_SELF:-hermes-fleet}
SYSTEMCTL=${SYSTEMCTL:-/run/current-system/sw/bin/systemctl}
JOURNALCTL=${JOURNALCTL:-/run/current-system/sw/bin/journalctl}
SUDO=${SUDO:-/run/wrappers/bin/sudo}

if [[ -t 1 ]]; then
  bold=$'\033[1m'
  red=$'\033[31m'
  green=$'\033[32m'
  yellow=$'\033[33m'
  blue=$'\033[34m'
  reset=$'\033[0m'
else
  bold=""
  red=""
  green=""
  yellow=""
  blue=""
  reset=""
fi

usage() {
  cat <<'EOF'
Usage:
  hermes-fleet list
  hermes-fleet variants [gateway]
  hermes-fleet status [gateway]
  hermes-fleet apply <gateway> <variant>
  hermes-fleet start <gateway> <variant>
  hermes-fleet restart <gateway>
  hermes-fleet stop <gateway>
  hermes-fleet logs <gateway> [-n LINES]
  hermes-fleet cat-service <gateway>

Notes:
  apply      = set Discord toolsets for the gateway user; does not start service
  start      = apply toolset preset, reset failed state, then restart service
  restart    = restart an existing service without changing toolsets
  stop       = stop the gateway service
  status     = show service state; target-user Hermes details are shown only when sudo is available
  logs       = show recent journal lines for a gateway service
EOF
}

die() {
  printf '%sError:%s %s\n' "$red" "$reset" "$*" >&2
  exit 2
}

need_argc() {
  local expected="$1"
  local actual="$2"
  [[ "$actual" -eq "$expected" ]] || { usage >&2; exit 2; }
}

jq_get() {
  jq -r "$@" "$CONFIG"
}

all_gateways() {
  jq_get '.instances | keys | sort | .[]'
}

gateway_exists() {
  local gateway="$1"
  [[ "$(jq_get --arg gateway "$gateway" '.instances[$gateway] != null')" == "true" ]]
}

require_gateway() {
  local gateway="$1"
  gateway_exists "$gateway" || die "Unknown gateway '$gateway'. Available: $(all_gateways | tr '\n' ' ')"
}

gateway_user() {
  local gateway="$1"
  require_gateway "$gateway"
  jq_get --arg gateway "$gateway" '.instances[$gateway].user'
}

gateway_service() {
  local gateway="$1"
  require_gateway "$gateway"
  jq_get --arg gateway "$gateway" '.instances[$gateway].serviceName'
}

gateway_home() {
  local gateway="$1"
  require_gateway "$gateway"
  jq_get --arg gateway "$gateway" '.instances[$gateway].home'
}

variants_for() {
  local gateway="$1"
  require_gateway "$gateway"
  jq_get --arg gateway "$gateway" '.instances[$gateway].variants | keys | sort | .[]'
}

variant_exists() {
  local gateway="$1"
  local variant="$2"
  [[ "$(jq_get --arg gateway "$gateway" --arg variant "$variant" '.instances[$gateway].variants[$variant] != null')" == "true" ]]
}

require_variant() {
  local gateway="$1"
  local variant="$2"
  variant_exists "$gateway" "$variant" || die "Variant '$variant' is not defined for gateway '$gateway'. Available: $(variants_for "$gateway" | tr '\n' ' ')"
}

all_toolsets() {
  jq_get '.allToolsets[]'
}

preset_toolsets() {
  local gateway="$1"
  local variant="$2"
  require_variant "$gateway" "$variant"
  jq_get --arg gateway "$gateway" --arg variant "$variant" '.instances[$gateway].variants[$variant][]'
}

require_root_for() {
  local action="$1"
  if [[ "${EUID}" -ne 0 ]]; then
    printf '%sEscalating via sudo for:%s hermes-fleet %s\n' "$yellow" "$reset" "$action" >&2
    exec "$SUDO" "$SELF" "$@"
  fi
}

run_as_gateway_user() {
  local account="$1"
  shift
  "$SUDO" -u "$account" -H "$@"
}

run_as_gateway_user_no_prompt() {
  local account="$1"
  shift
  "$SUDO" -n -u "$account" -H "$@"
}

print_header() {
  printf '%s%s%s\n' "$bold$blue" "$*" "$reset"
}

cmd_list() {
  printf '%-10s %-14s %-26s %-20s %s\n' "Gateway" "User" "Service" "Home" "Variants"
  for gateway in $(all_gateways); do
    printf '%-10s %-14s %-26s %-20s %s\n' \
      "$gateway" \
      "$(gateway_user "$gateway")" \
      "$(gateway_service "$gateway")" \
      "$(gateway_home "$gateway")" \
      "$(variants_for "$gateway" | tr '\n' ' ')"
  done
}

cmd_variants() {
  if [[ $# -eq 0 ]]; then
    for gateway in $(all_gateways); do
      printf '%s: %s\n' "$gateway" "$(variants_for "$gateway" | tr '\n' ' ')"
    done
  else
    need_argc 1 "$#"
    printf '%s: %s\n' "$1" "$(variants_for "$1" | tr '\n' ' ')"
  fi
}

cmd_apply() {
  need_argc 2 "$#"
  local gateway="$1"
  local variant="$2"
  require_root_for apply "$gateway" "$variant"

  local account
  account="$(gateway_user "$gateway")"

  print_header "Applying '$variant' Discord toolset preset for $gateway ($account)"

  mapfile -t disable_toolsets < <(all_toolsets)
  mapfile -t enable_toolsets < <(preset_toolsets "$gateway" "$variant")

  run_as_gateway_user "$account" "$HERMES" tools disable --platform discord "${disable_toolsets[@]}" >/dev/null || true
  run_as_gateway_user "$account" "$HERMES" tools enable --platform discord "${enable_toolsets[@]}"
  printf 'Config path: '
  run_as_gateway_user "$account" "$HERMES" config path
}

service_state() {
  local service="$1"
  local active enabled failed
  active="$($SYSTEMCTL is-active "$service" 2>/dev/null || true)"
  enabled="$($SYSTEMCTL is-enabled "$service" 2>/dev/null || true)"
  failed="$($SYSTEMCTL is-failed "$service" 2>/dev/null || true)"
  printf 'active=%s enabled=%s failed=%s\n' "$active" "$enabled" "$failed"
}

cmd_status_one() {
  local gateway="$1"
  local account service
  account="$(gateway_user "$gateway")"
  service="$(gateway_service "$gateway")"

  print_header "== $gateway ($account / $service) =="
  service_state "$service"
  "$SYSTEMCTL" show "$service" \
    -p LoadState \
    -p ActiveState \
    -p SubState \
    -p UnitFileState \
    -p ExecMainStatus \
    --no-pager 2>/dev/null || true

  printf 'Hermes config: '
  if run_as_gateway_user_no_prompt "$account" "$HERMES" config path 2>/dev/null; then
    printf 'Discord toolsets:\n'
    run_as_gateway_user_no_prompt "$account" "$HERMES" tools list --platform discord 2>/dev/null | sed -n '1,80p' || true
  else
    printf '%sneeds sudo%s (run: sudo hermes-fleet status %s)\n' "$yellow" "$reset" "$gateway"
  fi
}

cmd_status() {
  if [[ $# -eq 0 ]]; then
    local first=1
    for gateway in $(all_gateways); do
      [[ "$first" -eq 1 ]] || printf '\n'
      cmd_status_one "$gateway"
      first=0
    done
  else
    need_argc 1 "$#"
    cmd_status_one "$1"
  fi
}

cmd_start() {
  need_argc 2 "$#"
  local gateway="$1"
  local variant="$2"
  require_root_for start "$gateway" "$variant"
  cmd_apply "$gateway" "$variant"
  local service
  service="$(gateway_service "$gateway")"
  "$SYSTEMCTL" reset-failed "$service" || true
  "$SYSTEMCTL" restart "$service"
  "$SYSTEMCTL" status "$service" --no-pager || true
}

cmd_restart() {
  need_argc 1 "$#"
  local gateway="$1"
  require_root_for restart "$gateway"
  local service
  service="$(gateway_service "$gateway")"
  print_header "Restarting $gateway ($service)"
  "$SYSTEMCTL" reset-failed "$service" || true
  "$SYSTEMCTL" restart "$service"
  "$SYSTEMCTL" status "$service" --no-pager || true
}

cmd_stop() {
  need_argc 1 "$#"
  local gateway="$1"
  require_root_for stop "$gateway"
  local service
  service="$(gateway_service "$gateway")"
  print_header "Stopping $gateway ($service)"
  "$SYSTEMCTL" stop "$service"
  "$SYSTEMCTL" status "$service" --no-pager || true
}

cmd_logs() {
  local lines=100
  local gateway=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--lines)
        [[ $# -ge 2 ]] || die "Missing value for $1"
        lines="$2"
        shift 2
        ;;
      *)
        [[ -z "$gateway" ]] || die "Unexpected argument '$1'"
        gateway="$1"
        shift
        ;;
    esac
  done
  [[ -n "$gateway" ]] || { usage >&2; exit 2; }
  local service
  service="$(gateway_service "$gateway")"
  "$JOURNALCTL" -u "$service" -n "$lines" --no-pager
}

cmd_cat_service() {
  need_argc 1 "$#"
  local service
  service="$(gateway_service "$1")"
  "$SYSTEMCTL" cat "$service" --no-pager
}

main() {
  if [[ $# -lt 1 ]]; then
    usage
    exit 2
  fi

  local cmd="$1"
  shift
  case "$cmd" in
    list) cmd_list "$@" ;;
    variants) cmd_variants "$@" ;;
    status) cmd_status "$@" ;;
    apply) cmd_apply "$@" ;;
    start) cmd_start "$@" ;;
    restart) cmd_restart "$@" ;;
    stop) cmd_stop "$@" ;;
    logs) cmd_logs "$@" ;;
    cat-service) cmd_cat_service "$@" ;;
    -h|--help|help) usage ;;
    *) usage >&2; exit 2 ;;
  esac
}

main "$@"
