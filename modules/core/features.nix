# Feature-based module loader
{ host, lib, ... }:
let
  inherit (import ../../hosts/${host}/variables.nix)
    enableGaming
    enableDesktop
    enableVirtualization
    enableDevelopment
    enableMultimedia
    ;
in
{
  imports = [
    # Always import core system modules
    ./boot.nix
    ./fonts.nix
    ./hardware.nix
    ./network.nix
    ./nfs.nix
    ./nh.nix
    ./packages.nix
    ./printing.nix
    ./security.nix
    ./services.nix
    ./starfish.nix
    ./stylix.nix
    ./syncthing.nix
    ./system.nix
    ./user.nix
    ./openssh.nix
    ./sops

    # Conditionally import feature modules
  ]
  ++ lib.optionals enableDesktop [
    ../features/desktop
  ]
  ++ lib.optionals enableGaming [
    ../features/gaming
  ]
  ++ lib.optionals enableDevelopment [
    ../features/development
  ]
  ++ lib.optionals enableVirtualization [
    ../features/virtualization
  ]
  ++ lib.optionals enableMultimedia [
    ../features/multimedia
  ];
}
