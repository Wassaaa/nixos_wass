#!/usr/bin/env bash

set -o pipefail

failures=0

run() {
  printf '\n$'
  printf ' %q' "$@"
  printf '\n'
  if "$@"; then
    return
  else
    status=$?
    printf 'Command failed with exit status %s\n' "$status" >&2
    failures=$((failures + 1))
  fi
}

check_file_readable() {
  head -c 1 "$1" > /dev/null && printf 'File is readable by the current user.\n'
}

windows_app_windows() {
  hyprctl clients -j | jq '[
    .[] | { pid, class, initialClass, mapped, hidden, workspace, monitor, at, size, floating, xwayland }
  ]'
}

windows_app_processes() {
  ps -u "$(id -u)" -o pid=,ppid=,comm=,args= | awk '
    /[w]indows-app-for-linux/ { print "pid=" $1, "ppid=" $2, "command=" $3; found = 1 }
    END { if (!found) print "No matching processes found." }
  '
}

run id
run nvidia-smi
run ls -l /sys/module/nvidia_drm/parameters/modeset /sys/module/nvidia_drm/parameters/fbdev
run sudo cat /sys/module/nvidia_drm/parameters/modeset
run sudo cat /sys/module/nvidia_drm/parameters/fbdev
run ls -l /run/opengl-driver/lib/gbm
run namei -l /run/opengl-driver/lib/gbm/dri_gbm.so
run check_file_readable /run/opengl-driver/lib/gbm/dri_gbm.so
run namei -l /run/opengl-driver/lib/gbm/nvidia-drm_gbm.so
run check_file_readable /run/opengl-driver/lib/gbm/nvidia-drm_gbm.so
run ls -l /dev/dri
run windows_app_processes
run windows_app_windows

if (( failures > 0 )); then
  printf '\n%s command(s) failed; include their messages in the diagnostic output.\n' "$failures" >&2
  exit 1
fi
