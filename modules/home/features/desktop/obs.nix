{ pkgs, ... }:

{
  programs.obs-studio = {
    enable = false;
    plugins = with pkgs.obs-studio-plugins; [
      droidcam-obs
    ];
  };

  home.packages = with pkgs; [
    droidcam
  ];
}
