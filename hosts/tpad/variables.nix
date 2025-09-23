{
  # Feature flags for modular system
  enableDesktop = true;
  enableGaming = false;
  enableDevelopment = true;
  enableVirtualization = false;
  enableMultimedia = true;

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
      workspace = [ "1" "2" "3" "4" "5" "6" "7" "8" "9" ];
    }
  ];

  # Waybar Settings
  clock24h = true;

  # Program Options
  browser = "google-chrome-stable"; # Set Default Browser (google-chrome-stable for google-chrome)
  terminal = "kitty"; # Set Default System Terminal
  keyboardLayout = "us";
  consoleKeyMap = "us";

  # Enable NFS
  enableNFS = true;

  # Enable Printing Support
  printEnable = false;
}
