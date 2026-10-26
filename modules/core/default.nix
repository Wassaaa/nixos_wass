{ inputs, ... }: {
  imports = [
    ./features.nix
    inputs.sops-nix.nixosModules.sops
  ];
}
