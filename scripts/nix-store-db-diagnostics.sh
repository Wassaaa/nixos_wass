#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run this script with sudo to inspect database metadata and kernel logs." >&2
  exit 1
fi

echo "== Nix filesystem =="
findmnt --target /nix --output TARGET,SOURCE,FSTYPE,OPTIONS
df -h /nix
df -i /nix

echo
echo "== Nix database file metadata =="
for path in /nix/var/nix/db/db.sqlite /nix/var/nix/db/db.sqlite-wal \
  /nix/var/nix/db/db.sqlite-shm /nix/var/nix/db/db.sqlite-journal; do
  if [[ -e "$path" ]]; then
    stat --printf='%n: size=%s bytes mode=%a owner=%U:%G modified=%y\n' "$path"
  else
    printf '%s: absent\n' "$path"
  fi
done

echo
echo "== Nix daemon state =="
systemctl show nix-daemon.service nix-daemon.socket \
  --property=Id --property=LoadState --property=ActiveState --property=SubState

echo
echo "== Recent kernel errors from this boot (up to 100) =="
journalctl --dmesg --boot --priority=err --lines=100 --no-pager
