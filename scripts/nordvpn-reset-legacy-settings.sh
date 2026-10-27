#!/usr/bin/env bash
set -euo pipefail
umask 077

if [[ ${EUID} -ne 0 ]]; then
  echo "Run with sudo." >&2
  exit 1
fi

data=/var/lib/nordvpn/data
settings=$data/settings.dat
install=$data/install.dat
backup=

on_exit() {
  local status=$?
  if (( status != 0 )); then
    echo "Recovery did not complete; inspect the service and any backup before retrying." >&2
    if [[ -n $backup ]]; then
      echo "Backup directory: $backup" >&2
    fi
  fi
}
trap on_exit EXIT

if [[ ! -d $data || -L $data || ! -f $settings || -L $settings || ! -f $install || -L $install ]]; then
  echo "Expected a real NordVPN data directory and regular settings.dat and install.dat files." >&2
  exit 1
fi
if [[ $(stat --format='%U:%G' "$data") != nordvpn:nordvpn ]]; then
  echo "Unexpected NordVPN data directory ownership; no changes made." >&2
  exit 1
fi

echo "Stopping the NordVPN service and socket."
systemctl stop nordvpnd.socket nordvpnd.service
for unit in nordvpnd.socket nordvpnd.service; do
  if [[ $(systemctl show "$unit" --property=ActiveState --value) != inactive ]]; then
    echo "$unit did not stop; refusing to change the state files." >&2
    exit 1
  fi
done

backup=$(mktemp -d /root/nordvpn-recovery.XXXXXXXX)
echo "Private backup: $backup"
stat --printf='%n: mode=%a owner=%U:%G\n' "$data" > "$backup/data-directory-metadata.txt"
cp --archive -- "$settings" "$install" "$backup/"

echo "Enabling the service user to write its data directory."
chmod 0750 -- "$data"
echo "Moving the legacy settings aside."
mv -- "$settings" "$backup/settings.original.dat"

echo "Starting the NordVPN service and socket."
systemctl start nordvpnd.socket nordvpnd.service
sleep 3
if ! systemctl is-active --quiet nordvpnd.service; then
  echo "NordVPN is not active; inspect its journal and retain the backup." >&2
  if ! systemctl --no-pager --full status nordvpnd.service; then
    echo "The service status also reports a failure." >&2
  fi
  exit 1
fi

echo "NordVPN is active. Check login, VPN connectivity, and kill-switch settings."
echo "Retain the private backup until the new configuration is confirmed."
