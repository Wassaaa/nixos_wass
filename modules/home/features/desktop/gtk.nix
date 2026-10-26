{ pkgs, ... }:
{
  # Caelestia owns the live GTK colour preference, CSS and icon-theme selection.
  home.packages = with pkgs; [
    adw-gtk3
    adwaita-icon-theme
    papirus-icon-theme
  ];
  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
  fonts.fontconfig.enable = true;
}
