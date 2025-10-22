# Variables for WSL host
{
  # Flake Directory
  flakeDir = "/home/wsl/nixos_wass";

  # Git Configuration
  gitUsername = "Allar Klein";
  gitEmail = "allarklein@gmail.com";
  gitSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFbC++MIhGE9FrwsgT6SJp01/a1E3bnhQzbzMSutCKhL";

  # System Variables
  keyboardLayout = "us";
  consoleKeyMap = "us";

  # Program Options (minimal for WSL)
  browser = ""; # No browser needed for WSL - will use Windows default
  terminal = "bash"; # or zsh

  # Hyprland Settings (not used in WSL)
  monitors = [ ];
  clock24h = true;

  # GPU/Prime Settings (not applicable to WSL)
  intelID = "";
  nvidiaID = "";

  # Services (disabled for WSL)
  enableNFS = false;
  printEnable = false;

  # System Features (minimal for WSL)
  enableGaming = false; # No Steam/gaming in WSL
  enableDesktop = false; # No GUI in WSL
  enableVirtualization = false; # No nested virtualization
  enableDevelopment = true; # Keep dev tools
  enableMultimedia = false; # No media players in WSL
}
