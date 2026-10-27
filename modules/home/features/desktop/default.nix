# Caelestia owns the desktop shell and theme integrations.
# Hyprland remains configured through live-editable Lua in ./hyprland/config.
{ ... }:
{
  imports = [
    ./hyprland
    ./caelestia.nix
    ./vicinae.nix
    ./utilities.nix
    ./foot.nix
    ./thunar.nix
    ./mpv.nix
    ./brave.nix
    ./gtk.nix
    ./xdg.nix
    ./vscode.nix
    ./chrome.nix
    ./virtmanager.nix
    ./1password.nix
    ./qbittorrent.nix
  ];
}
