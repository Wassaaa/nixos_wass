{inputs, ...}: {
  imports = [
    # Core system modules
    ./boot.nix
    ./fonts.nix
    ./hardware.nix
    ./network.nix
    ./nfs.nix
    ./nh.nix
    ./packages.nix
    ./printing.nix
    ./security.nix
    ./services.nix
    ./starfish.nix
    ./stylix.nix
    ./syncthing.nix
    ./system.nix
    ./user.nix
    ./openssh.nix
    ./sops
    
    # Feature-based module loader
    ./features.nix
    
    # External modules
    inputs.stylix.nixosModules.stylix
    inputs.sops-nix.nixosModules.sops
  ];
}
