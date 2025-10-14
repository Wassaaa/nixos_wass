{ ... }:
{
  imports = [
    ./1password.nix

    # --- pick ONE display manager ---
    # ./dm-greetd.nix
    ./dm-gdm.nix          # GNOME’s GDM



    # --- desktops / compositors (pick any you actually use) ---
    ./de-hyprland.nix
    ./de-gnome.nix

    # --- combined portals
    ./portals.nix

    # --- extras (optional) ---
    ./flatpak.nix
    ./boot-theme.nix
    ./stylix.nix
  ];
}
