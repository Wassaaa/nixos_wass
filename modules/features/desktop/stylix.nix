{ pkgs, lib, ... }:
{
  # Prefer qtct platform for Qt theming; avoids pulling qgnomeplatform
  stylix.targets.qt.platform = lib.mkForce "qtct";
  stylix.cursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
  };
  stylix.fonts.sizes = {
    desktop = 11;
    popups = 12;
  };
}
