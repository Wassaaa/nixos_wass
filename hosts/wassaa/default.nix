{ ... }:
{
  imports = [
    ./hardware.nix
    ./host-packages.nix
  ];

  hardware.nvidia.open = true;
}
