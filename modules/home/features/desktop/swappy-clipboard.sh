if ! output=$(mktemp); then
  notify-send -u critical "Screenshot failed" "Could not create a temporary output file."
  exit 1
fi
trap 'rm -f -- "$output"' EXIT

if ! swappy -o - "$@" > "$output"; then
  notify-send -u critical "Screenshot failed" "Swappy could not edit the screenshot."
  exit 1
fi
if [ ! -s "$output" ]; then
  notify-send -u critical "Screenshot not copied" "Swappy did not produce an image."
  exit 1
fi
if ! wl-copy --type image/png < "$output"; then
  notify-send -u critical "Screenshot not copied" "Could not copy the edited image to the clipboard."
  exit 1
fi
