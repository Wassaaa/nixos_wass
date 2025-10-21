{
  description = "WassOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nvf.url = "github:notashelf/nvf";
    stylix.url = "github:danth/stylix";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions/master";
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
    { nixpkgs, nixos-wsl, ... }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations = {
        # Main desktop system with NVIDIA GPU
        wassaa = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            username = "wassaa";
            host = "wassaa";
            profile = "nvidia";
          };
          modules = [ ./profiles/nvidia ];
        }; # ThinkPad laptop with Intel integrated graphics
        tpad = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            username = "allar";
            host = "tpad";
            profile = "intel";
          };
          modules = [ ./profiles/intel ];
        };

        # WSL configuration
        wsl = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            username = "nixos";
            host = "wsl";
            profile = "wsl";
          };
          modules = [
            ./profiles/wsl
            nixos-wsl.nixosModules.default
          ];
        };
      };
    };
}
