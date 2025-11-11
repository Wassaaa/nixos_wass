# Desktop Home Manager Features - GUI applications and desktop environment
{ inputs, host, lib, flakeRoot, ... }:
let
  variables = import "${flakeRoot}/hosts/${host}/variables.nix";
  inherit (variables) waybarChoice;
  
  barChoice = variables.barChoice or "waybar";
in
{
  imports = [
    # Window manager and desktop environment
    ./hyprland # Hyprland window manager config
    ./niri # Alternative: Niri scrollable-tiling compositor
    ./rofi # Application launcher
    ./wlogout # Logout menu
    ./clipboard.nix # Clipboard history manager

    # Desktop applications
    ./vscode.nix # Code editor (GUI) - NixOS-managed
    ./chrome.nix # Web browser
    ./virtmanager.nix # VM management GUI
    ./1password.nix # 1Password SSH agent integration (desktop)
    ./qbittorrent.nix # Torrent client (GUI)
    ./obs.nix # OBS Studio
    ./transmission.nix # Alternative torrent client

    # Desktop theming and styling
    ./gtk.nix # GTK themes
    ./qt.nix # QT themes
    ./xdg.nix # XDG settings for desktop
    ./stylix.nix # System-wide theming
    ./cava.nix # Audio visualizer

    # Desktop-specific scripts
    ./scripts # Includes wallpaper, screenshot, etc.

    # Theming
    ./catppuccin.nix
    inputs.catppuccin.homeModules.catppuccin
  ]
  
  # Bar/Shell - conditional import based on barChoice
  ++ lib.optionals (barChoice == "noctalia") [
    ./noctalia-shell
  ]
  ++ lib.optionals (barChoice == "waybar") [
    waybarChoice
    ./swaync.nix # Notifications only work with waybar
  ];
}
