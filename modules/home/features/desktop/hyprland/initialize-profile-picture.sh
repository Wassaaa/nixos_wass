initialize_profile_picture() {
  local profile="$HOME/.face" alias

  if [ -d "$profile" ]; then
    echo "Cannot initialize profile picture: $profile is a directory." >&2
    return 1
  fi

  if [ ! -e "$profile" ] && [ ! -L "$profile" ]; then
    run cp -n -- "$1" "$profile"
  elif [ -L "$profile" ] && [ ! -e "$profile" ]; then
    echo "Profile picture is a dangling symlink: $profile" >&2
  fi

  run mkdir -p -- "$HOME/.config"
  for alias in "$HOME/.face.icon" "$HOME/.config/face.jpg"; do
    if [ ! -e "$alias" ] && [ ! -L "$alias" ]; then
      run ln -sT -- "$profile" "$alias"
    fi
  done
}

initialize_profile_picture "$@"
