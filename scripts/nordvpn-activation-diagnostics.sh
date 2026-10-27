#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run with sudo to inspect the system journal." >&2
  exit 1
fi

echo "== NordVPN service state =="
systemctl show nordvpnd.service \
  --property=Id --property=LoadState --property=ActiveState --property=SubState \
  --property=Result --property=ExecMainCode --property=ExecMainStatus \
  --property=NRestarts --property=ExecMainStartTimestamp --property=ExecMainExitTimestamp

echo
echo "== NordVPN state file metadata (no contents) =="
for path in /var/lib/nordvpn/data /var/lib/nordvpn/data/settings.dat \
  /var/lib/nordvpn/data/install.dat; do
  if [[ -e "$path" || -L "$path" ]]; then
    stat --printf='%n: type=%F size=%s mode=%a owner=%U:%G modified=%y\n' "$path"
  else
    printf '%s: absent\n' "$path"
  fi
done

echo
echo "== Recent NordVPN service logs from this boot =="
journalctl --boot --unit=nordvpnd.service --lines=160 --no-pager --output=short-iso
