# Core styling - desktop-specific features moved to modules/features/desktop
{pkgs, host, lib, flakeRoot, ...}: let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") enableDesktop;
in {
  # Basic styling for desktop systems only
  stylix = lib.mkIf enableDesktop {
    enable = true;
    image = ../../wallpapers/zaney-wallpaper.jpg;
    base16Scheme = {
      base00 = "313244";
      base01 = "45475a";
      base02 = "585b70";
      base03 = "7f849c";
      base04 = "89dceb";
      base05 = "cdd6f4";
      base06 = "cdd6f4";
      base07 = "cdd6f4";
      base08 = "f38ba8";
      base09 = "f5c2e7";
      base0A = "a6e3a1";
      base0B = "f9e2af";
      base0C = "a1efe4";
      base0D = "62d6e8";
      base0E = "89b4fa";
      base0F = "a6e3a1";
    };
    polarity = "dark";
    opacity.terminal = 1.0;
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrains Mono";
      };
      sansSerif = {
        package = pkgs.montserrat;
        name = "Montserrat";
      };
      serif = {
        package = pkgs.montserrat;
        name = "Montserrat";
      };
      sizes = {
        applications = 12;
        terminal = 15;
        desktop = 11;
        popups = 12;
      };
    };
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };
    targets.qt.platform = "qtct";  # Prefer qtct platform for Qt theming
  };
}
