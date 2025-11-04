{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    (pkgs.makeDesktopItem {
      name = "discord";
      exec = "${pkgs.discord}/bin/discord --use-gl=desktop --enable-gpu-rasterization  --enable-features=UseOzonePlatform --ozone-platform=wayland";
      desktopName = "Discord";
      icon = "${pkgs.xfce.xfce4-icon-theme}/share/icons/apps/scalable/discord.svg";
    })
    (discord.override { withOpenASAR = true; })
  ];
}
