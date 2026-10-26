{ ... }: {
  imports = [
    ./host-vars.nix
    ./monitors.nix
    ./hypridle.nix
    ./hyprland.nix
    ./hyprlock.nix
  ];
}
