# Variables for laptop host - optimized for portable use
{
  # Git Configuration
  gitUsername = "Allar Klein";
  gitEmail = "allarklein@gmail.com";
  gitSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFbC++MIhGE9FrwsgT6SJp01/a1E3bnhQzbzMSutCKhL";


  # System Variables
  keyboardLayout = "us";
  consoleKeyMap = "us";

  # Program Options
  browser = "google-chrome-stable";
  terminal = "kitty";

  # Hyprland Settings (single monitor, laptop-optimized)
  monitors = [
    {
      name = "eDP-1";  # Typical laptop display name
      enabled = true;
      width = 1920;
      height = 1080;
      refreshRate = 60;
      primary = true;
      x = 0;
      y = 0;
      workspace = [ "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" ];
    }
  ];

  # Waybar Settings
  clock24h = true;

  # GPU Settings (adjust based on your laptop)
  intelID = "PCI:0:2:0";  # Adjust based on your hardware
  nvidiaID = "";          # Empty if no discrete GPU

  # Services
  enableNFS = false;      # Usually not needed on laptop
  printEnable = true;     # Might want printing on laptop

  # System Features - LAPTOP OPTIMIZED
  enableGaming = false;      # Disable Steam/gaming for better battery
  enableDesktop = true;      # Keep desktop environment
  enableVirtualization = false; # Disable for battery life
  enableDevelopment = true;  # Keep dev tools
  enableMultimedia = true;   # Media players for laptop use
}
