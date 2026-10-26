{ pkgs, ... }: {
  # Caelestia's GTK integration generates Thunar's CSS; this owns the app and plugins.
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
    ];
  };

  services.tumbler.enable = true;

  home.packages = with pkgs; [
    xfce.thunar-archive-plugin
    p7zip
    unzip
  ];
}
