hyprpicker -r -z &
picker_pid=$!
cleanup() {
  if kill -0 "$picker_pid" 2>/dev/null; then
    kill "$picker_pid"
  fi
  wait "$picker_pid" 2>/dev/null || :
}
trap cleanup EXIT

sleep 0.2
if ! kill -0 "$picker_pid" 2>/dev/null; then
  notify-send -u critical "Screenshot failed" "Could not freeze the screen."
  exit 1
fi

if ! region=$(slurp); then
  notify-send "Screenshot" "Selection cancelled or unavailable."
  exit 0
fi

directory="${XDG_SCREENSHOTS_DIR:-${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots}"
mkdir -p -- "$directory"
file=$(mktemp --tmpdir="$directory" "Screenshot-$(date +%Y%m%d-%H%M%S)-XXXXXX.png")
if ! grim -g "$region" "$file"; then
  rm -- "$file"
  notify-send -u critical "Screenshot failed" "Could not capture the selected area."
  exit 1
fi
if ! wl-copy --type image/png < "$file"; then
  notify-send -u critical "Screenshot saved, but not copied" "$file"
  exit 1
fi
notify-send "Screenshot saved and copied" "$file" -i "$file"
