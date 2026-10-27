{ pkgs, config, flakeRoot, ... }:
{
  imports = [
    "${flakeRoot}/modules/core/nordvpn"
  ];

  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];

  environment.systemPackages = with pkgs; [
    obs-studio
    (discord.override {
      # withOpenASAR = true;
      withVencord = true;
    })
  ];

  services.nordvpn = {
    enable = true;
    enableGui = true;
    users = [ "wassaa" ];
  };

  services.tailscale.enable = true;
}
