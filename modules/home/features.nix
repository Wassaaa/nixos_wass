# Home Manager Feature-based module loader
{
  host,
  lib,
  flakeRoot,
  ...
}:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix")
    enableDesktop
    enableDevelopment
    enableMultimedia
    enableMediaRouting
    ;

  # Check if host has host-specific home configs
  hostHomeDir = "${flakeRoot}/hosts/${host}/home";
  hasHostHome = builtins.pathExists "${hostHomeDir}/default.nix";
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
  ++ lib.optionals (enableDesktop && enableMultimedia && enableMediaRouting) [
    ./features/multimedia/qpwgraph.nix
  ]
  ++ lib.optionals hasHostHome [
    ../../hosts/${host}/home
  ];
}
