{
  description = "WassOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    stylix.url = "github:danth/stylix";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-insiders = {
      url = "github:iosmanthus/code-insiders-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-stable,
      nixos-wsl,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      flakeRoot = ./.;

      # Overlay to replace specific packages with stable versions
      # Just add package names here - each will be pulled from nixpkgs-stable
      stableOverlay = final: prev: {
        qgnomeplatform = nixpkgs-stable.legacyPackages.${system}.qgnomeplatform;
        bat-extras = nixpkgs-stable.legacyPackages.${system}.bat-extras;

        # Add more stable packages here as needed:
        # firefox = nixpkgs-stable.legacyPackages.${system}.firefox;
        # gdm = nixpkgs-stable.legacyPackages.${system}.gdm;
      };
    in
    {
      nixosConfigurations = {
        # Main desktop system with NVIDIA GPU
        wassaa = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs flakeRoot;
            username = "wassaa";
            host = "wassaa";
            profile = "nvidia";
          };
          modules = [
            ./profiles/nvidia
            { nixpkgs.overlays = [ stableOverlay ]; }
          ];
        };
        # ThinkPad laptop with Intel integrated graphics
        tpad = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs flakeRoot;
            username = "allar";
            host = "tpad";
            profile = "intel";
          };
          modules = [
            ./profiles/intel
            { nixpkgs.overlays = [ stableOverlay ]; }
          ];
        };

        # WSL configuration
        wsl = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs flakeRoot;
            username = "wsl";
            host = "wsl";
            profile = "wsl";
          };
          modules = [
            ./profiles/wsl
            nixos-wsl.nixosModules.default
            { nixpkgs.overlays = [ stableOverlay ]; }
          ];
        };
      };
    };
}
