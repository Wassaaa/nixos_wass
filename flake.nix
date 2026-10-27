{
  description = "WassOS";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    caelestia-cli = {
      url = "github:caelestia-dots/cli";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.caelestia-shell.follows = "caelestia-shell";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
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
    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    windows-app-for-linux-src = {
      url = "github:mariuszkopowski/windows-app-for-linux/721e8d87edfc137d4ce2beeeaafef3009d7c8bb5";
      flake = false;
    };
  };
  outputs = { nixpkgs, nixpkgs-stable, nixos-wsl, ... }@inputs:
    let
      flakeRoot = ./.;
      mkSystem = { username, host, profile, extraModules ? [ ] }:
        nixpkgs.lib.nixosSystem {
          modules = [
            { nixpkgs.hostPlatform = "x86_64-linux"; }
            ./profiles/${profile}
          ] ++ extraModules;
          specialArgs = {
            inherit inputs flakeRoot username host profile;
            stable = import nixpkgs-stable {
              localSystem = "x86_64-linux";
              config.allowUnfree = true;
            };
          };
        };
    in {
      packages.x86_64-linux.windows-app-for-linux =
        let
          pkgs = import nixpkgs { system = "x86_64-linux"; };
        in
        pkgs.callPackage ./modules/core/features/desktop/windows-app-for-linux.nix {
          windowsAppSrc = inputs.windows-app-for-linux-src;
        };

      nixosConfigurations = {
        wassaa = mkSystem { username = "wassaa"; host = "wassaa"; profile = "nvidia"; };
        tpad = mkSystem { username = "allar"; host = "tpad"; profile = "intel"; };
        wsl = mkSystem {
          username = "wsl"; host = "wsl"; profile = "wsl";
          extraModules = [ nixos-wsl.nixosModules.default ];
        };
      };
    };
}
