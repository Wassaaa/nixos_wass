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
  # System version
  system.stateVersion = "25.05";
}
