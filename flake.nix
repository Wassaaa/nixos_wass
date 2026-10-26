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
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    split-monitor-workspaces = {
      url = "github:zjeffer/split-monitor-workspaces";
      flake = false;
    };
    vscode-insiders = {
      url = "github:Wassaaa/code-insiders-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    noctalia.url = "github:noctalia-dev/noctalia-shell";
    hermes-agent = {
      url = "github:nousresearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
            stable = import nixpkgs-stable {
              localSystem = "x86_64-linux";
              config.allowUnfree = true;
            };
          };
        };
    in
    {
      nixosConfigurations = {
        wassaa = mkSystem {
          username = "wassaa";
          host = "wassaa";
          profile = "nvidia";
        };

        tpad = mkSystem {
          username = "allar";
          host = "tpad";
          profile = "intel";
        };

        wsl = mkSystem {
          username = "wsl";
          host = "wsl";
          profile = "wsl";
          extraModules = [ nixos-wsl.nixosModules.default ];
        };
      };
    };
}
