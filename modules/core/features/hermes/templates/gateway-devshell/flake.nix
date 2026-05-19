{
  description = "Mutable devshell for this Hermes gateway identity";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          # Baseline shell/system tools
          bashInteractive
          coreutils
          git
          curl
          jq
          ripgrep
          fd
          direnv

          # Media/voice/document tools commonly used by Hermes skills
          ffmpeg
          imagemagick
          mediainfo
          exiftool
          sox

          # Language/package managers for gateway-owned helper tools
          nodejs_24
          python312
          uv
        ];

        shellHook = ''
          export HERMES_GATEWAY_WORKSPACE="$PWD"
          export HERMES_MUTABLE_DEVSHELL=1
        '';
      };
    };
}
