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
      flakeRoot = ./.;

      mkSystem =
        {
          username,
          host,
          profile,
          extraModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          modules = [
            { nixpkgs.hostPlatform = "x86_64-linux"; }
            ./profiles/${profile}
          ]
          ++ extraModules;
          specialArgs = {
            inherit
              inputs
              flakeRoot
              username
              host
              profile
              ;
            # Make stable packages globally available with proper dependencies
            stable = import nixpkgs-stable {
              localSystem = "x86_64-linux";
              config.allowUnfree = true;
            };
          };
        };
    in
    {
      nixosConfigurations = {
        # Main desktop system with NVIDIA GPU
        wassaa = mkSystem {
          username = "wassaa";
          host = "wassaa";
          profile = "nvidia";
        };

        # ThinkPad laptop with Intel integrated graphics
        tpad = mkSystem {
          username = "allar";
          host = "tpad";
          profile = "intel";
        };

        # WSL configuration
        wsl = mkSystem {
          username = "wsl";
          host = "wsl";
          profile = "wsl";
          extraModules = [ nixos-wsl.nixosModules.default ];
        };
      };
    };
}
