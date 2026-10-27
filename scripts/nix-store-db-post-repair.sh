#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -eq 0 ]]; then
  echo "Run without sudo; the script uses sudo only for the database snapshot." >&2
  exit 1
fi

uv_path=$(command -v uv) || {
  echo "uv was not found on PATH." >&2
  exit 1
}
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

echo "== Nix daemon store query =="
NIX_REMOTE=daemon nix path-info /run/current-system

echo
echo "== Fresh database snapshot and integrity check =="
sudo "$uv_path" run "$script_dir/nix-store-db-snapshot.py"
