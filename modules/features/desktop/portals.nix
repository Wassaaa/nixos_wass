{ pkgs, ... }:
{
  xdg.portal = {
    enable = true;

    wlr.enable = true;

    # Backends to provide:
    # - GNOME portal for GNOME sessions
    # - GTK portal as a general fallback on both GNOME and wlroots
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];

    # Helps route xdg-open through the portal (good for Flatpak/sandboxed apps)
    xdgOpenUsePortal = true;

    # Let Hyprland ship its session-specific portal config (harmless on GNOME)
    configPackages = [ pkgs.hyprland ];
  };
}
