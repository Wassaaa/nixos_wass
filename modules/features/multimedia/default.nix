# Multimedia Features
{ pkgs, ... }: {
  # Audio support
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Video and graphics
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Multimedia packages
  environment.systemPackages = with pkgs; [
    # Media players
    vlc
    mpv
    
    # Audio tools
    pavucontrol
    easyeffects
    audacity
    
    # Video editing
    kdenlive
    obs-studio
    
    # Image editing
    gimp
    inkscape
    
    # Media codecs and formats
    ffmpeg
    gstreamer
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    
    # Screen capture
    grim
    slurp
    wl-clipboard
  ];

  # Font configuration for multimedia
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
  ];
}