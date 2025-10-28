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
    solaar = {
      url = "https://flakehub.com/f/Svenum/Solaar-Flake/*.tar.gz"; # For latest stable version
      #url = "https://flakehub.com/f/Svenum/Solaar-Flake/0.1.3.tar.gz"; # uncomment line for solaar version 1.1.15
      #url = "github:Svenum/Solaar-Flake/main"; # Uncomment line for latest unstable version
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-stable,
      nixos-wsl,
      solaar,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      flakeRoot = ./.;

      # Overlay to replace specific packages with stable versions
      # Just add package names here - each will be pulled from nixpkgs-stable
      stableOverlay = final: prev: {
        qgnomeplatform = nixpkgs-stable.legacyPackages.${system}.qgnomeplatform;
        qt6 = nixpkgs-stable.legacyPackages.${system}.qt6;
        # gnome = nixpkgs-stable.legacyPackages.${system}.gnome;
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
            solaar.nixosModules.default
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
