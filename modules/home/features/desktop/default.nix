# Desktop Home Manager Features - GUI applications and desktop environment
{ inputs, ... }: {
  imports = [
    # Window manager and desktop environment
    ../../hyprland            # Hyprland window manager config
    ../../waybar.nix          # Status bar
    ../../rofi                # Application launcher
    ../../wlogout             # Logout menu
    ../../swaync.nix          # Notification daemon
    ../../clipboard.nix  # Clipboard history manager

    # Desktop applications
    ../../vscode.nix      # Code editor (GUI) - NixOS-managed
    ../../chrome.nix      # Web browser
    ../../virtmanager.nix # VM management GUI
    ../../1password.nix   # 1Password SSH agent integration (desktop)

    # Desktop theming and styling
    ../../gtk.nix        # GTK themes
    ../../qt.nix         # QT themes
    ../../xdg.nix        # XDG settings for desktop
    ../../stylix.nix     # System-wide theming
    ../../cava.nix       # Audio visualizer
    ../../kitty.nix      # Terminal emulator
    ../../ghostty.nix    # Alternative terminal

    # Desktop-specific scripts
    ../../scripts        # Includes wallpaper, screenshot, etc.

    # Theming
    ../../catppuccin.nix
    inputs.catppuccin.homeModules.catppuccin
  ];
}
