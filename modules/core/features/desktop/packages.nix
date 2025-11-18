{ pkgs, ... }:
{
  # Desktop-specific programs
  programs = {
    firefox.enable = false;
    dconf.enable = true;
    seahorse.enable = true;
    adb.enable = true;
  };

  # Desktop GUI applications
  environment.systemPackages = with pkgs; [
    appimage-run
    brave # Browser
    brightnessctl
    file-roller # Archive manager GUI
    gedit # Text editor GUI
    gimp # Photo editor
    tuigreet # Display manager
    hyprpicker # Color picker
    eog # Image viewer
    libnotify
    lm_sensors
    lxqt.lxqt-policykit # Policy kit GUI
    mpv # Video player
    nautilus # File manager (GNOME Files)
    pavucontrol # Audio control GUI
    picard # Music tagger GUI
    playerctl # Media control
    ffmpegthumbnailer # Thumbnails
    ytmdl # YouTube downloader
  ];
}
