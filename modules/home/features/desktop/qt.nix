# Caelestia's Qt integration owns its qtengine configuration and palette.
# Keep only the runtime pieces it expects; do not force another Qt platform theme.
{ pkgs, ... }: {
  home.packages = with pkgs; [
    kdePackages.breeze kdePackages.kconfig kdePackages.kcolorscheme
  ];
}
