{host, flakeRoot, ...}: {
  imports = [
    "${flakeRoot}/hosts/${host}"
    "${flakeRoot}/modules/drivers"
    "${flakeRoot}/modules/core"
  ];
  # Enable GPU Drivers
  drivers.amdgpu.enable = true;
  drivers.nvidia.enable = false;
  drivers.nvidia-prime.enable = false;
  drivers.intel.enable = false;
  vm.guest-services.enable = false;
}
