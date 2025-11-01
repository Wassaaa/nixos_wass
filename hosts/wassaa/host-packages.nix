{ pkgs, ... }:
{
  services.solaar.enable = true;
  environment.systemPackages = with pkgs; [
    audacity
    nodejs
    obs-studio
    # (pkgs.makeDesktopItem {
    #   name = "discord";
    #   exec = "${pkgs.discord}/bin/discord";
    #   desktopName = "Discord";
    #   icon = "${pkgs.xfce.xfce4-icon-theme}/share/icons/apps/scalable/discord.svg";
    # })
    (discord.override {
      # withOpenASAR = true;
      withVencord = true;
    })
  ];
}
