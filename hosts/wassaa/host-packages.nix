{ pkgs, config, ... }:
{
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];

  environment.systemPackages = with pkgs; [
    obs-studio
    (discord.override {
      # withOpenASAR = true;
      withVencord = true;
    })
  ];

  services.nordvpn.enable = true;
  users.users.wassaa.extraGroups = [ "nordvpn" ];
  networking.firewall.checkReversePath = "loose";
  services.tailscale.enable = true;
}
