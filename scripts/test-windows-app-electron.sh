#!/usr/bin/env bash
set -euo pipefail

version="${1:-}"
backend="${2:-default}"
sandbox="${3:-sandboxed}"
platform="${4:-as-packaged}"
usage='Usage: bash scripts/test-windows-app-electron.sh 42|43 [default|nvidia-gbm] [sandboxed|gpu-unsandboxed] [as-packaged|native-wayland]'
case "$version" in
  42|43) ;;
  *)
    printf '%s\n' "$usage" >&2
    exit 2
    ;;
esac
case "$backend" in
  default) extra_env=() ;;
  nvidia-gbm) extra_env=("GBM_BACKEND=nvidia-drm") ;;
  *)
    printf '%s\n' "$usage" >&2
    exit 2
    ;;
esac
case "$sandbox" in
  sandboxed) extra_flags=() ;;
  gpu-unsandboxed) extra_flags=("--disable-gpu-sandbox") ;;
  *)
    printf '%s\n' "$usage" >&2
    exit 2
    ;;
esac
case "$platform" in
  as-packaged) patch_expr="" ;;
  native-wayland)
    patch_expr="$(cat <<'NIX'
      .overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace app/index.js \
            --replace-fail "app.commandLine.appendSwitch('ozone-platform', 'x11');" \
              "app.commandLine.appendSwitch('ozone-platform', 'wayland');"
        '';
      })
NIX
)"
    ;;
  *)
    printf '%s\n' "$usage" >&2
    exit 2
    ;;
esac

cd "$(dirname "$0")/.."
expression="
  let
    flake = builtins.getFlake (toString ./.);
    pkgs = import flake.inputs.nixpkgs { system = \"x86_64-linux\"; };
  in
    (flake.packages.x86_64-linux.windows-app-for-linux.override {
      electron = pkgs.electron_${version}-bin;
    })${patch_expr}
"

printf 'Building Windows App with Electron %s; this may download dependencies.\n' "$version" >&2
app="$(nix build --impure --no-link --no-write-lock-file --print-out-paths --expr "$expression")"

test_dir="$(mktemp -d "${TMPDIR:-/tmp}/windows-app-electron-test.XXXXXXXX")"
mkdir -p "$test_dir/config" "$test_dir/cache" "$test_dir/data"
printf 'Temporary profile: %s\n' "$test_dir"
printf 'GBM backend: %s\n' "$backend"
printf 'GPU sandbox: %s\n' "$sandbox"
printf 'Platform: %s\n' "$platform"
printf 'Do not sign in; close the app after checking whether its window appears.\n'

exec env \
  XDG_CONFIG_HOME="$test_dir/config" \
  XDG_CACHE_HOME="$test_dir/cache" \
  XDG_DATA_HOME="$test_dir/data" \
  "${extra_env[@]}" \
  "$app/bin/windows-app-for-linux" "${extra_flags[@]}"
