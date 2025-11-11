{ pkgs, inputs, ... }:
{
  # Enable niri compositor
  programs.niri = {
    enable = true;
    package = inputs.niri.packages.${pkgs.system}.niri;
  };

  # XDG desktop portal for niri (uses gnome backend for screencasting)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  # Niri will automatically create a session file, but we ensure it's visible to GDM
  environment.systemPackages = [ inputs.niri.packages.${pkgs.system}.niri ];
}
