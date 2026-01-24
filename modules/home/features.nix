# Home Manager Feature-based module loader
{
  host,
  lib,
  flakeRoot,
  ...
}:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix")
    enableGaming
    enableDesktop
    enableDevelopment
    enableMultimedia
    ;

  # Check if host has host-specific home configs
  hostHomeDir = "${flakeRoot}/hosts/${host}/home";
  hasHostHome = builtins.pathExists hostHomeDir;
in
{
  imports = [
    # Always import core home modules (work everywhere)
    # These are minimal and work in any environment
    ./features/core

    # Conditionally import home feature modules
  ]
  ++ lib.optionals enableDesktop [
    ./features/desktop
  ]
  ++ lib.optionals enableDevelopment [
    ./features/development
  ]
  ++ lib.optionals enableMultimedia [
    ./features/multimedia
  ]
  ++ lib.optionals enableGaming [
    ./features/gaming
  ]
  ++ lib.optionals hasHostHome [
    ../../hosts/${host}/home
  ];
}
