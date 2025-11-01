# Gaming Features
{ pkgs, config, ... }:
{
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true; # enables "Steam (Gamescope)" at login
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;
    args = [
      "--rt"
    ];
  };

  # Gaming-specific kernel modules
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];

  # Gaming packages
  environment.systemPackages = with pkgs; [
    # Game launchers and tools
    # lutris
    # heroic
    bottles

    wineWowPackages.staging
    winetricks

    # Performance monitoring
    mangohud
    goverlay

    vulkan-tools
    vulkan-loader
    vulkan-validation-layers

    (pkgs.writeShellScriptBin "steam-gamescope" ''
      #!/usr/bin/env bash
      # Run Steam in Gamescope (Deck-style session) with sane defaults
      exec dbus-run-session -- \
        env XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=gamescope MANGOHUD=1 \
        ${pkgs.gamescope}/bin/gamescope \
          -f -r 144 -W 2560 -H 1440 -- \
          ${pkgs.steam}/bin/steam
    '')
  ];

  environment.etc."xdg/wayland-sessions/steam-gamescope.desktop".text = ''
    [Desktop Entry]
    Name=Steam (Gamescope)
    Comment=Run Steam inside a Gamescope session (Steam Deck style)
    TryExec=steam-gamescope
    Exec=steam-gamescope
    Type=Application
  '';

}
