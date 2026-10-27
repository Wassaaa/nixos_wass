# Feature-based module loader
{
  host,
  lib,
  flakeRoot,
  ...
}:
let
  hostVars = import "${flakeRoot}/hosts/${host}/variables.nix";
  inherit (hostVars)
    enableGaming
    enableDesktop
    enableAudio
    enableSyncthing
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
    ./system.nix
    ./user.nix
    ./openssh.nix
    ./services.nix
    ./sops
    ./packages.nix # Only core CLI utilities
    ./nh.nix # NixOS helper - useful everywhere
    ./starfish.nix # Shell prompt - useful everywhere

    # Conditionally import feature modules
  ]
  ++ lib.optionals enableDesktop [
    ./features/desktop
  ]
  ++ lib.optionals enableAudio [
    ./features/audio
  ]
  ++ lib.optionals enableSyncthing [
    ./syncthing.nix
  ]
  ++ lib.optionals enableGaming [
    ./features/gaming
  ]
  ++ lib.optionals enableDevelopment [
    ./features/development
  ]
  ++ lib.optionals enableVirtualization [
    ./features/virtualization
  ]
  ++ lib.optionals enableMultimedia [
    ./features/multimedia
  ];
}
