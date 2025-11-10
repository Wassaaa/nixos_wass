{ pkgs, ... }:
{
  imports = [
    ../../modules/core/nordvpn
  ];

  environment.systemPackages = with pkgs; [
    nodejs
    obs-studio
    (discord.override {
      # withOpenASAR = true;
      withVencord = true;
    })
    wgnord
  ];

  services.nordvpn = {
    enable = true;
    users = [ "wassaa" ];
  };
}
