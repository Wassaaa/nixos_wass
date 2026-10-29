{ inputs, pkgs, host, flakeRoot, ... }:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") windowsAppNativeWaylandOnNvidia;
in
{
  # Desktop-specific programs
  programs = {
    firefox.enable = false;
    dconf.enable = true;
    seahorse.enable = true;
  };

  # Desktop GUI applications
  environment.systemPackages = with pkgs; [
    (callPackage ./windows-app-for-linux.nix {
      windowsAppSrc = inputs.windows-app-for-linux-src;
      forceNativeWaylandOnNvidia = windowsAppNativeWaylandOnNvidia;
    })
    appimage-run
    audacity
    brightnessctl
    easyeffects
    file-roller # Archive manager GUI
    gedit # Text editor GUI
    gimp # Photo editor
    hyprpicker # Color picker
    eog # Image viewer
    inkscape
    libnotify
    lm_sensors
    lxqt.lxqt-policykit # Policy kit GUI
    nautilus # File manager (GNOME Files)
    pavucontrol # Audio control GUI
    picard # Music tagger GUI
    playerctl # Media control
    vesktop
    vlc
    ffmpegthumbnailer # Thumbnails
    ytmdl # YouTube downloader
  ];
}
