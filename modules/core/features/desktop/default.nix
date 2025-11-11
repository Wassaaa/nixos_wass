{ ... }:
{
  imports = [
    ./packages.nix
    ./1password.nix

    # --- pick ONE display manager ---
    # ./dm-greetd.nix
    ./dm-gdm.nix # GNOME's GDM

    # --- desktops / compositors (pick any you actually use) ---
    ./de-hyprland.nix
    ./de-niri.nix
    ./de-gnome.nix

    # --- combined portals
    ./portals.nix

    # --- extras (optional) ---
    ./flatpak.nix
    ./boot-theme.nix
    ./stylix.nix
    ./hardware.nix
    ./stylix.nix
    ./printing.nix
    ./nfs.nix
  ];
}
