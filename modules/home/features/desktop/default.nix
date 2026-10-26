# Desktop shell and explicit application themes; no Stylix.
{ ... }: {
  imports = [
    ./hyprland
    ./quickshell.nix
    ./vicinae.nix
    ./utilities.nix
    ./foot.nix
    ./theme.nix
    ./gtk.nix
    ./qt.nix
    ./xdg.nix
    ./vscode.nix
    ./chrome.nix
    ./virtmanager.nix
    ./1password.nix
    ./qbittorrent.nix
    ./obs.nix
    ./transmission.nix
  ];
}
