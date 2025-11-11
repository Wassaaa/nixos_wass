{ pkgs, ... }:
{
  # Keep niri available at system level for GDM to detect it
  programs.niri.package = pkgs.niri;

  # Ensure niri session is available to display manager
  services.displayManager.sessionPackages = [ pkgs.niri ];
}
