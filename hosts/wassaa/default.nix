{ ... }:
{
  imports = [
    ./hardware.nix
    ./host-packages.nix
  ];

  environment.variables = {
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
  };
  hardware.nvidia.open = true;
}
