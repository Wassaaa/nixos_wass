{...}: {
  imports = [
    ./hardware.nix  # You'll need to generate this with nixos-generate-config
    ./host-packages.nix
  ];
}