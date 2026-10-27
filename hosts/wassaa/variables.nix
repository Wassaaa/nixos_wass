{
  # Flake Directory
  flakeDir = "/home/wassaa/nixos_wass";

  # Git Configuration ( For Pulling Software Repos )
  gitUsername = "Allar Klein";
  gitEmail = "allarklein@gmail.com";
  gitSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFbC++MIhGE9FrwsgT6SJp01/a1E3bnhQzbzMSutCKhL";

  # Hyprland Settings
  # extraMonitorSettings = "
  # monitor=DP-3, 2560x1440@144, 0x0, 1
  # monitor=HDMI-A-1, 1920x1080@60, 2560x120, 1
  # ";

  # hyprctl monitors, the Monitor with LOWER ID, needs to have the lower set of workspaces for hyprsome to work
  monitors = [
    {
      # Left monitor: 2560x1440 @ 144 Hz
      name = "DP-2";
      enabled = true;
      width = 2560;
      height = 1440;
      refreshRate = 144;
      primary = true;
      x = 0;
      y = 0;
    }
    {
      # Right monitor: 1920x1080 @ 60 Hz
      name = "HDMI-A-1";
      enabled = true;
      width = 1920;
      height = 1080;
      refreshRate = 60;
      primary = false;
      x = 2560;
      y = 240;
    }
  ];

  # Program Options
  browser = "brave";
  terminal = "footclient";
  myshell = "fish"; # or zsh/bash
  keyboardLayout = "us,ee";
  consoleKeyMap = "us";

  # For Nvidia Prime support
  intelID = "PCI:1:0:0";
  nvidiaID = "PCI:0:2:0";

  # Enable Printing Support
  printEnable = false;

  # System Features
  enableGaming = true; # Steam, gamescope, etc.
  enableDesktop = true; # Full desktop environment
  enableAudio = true; # PipeWire audio
  enableBluetooth = false;
  enableSyncthing = false;
  enableVirtualization = true; # Docker, VMs, etc.
  enableDevelopment = true; # Dev tools, languages
  enableMultimedia = true; # Media codecs, players
}
