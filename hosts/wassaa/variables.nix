{
  # Git Configuration ( For Pulling Software Repos )
  gitUsername = "Allar Klein";
  gitEmail = "allarklein@gmail.com";

  # Hyprland Settings
  # extraMonitorSettings = "
  # monitor=DP-3, 2560x1440@144, 0x0, 1
  # monitor=HDMI-A-1, 1920x1080@60, 2560x120, 1
  # ";

  # hyprctl monitors, the Monitor with LOWER ID, needs to have the lower set of workspaces for hyprsome to work
  monitors = [
    {
      name = "DP-3";
      enabled = true;
      width = 2560;
      height = 1440;
      refreshRate = 144;
      primary = true;
      x = 0;
      y = 0;
      workspace = [ "11" "12" "13" "14" "15" "16" "17" "18" "19" ];
    }
    {
      name = "HDMI-A-1";
      enabled = true;
      width = 1920;
      height = 1080;
      refreshRate = 60;
      primary = false;
      x = 2560;
      y = 120;
      workspace = [ "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" ];
    }
  ];

  # Waybar Settings
  clock24h = true;

  # Program Options
  browser = "google-chrome-stable"; # Set Default Browser (google-chrome-stable for google-chrome)
  terminal = "kitty"; # Set Default System Terminal
  keyboardLayout = "us";
  consoleKeyMap = "us";

  # For Nvidia Prime support
  intelID = "PCI:1:0:0";
  nvidiaID = "PCI:0:2:0";

  # Enable NFS
  enableNFS = true;

  # Enable Printing Support
  printEnable = false;
}
