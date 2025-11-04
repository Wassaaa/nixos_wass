{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nodejs
    obs-studio
    (discord.override {
      # withOpenASAR = true;
      withVencord = true;
    })
  ];
}
