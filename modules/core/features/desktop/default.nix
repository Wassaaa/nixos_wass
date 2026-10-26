{ ... }: {
  imports = [
    ./security.nix
    ./packages.nix
    ./1password.nix
    ./dm-gdm.nix
    ./de-hyprland.nix
    ./de-niri.nix
    ./de-gnome.nix
    ./portals.nix
    ./flatpak.nix
    ./boot-theme.nix
    ./hardware.nix
    ./printing.nix
    ./nfs.nix
  ];
}
