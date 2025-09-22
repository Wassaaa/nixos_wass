{host, ...}: {
  imports = [
    ../../hosts/${host}
    ../../modules/drivers
    ../../modules/core
  ];
  
  # Disable all GPU drivers for WSL
  drivers.amdgpu.enable = false;
  drivers.nvidia.enable = false;
  drivers.nvidia-prime.enable = false;
  drivers.intel.enable = false;
  vm.guest-services.enable = false;
  
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
