{pkgs}:

pkgs.writeShellScriptBin "hyprsomescroll" ''
    #!/usr/bin/env bash

    # Check if an argument is passed
    if [ -z "$1" ]; then
      echo "Usage: $0 <1|-1>"
      exit 1
    fi

    # Ensure the argument is either 1 or -1
    if [ "$1" -ne 1 ] && [ "$1" -ne -1 ]; then
      echo "Argument must be 1 or -1"
      exit 1
    fi

    # Get the active workspace number
    ACTIVE_WORKSPACE=$(hyprctl monitors | grep -C 5 "focused: yes" | grep active | awk '{print $3}')
    echo "Current workspace: $ACTIVE_WORKSPACE"

    # Calculate the next workspace
    NEXT_WORKSPACE=$(expr $ACTIVE_WORKSPACE + $1)

    # Handle looping cases
    if ((NEXT_WORKSPACE == 10)); then
      if [ "$1" -eq -1 ]; then
        NEXT_WORKSPACE=19 # Decrementing mode: wrap 10 to 19
      else
        NEXT_WORKSPACE=1  # Incrementing mode: wrap 10 to 1
      fi
    elif ((NEXT_WORKSPACE == 0)); then
      NEXT_WORKSPACE=9    # Wrap 0 to 9 when decrementing
    elif ((NEXT_WORKSPACE == 20)); then
      NEXT_WORKSPACE=11   # Wrap 20 to 11 when incrementing
    fi

    echo "Switching to workspace: $NEXT_WORKSPACE"

    # Dispatch the command to switch to the next workspace
    hyprctl dispatch workspace $NEXT_WORKSPACE
  ''
