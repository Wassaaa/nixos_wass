# Variables for server host - headless server optimized
{
  # Git Configuration
  gitUsername = "Allar Klein";
  gitEmail = "allarklein@gmail.com";
  gitSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFbC++MIhGE9FrwsgT6SJp01/a1E3bnhQzbzMSutCKhL";


  # System Variables
  keyboardLayout = "us";
  consoleKeyMap = "us";

  # Program Options (minimal for server)
  browser = "";          # No browser needed
  terminal = "bash";     # Simple shell

  # No monitors for headless server
  monitors = [];

  # Waybar Settings (not used)
  clock24h = true;

  # GPU Settings (none for server)
  intelID = "";
  nvidiaID = "";

  # Services (server-appropriate)
  enableNFS = true;       # Might want NFS for server
  printEnable = false;    # No printing on server

  # System Features - SERVER OPTIMIZED
  enableGaming = false;      # Definitely no gaming
  enableDesktop = false;     # Headless server
  enableVirtualization = true; # Containers/VMs useful on server
  enableDevelopment = true;  # Dev tools for server management
  enableMultimedia = false;  # No media on headless server
}
