# Home Manager Feature-based module loader
{ host, lib, inputs, ... }: let
  inherit (import ../../hosts/${host}/variables.nix)
    enableGaming
    enableDesktop
    enableVirtualization
    enableDevelopment
    enableMultimedia;
in {
  imports = [
    # Always import core home modules (work everywhere)
    # These are minimal and work in any environment
    ./features/core

    # Conditionally import home feature modules
  ] ++ lib.optionals enableDesktop [
    ./features/desktop
  ] ++ lib.optionals enableDevelopment [
    ./features/development
  ] ++ lib.optionals enableMultimedia [
    ./features/multimedia
  ] ++ lib.optionals enableGaming [
    ./features/gaming
  ];
}
