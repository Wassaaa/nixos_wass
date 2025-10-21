{host, inputs, username, ...}: {
  imports = [
    ../../hosts/${host}
    ../../modules/core  # Now uses feature-based loading
  ];
  
  # WSL configuration
  wsl.enable = true;
  wsl.defaultUser = "wsl";
  programs.nix-ld.enable = true;
  
  # WSL-specific Nix daemon fixes
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
    # WSL-specific daemon settings to prevent connection issues
    keep-outputs = true;
    keep-derivations = true;
    # Ensure daemon can be reached
    use-xdg-base-directories = false;
    # Allow the WSL user to connect to the system nix daemon
    trusted-users = [ "root" "@wheel" "wsl" ];
  };
  
  # Ensure systemd works properly in WSL
  systemd.services.nix-daemon.serviceConfig = {
    # WSL-specific overrides for nix-daemon
    StandardOutput = "journal";
    StandardError = "journal";
  };
  
  # WSL-specific environment setup
  environment.variables = {
    # Ensure proper WSL integration
    NIXOS_WSL = "1";
  };
  
  # Enable essential services for WSL
  services.openssh.enable = true;
  
  # System version
  system.stateVersion = "25.05";
}
