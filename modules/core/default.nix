{inputs, ...}: {
  imports = [
    # Feature-based module loader handles conditional imports
    ./features.nix
    
    # External modules
    inputs.stylix.nixosModules.stylix
    inputs.sops-nix.nixosModules.sops
  ];
}
