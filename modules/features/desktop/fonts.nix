{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      noto-fonts-emoji
      noto-fonts-cjk-sans
      font-awesome
      # symbola  # Temporarily disabled due to broken download URL
      material-icons
    ];
  };
}
