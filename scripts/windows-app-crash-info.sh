#!/usr/bin/env bash
set -euo pipefail

printf 'Recent Electron coredumps:\n'
if ! coredumpctl --no-pager --reverse -n 8 list electron; then
  printf 'No accessible Electron coredump list; include the error above.\n' >&2
  exit 1
fi

printf '\nMost recent Electron crash details:\n'
printf 'Review command lines and other details for sensitive data before sharing.\n'
coredumpctl --no-pager -1 info electron
