{profile, host, lib, flakeRoot, ...}: let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") enableDesktop;
in {
  # Services to start
  services = {
    # Always enabled services
    openssh.enable = true; # Enable SSH

    # Only enable disk-related services on real hardware
    fstrim.enable = lib.mkIf (profile != "vm" && profile != "wsl") true; # SSD Optimizer

    smartd = {
      enable =
        if (profile == "vm" || profile == "wsl")
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

  # Disable orca screen reader (auto-enabled by GNOME services but not needed)
  systemd.user.services.orca.enable = lib.mkIf enableDesktop false;
}
