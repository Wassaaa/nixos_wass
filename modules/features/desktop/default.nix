{ ... }:
{
  imports = [
    ./1password.nix

    # --- pick ONE display manager ---
    ./dm-greetd.nix
    # ./dm-gdm.nix          # GNOME’s GDM
    # ./dm-sddm.nix         # KDE’s SDDM

    # --- pick ONE desktop portal set (matches your session) ---
    ./portals-hyprland.nix
    # ./portals-gnome.nix
    # ./portals-kde.nix

    # --- desktops / compositors (pick any you actually use) ---
    ./de-hyprland.nix
    # ./de-gnome.nix
    # ./de-plasma-x11.nix    # Plasma (Xorg)

    # --- extras (optional) ---
    ./flatpak.nix
    ./boot-theme.nix
    ./stylix.nix
  ];
}
