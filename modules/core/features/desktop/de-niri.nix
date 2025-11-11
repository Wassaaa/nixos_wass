{ pkgs, ... }:
{
  # Enable niri compositor from nixpkgs
  programs.niri.enable = true;

  # XDG desktop portal for niri (uses gnome backend for screencasting)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };
}
