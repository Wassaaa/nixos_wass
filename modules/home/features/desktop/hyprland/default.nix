{ ... }:
{
  imports = [
    # ./binds.nix
    #./config.nix
    ./host-vars.nix
    ./monitors.nix
    ./hypridle.nix
    ./hyprland.nix
    ./hyprlock.nix
    ./pyprland.nix
  ];
}
