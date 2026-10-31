{ pkgs, hyprland }:
let
  hyprlandLuaStubs =
    pkgs.runCommand "hyprland-lua-stubs"
      {
        nativeBuildInputs = [ pkgs.python314 ];
      }
      ''
        mkdir -p "$out"
        python ${hyprland}/meta/generateLuaStubs.py \
          --root ${hyprland} --output "$out/hl.meta.lua"
      '';
in
pkgs.mkShell {
  packages = with pkgs; [
    deadnix
    git
    lua5_4
    lua-language-server
    nixd
    nixfmt
    python314
    statix
    stylua
    uv
  ];
  WASSOS_HYPRLAND_LUA_STUBS = "${hyprlandLuaStubs}";
}
