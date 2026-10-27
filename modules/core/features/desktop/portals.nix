{ pkgs, ... }:
{
  xdg.portal = {
    enable = true;

    # Backends to provide:
    # - The Hyprland module supplies its portal
    # - GNOME portal for GNOME sessions
    # - GTK portal as fallback for OpenURI and other interfaces
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];

    # Don't force xdg-open through portal - let it use fallback if needed
    xdgOpenUsePortal = false;

    # Explicit portal configuration for each desktop environment
    config = {
      common = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
      hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
      gnome = {
        default = [ "gnome" ];
      };
    };
  };
}
