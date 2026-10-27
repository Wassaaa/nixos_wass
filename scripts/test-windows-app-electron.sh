#!/usr/bin/env bash
set -euo pipefail

version="${1:-}"
case "$version" in
  42|43) ;;
  *)
    printf 'Usage: bash scripts/test-windows-app-electron.sh 42|43\n' >&2
    exit 2
    ;;
esac

cd "$(dirname "$0")/.."
expression="
  let
    flake = builtins.getFlake (toString ./.);
    pkgs = import flake.inputs.nixpkgs { system = \"x86_64-linux\"; };
  in
    flake.packages.x86_64-linux.windows-app-for-linux.override {
      electron = pkgs.electron_${version}-bin;
    }
"

printf 'Building Windows App with Electron %s; this may download dependencies.\n' "$version" >&2
app="$(nix build --impure --no-link --no-write-lock-file --print-out-paths --expr "$expression")"

test_dir="$(mktemp -d "${TMPDIR:-/tmp}/windows-app-electron-test.XXXXXXXX")"
mkdir -p "$test_dir/config" "$test_dir/cache" "$test_dir/data"
printf 'Temporary profile: %s\n' "$test_dir"
printf 'Do not sign in; close the app after checking whether its window appears.\n'

exec env \
  XDG_CONFIG_HOME="$test_dir/config" \
  XDG_CACHE_HOME="$test_dir/cache" \
  XDG_DATA_HOME="$test_dir/data" \
  "$app/bin/windows-app-for-linux"
