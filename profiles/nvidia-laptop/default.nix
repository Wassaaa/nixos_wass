{ host, flakeRoot, ... }:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") intelID nvidiaID;
in
{
  imports = [
    "${flakeRoot}/hosts/${host}"
    "${flakeRoot}/modules/drivers"
    "${flakeRoot}/modules/core"
  ];
  # Enable GPU Drivers
  drivers.amdgpu.enable = false;
  drivers.nvidia.enable = true;
  drivers.nvidia-prime = {
    enable = true;
    intelBusID = "${intelID}";
    nvidiaBusID = "${nvidiaID}";
  };
  drivers.intel.enable = false;
  vm.guest-services.enable = false;
}
