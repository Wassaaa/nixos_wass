{
  # Flake Directory
  flakeDir = "/home/allar/nixos_wass";

  # Feature flags for modular system
  enableDesktop = true;
  enableAudio = true;
  enableBluetooth = true;
  enableSyncthing = false;
  enableGaming = false;
  enableDevelopment = true;
  enableVirtualization = true;
  enableMultimedia = true;
  enableMediaRouting = false;

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
      name = "eDP-1";
      enabled = true;
      width = 1920;
      height = 1080;
      refreshRate = 60;
      primary = true;
      x = 0;
      y = 0;
      workspace = [
        "1"
        "2"
        "3"
        "4"
        "5"
        "6"
        "7"
        "8"
        "9"
      ];
    }
  ];

  # Program Options
  browser = "brave";
  windowsAppNativeWaylandOnNvidia = false;
  terminal = "footclient";
  myshell = "fish"; # or zsh/bash
  keyboardLayout = "us,ee";
  consoleKeyMap = "us";

  # Enable Printing Support
  printEnable = false;
}
