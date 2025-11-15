{
  host,
  lib,
  flakeRoot,
  ...
}:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") consoleKeyMap;
in
{
  nixpkgs.overlays = [
    (final: prev:
      let
        removeStylixDarkPatch = pkg:
          pkg.overrideAttrs (old: {
            patches =
              let
                existing = old.patches or [ ];
                keepPatch = patch:
                  let
                    patchStr = builtins.toString patch;
                  in
                  builtins.match ".*shell_remove_dark_mode.*" patchStr == null;
              in
              builtins.filter keepPatch existing;
          });

      in
      lib.optionalAttrs (prev ? gnome-shell) {
        gnome-shell = removeStylixDarkPatch prev.gnome-shell;
      })
  ];

  nix = {
    settings = {
      download-buffer-size = 250000000;
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
        "https://nixpkgs-unfree.cachix.org"
        "https://cuda-maintainers.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPiCmgKC/G8BHwlUfAmArcgZjCM+gO+d8="
      ];
      # Performance improvements
      max-jobs = "auto";
      cores = 0; # Use all available cores
      build-users-group = "nixbld";
      # Enable parallel downloads
      http-connections = 128;
      # Keep build outputs for faster rebuilds
      keep-outputs = true;
      keep-derivations = true;
    };
  };
  time.timeZone = "Europe/Helsinki";
  i18n.defaultLocale = "en_IE.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IE.UTF-8";
    LC_IDENTIFICATION = "en_IE.UTF-8";
    LC_MEASUREMENT = "en_IE.UTF-8";
    LC_MONETARY = "en_IE.UTF-8";
    LC_NAME = "en_IE.UTF-8";
    LC_NUMERIC = "en_IE.UTF-8";
    LC_PAPER = "en_IE.UTF-8";
    LC_TELEPHONE = "en_IE.UTF-8";
    LC_TIME = "en_IE.UTF-8";
  };
  console.keyMap = "${consoleKeyMap}";

  # Disable slow man-db cache generation on rebuilds
  documentation = {
    enable = true;
    man.enable = true;
    man.generateCaches = false;  # This is what makes rebuilds slow
  };

  system.stateVersion = lib.mkDefault "25.05"; # Do not change!
}
