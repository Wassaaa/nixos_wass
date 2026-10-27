if ! cd -- "$1"; then
  notify-send -u critical "Unable to open terminal" "Cannot access the selected directory."
  exit 1
fi
if ! xdg-terminal-exec; then
  notify-send -u critical "Unable to open terminal" "The configured terminal could not be started."
  exit 1
fi
