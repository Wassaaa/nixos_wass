{ ... }:
{
  imports = [
    ./hardware.nix
    ./host-packages.nix
  ];

  hardware.nvidia.open = true;
  hardware.i2c.enable = true;
}
