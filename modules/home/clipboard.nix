{ pkgs, ... }:
let
  clipvault = pkgs.stdenvNoCC.mkDerivation {
    pname = "clipvault";
    version = "1.0.3";
    src = pkgs.fetchurl {
      url = "https://github.com/Rolv-Apneseth/clipvault/releases/download/v1.0.3/clipvault-x86_64-unknown-linux-gnu.tar.gz";
      sha256 = "sha256-FgMeJKRCk31AF7T9CFr3iZurRZw1Jh2HaEPcztpKgrM=";
    };
    nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.patchelf ];
      buildInputs = [ pkgs.stdenv.cc.cc.lib ];
      dontConfigure = true;
    dontBuild = true;
    unpackPhase = "tar -xzf $src";
    installPhase = ''
      mkdir -p $out/bin
      install -m755 clipvault $out/bin/clipvault
    '';
      meta.platforms = [ "x86_64-linux" ];
  };
  clipvaultRofi = pkgs.writeShellScriptBin "clipvault_rofi.sh" (builtins.readFile ./scripts/clipvault_rofi.sh);
in
{
  home.packages = (with pkgs; [
    wl-clipboard
    gawk
    wtype
  ]) ++ [ clipvault clipvaultRofi ];
}
