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
    # Always import core system modules (minimal, work everywhere)
    ./boot.nix
    ./network.nix
    ./security.nix
    ./system.nix
    ./user.nix
    ./openssh.nix
    ./services.nix
    ./sops
    ./packages.nix  # Only core CLI utilities
    ./nh.nix        # NixOS helper - useful everywhere
    ./syncthing.nix # File syncing - useful everywhere
    ./starfish.nix  # Shell prompt - useful everywhere

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
