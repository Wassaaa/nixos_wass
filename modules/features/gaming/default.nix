# Gaming Features
{ pkgs, config, ... }: {
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
    gamescopeSession.enable = true;
    extraCompatPackages = [pkgs.proton-ge-bin];
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;
    args = [
      "--rt"
      "--expose-wayland"
    ];
  };

  # Gaming-specific kernel modules
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];

  # Performance optimizations for gaming
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642;
  };

  # Gaming packages
  environment.systemPackages = with pkgs; [
    # Game launchers and tools
    lutris
    heroic
    bottles

    # Performance monitoring
    mangohud
    goverlay

    # Game development
    godot_4
    blender
  ];
}
