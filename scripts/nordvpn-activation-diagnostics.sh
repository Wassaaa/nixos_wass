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
echo "== Recent NordVPN service logs from this boot =="
journalctl --boot --unit=nordvpnd.service --lines=160 --no-pager --output=short-iso
