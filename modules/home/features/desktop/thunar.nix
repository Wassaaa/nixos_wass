{ pkgs, ... }: {
  # Caelestia's GTK integration generates Thunar's CSS.
  # Thunar and Tumbler are installed through Home Manager packages because
  # programs.thunar/services.tumbler are NixOS module options, not HM options.
  home.packages = with pkgs; [
    xfce.thunar
    xfce.thunar-archive-plugin
    xfce.thunar-volman
    xfce.tumbler
    p7zip
  ];

  xdg.mimeApps.defaultApplications = {
    "inode/directory" = [ "thunar.desktop" ];
  };
}
