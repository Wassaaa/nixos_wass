{ pkgs, lib, ... }:

{
  # Install VS Code Insiders via Flatpak for user-managed updates
  # This configuration sets up the necessary environment and flags for Wayland/Nvidia

  # Ensure Flatpak is available
  home.packages = with pkgs; [
    # Flatpak utilities
    xdg-desktop-portal
    xdg-desktop-portal-gtk
  ];

  # Provide a base settings fragment (same as before)
  xdg.configFile."Code/User/settings.base.json" = {
    source = ./vscode.settings.base.json;
  };

  # VS Code Settings Sync is recommended for managing extensions and settings
  # After first launch:
  # 1. Sign in with GitHub/Microsoft account
  # 2. Enable Settings Sync (Ctrl+Shift+P -> "Settings Sync: Turn On")
  # 3. Select what to sync (Settings, Keybindings, Extensions, UI State, etc.)
  # Your extensions and settings will automatically sync across all machines!

  # Create a wrapper script that handles the GPU flags
  home.file.".local/bin/code" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Wrapper for VS Code with Wayland/Nvidia flags

      # Check if Flatpak version exists (Insiders or Stable)
      if command -v flatpak &> /dev/null; then
        if flatpak list --app | grep -q "com.visualstudio.code.insiders"; then
          exec flatpak run --command=code-insiders com.visualstudio.code.insiders \
            --disable-gpu-compositing \
            "$@"
        elif flatpak list --app | grep -q "com.visualstudio.code"; then
          exec flatpak run com.visualstudio.code \
            --disable-gpu-compositing \
            "$@"
        fi
      fi

      # Fallback to system code if no Flatpak version found
      if command -v code-insiders &> /dev/null; then
        exec code-insiders --disable-gpu-compositing "$@"
      elif command -v code &> /dev/null; then
        exec code --disable-gpu-compositing "$@"
      else
        echo "VS Code not found. Please install via Flatpak:"
        echo "  flatpak install flathub com.visualstudio.code.insiders"
        echo "  or"
        echo "  flatpak install flathub com.visualstudio.code"
        exit 1
      fi
    '';
  };

  # Merge base settings with user settings on activation
  home.activation.mergeVscodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -eu
    CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
    SETTINGS_DIR="$CONFIG_HOME/Code/User"
    BASE="$SETTINGS_DIR/settings.base.json"
    USER_SETTINGS="$SETTINGS_DIR/settings.json"
    TMP="$SETTINGS_DIR/.settings.json.hm-merge"

    mkdir -p "$SETTINGS_DIR"
    if [ -f "$BASE" ]; then
      if [ -f "$USER_SETTINGS" ]; then
        ${pkgs.jq}/bin/jq -s 'add' "$BASE" "$USER_SETTINGS" > "$TMP" && mv "$TMP" "$USER_SETTINGS"
      else
        cp "$BASE" "$USER_SETTINGS"
      fi
    fi
  '';

  # Optional: Set environment variables for Wayland/Nvidia
  home.sessionVariables = {
    # These help with Electron apps on Wayland
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };
}
