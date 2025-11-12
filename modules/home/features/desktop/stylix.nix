{
  host,
  lib,
  flakeRoot,
  ...
}:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") stylixEnable;
in
lib.mkIf stylixEnable {
  stylix.targets = {
    waybar.enable = false;
    rofi.enable = false;
    hyprland.enable = false;
    hyprlock.enable = false;
    ghostty.enable = false;
    vscode.enable = false;
    qt.enable = true;
  };
}
