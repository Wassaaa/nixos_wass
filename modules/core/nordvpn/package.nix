{
  autoPatchelfHook,
  buildFHSEnv,
  dpkg,
  fetchurl,
  lib,
  stdenv,
  sysctl,
  iptables,
  iproute2,
  procps,
  cacert,
  libnl,
  libcap_ng,
  sqlite,
  libxml2,
  libidn2,
  zlib,
  wireguard-tools,
}:
let
  pname = "nordvpn";
  version = "4.2.1";

  nordVPNBase = stdenv.mkDerivation {
    inherit pname version;

    src = fetchurl {
      url = "https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/n/nordvpn/nordvpn_${version}_amd64.deb";
      sha256 = "0ccc8d3dcd3cb71be4001dd028ae15887a26b2bdd9de5e897ab510d33b9196ba";
    };

    buildInputs = [
      libxml2
      libidn2
      libnl
      sqlite
      libcap_ng
      zlib
    ];
    nativeBuildInputs = [
      dpkg
      autoPatchelfHook
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
      mv var/ $out/
      mv etc/ $out/
      runHook postInstall
    '';
  };

  nordVPNfhs = buildFHSEnv {
    name = "nordvpnd";
    runScript = "nordvpnd";

    targetPkgs = pkgs: [
      sqlite
      nordVPNBase
      sysctl
      iptables
      iproute2
      procps
      cacert
      libnl
      libcap_ng
      libxml2
      libidn2
      zlib
      wireguard-tools
    ];
  };
in
stdenv.mkDerivation {
  inherit pname version;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share
    ln -s ${nordVPNBase}/bin/nordvpn $out/bin
    ln -s ${nordVPNfhs}/bin/nordvpnd $out/bin
    ln -s ${nordVPNBase}/share/* $out/share/
    ln -s ${nordVPNBase}/var $out/
    runHook postInstall
  '';

  meta = with lib; {
    description = "CLI client for NordVPN";
    homepage = "https://www.nordvpn.com";
    license = licenses.unfreeRedistributable;
    platforms = [ "x86_64-linux" ];
  };
}
