{
  description = "ZaneyOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nvf.url = "github:notashelf/nvf";
    stylix.url = "github:danth/stylix/release-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions/master";
    catppuccin.url = "github:catppuccin/nix";
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
  };

  outputs = {nixpkgs, nixos-wsl, ...} @ inputs: let
    system = "x86_64-linux";
    host = "wassaa";
    profile = "nvidia";
    username = "wassaa";
  in {
    nixosConfigurations = {
      amd = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          inherit username;
          inherit host;
          inherit profile;
        };
        modules = [./profiles/amd];
      };
      nvidia = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          inherit username;
          inherit host;
          inherit profile;
        };
        modules = [./profiles/nvidia];
      };
      nvidia-laptop = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          inherit username;
          inherit host;
          inherit profile;
        };
        modules = [./profiles/nvidia-laptop];
      };
      intel = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          inherit username;
          inherit host;
          inherit profile;
        };
        modules = [./profiles/intel];
      };
      vm = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          inherit username;
          inherit host;
          inherit profile;
        };
        modules = [./profiles/vm];
      };
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
      tpad = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          username = "allar";
          host = "tpad";
          profile = "intel"; # Intel CPU with integrated graphics
        };
        modules = [./profiles/intel];
      };
      # Example laptop configuration - uncomment and customize as needed
      # laptop = nixpkgs.lib.nixosSystem {
      #   inherit system;
      #   specialArgs = {
      #     inherit inputs;
      #     username = "your-username";
      #     host = "laptop";
      #     profile = "nvidia"; # or "amd", "intel" based on your GPU
      #   };
      #   modules = [./profiles/nvidia]; # or the appropriate profile
      # };
    };
  };
}
