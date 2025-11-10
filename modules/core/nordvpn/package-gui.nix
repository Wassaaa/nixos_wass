{
  autoPatchelfHook,
  dpkg,
  fetchurl,
  lib,
  stdenv,
  # GUI dependencies
  glib,
  gtk3,
  libnotify,
  libappindicator-gtk3,
  libayatana-appindicator,
  wrapGAppsHook,
}:
let
  pname = "nordvpn-gui";
  version = "4.2.1";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/n/nordvpn-gui/nordvpn-gui_${version}_amd64.deb";
    sha256 = "c91e04918c152b5770be2088cb01e4a14a1fd492e32dbb971914c5749b7e1e00";
  };

  buildInputs = [
    glib
    gtk3
    libnotify
    libappindicator-gtk3
    libayatana-appindicator
  ];

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    wrapGAppsHook
    stdenv.cc.cc.lib
  ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    dpkg --extract $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    mv usr/* $out/
    runHook postInstall
  '';

  meta = with lib; {
    description = "GUI client for NordVPN";
    homepage = "https://www.nordvpn.com";
    license = licenses.unfreeRedistributable;
    platforms = [ "x86_64-linux" ];
  };
}
