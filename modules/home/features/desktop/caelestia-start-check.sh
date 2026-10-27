if ! instances=$(caelestia-shell list -j); then
  printf '%s\n' "Caelestia could not check for existing shell instances." >&2
  notify-send -u critical "Caelestia could not start" "Could not check for existing shell instances." \
    || printf '%s\n' "Could not send the Caelestia startup notification." >&2
  exit 255
fi

case "$instances" in
  "No running instances"*) exit 0 ;;
esac

if ! count=$(printf '%s' "$instances" | jq -er 'if type == "array" then length else error("invalid instance list") end'); then
  printf '%s\n' "Caelestia returned an invalid shell instance list." >&2
  notify-send -u critical "Caelestia could not start" "The shell instance list was invalid." \
    || printf '%s\n' "Could not send the Caelestia startup notification." >&2
  exit 255
fi

if [ "$count" -gt 0 ]; then
  printf '%s\n' "An existing Caelestia shell is running; start a fresh Hyprland session." >&2
  notify-send "Caelestia" "An existing shell is running. Start a fresh Hyprland session to use the service." \
    || printf '%s\n' "Could not send the Caelestia startup notification." >&2
  exit 1
fi
