{profile, host, lib, flakeRoot, ...}: let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") enableDesktop;
in {
  # Services to start
  services = {
    # Always enabled services
    fstrim.enable = true; # SSD Optimizer
    openssh.enable = true; # Enable SSH
    
    smartd = {
      enable =
        if profile == "vm"
        then false
        else true;
      autodetect = true;
    };
  } // lib.optionalAttrs enableDesktop {
    # Desktop-only services
    libinput.enable = true; # Input Handling
    gvfs.enable = true; # For Mounting USB & More
    blueman.enable = true; # Bluetooth Support
    tumbler.enable = true; # Image/video preview
    gnome.gnome-keyring.enable = true;
    
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
