#!/usr/bin/env bash

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

run nvidia-smi
run cat /sys/module/nvidia_drm/parameters/modeset
run cat /sys/module/nvidia_drm/parameters/fbdev
run ls -l /run/opengl-driver/lib/gbm
run namei -l /run/opengl-driver/lib/gbm/dri_gbm.so
run ls -l /dev/dri

if (( failures > 0 )); then
  printf '\n%s command(s) failed; include their messages in the diagnostic output.\n' "$failures" >&2
  exit 1
fi
