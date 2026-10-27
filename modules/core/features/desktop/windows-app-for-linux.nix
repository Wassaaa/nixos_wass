{
  lib,
  fetchurl,
  appimage-run,
  makeDesktopItem,
  symlinkJoin,
  writeShellScriptBin
}:
let
  version = "0.1.0";
  appimage = fetchurl {
    url = "https://github.com/mariuszkopowski/windows-app-for-linux/releases/download/v${version}/Windows.App-${version}.AppImage";
    hash = "sha256-8N1dGz0hWTcOlITDt0DjWSGVju55ExZP2shCs6MrcZM=";
  };
  icon = fetchurl {
    name = "windows-app-for-linux.svg";
    url = "https://raw.githubusercontent.com/mariuszkopowski/windows-app-for-linux/721e8d87edfc137d4ce2beeeaafef3009d7c8bb5/assets/icons/icon.svg";
    hash = "sha256-AaU+1XNXqqkCIlrNoCk+3MEiOGdzq+fFXfj1vD0z/nI=";
  };
  launcher = writeShellScriptBin "windows-app-for-linux" ''
    exec ${appimage-run}/bin/appimage-run ${appimage} "$@"
  '';
  desktopItem = makeDesktopItem {
    name = "windows-app-for-linux";
    desktopName = "Windows App";
    comment = "Unofficial Windows App web client";
    exec = "${launcher}/bin/windows-app-for-linux";
    icon = "${icon}";
    categories = [ "Network" "Office" ];
  };
in
symlinkJoin {
  name = "windows-app-for-linux-${version}";
  paths = [ launcher desktopItem ];
  meta = {
    description = "Unofficial Windows App web client for Linux";
    homepage = "https://github.com/mariuszkopowski/windows-app-for-linux";
    platforms = [ "x86_64-linux" ];
    mainProgram = "windows-app-for-linux";
  };
}
