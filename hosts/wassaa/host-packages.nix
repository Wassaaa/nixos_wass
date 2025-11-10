{ pkgs, flakeRoot, ... }:
{
  imports = [
    "${flakeRoot}/modules/core/nordvpn"
  ];

  environment.systemPackages = with pkgs; [
    nodejs
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
}
