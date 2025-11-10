{
  config,
  lib,
  pkgs,
  flakeRoot,
  ...
}:
with lib;
let
  cfg = config.services.nordvpn;

  # NordVPN packages
  nordVpnPkg = pkgs.callPackage ./package.nix { };
  nordVpnGuiPkg = pkgs.callPackage ./package-gui.nix { };

  # Update script with resholve
  updateScript = pkgs.resholve.mkDerivation {
    pname = "update-nordvpn";
    version = "1.0.0";
    src = ./.;

    installPhase = ''
      install -Dm755 update-nordvpn.sh $out/bin/update-nordvpn
    '';

    solutions.default = {
      scripts = [ "bin/update-nordvpn" ];
      interpreter = "${pkgs.bash}/bin/bash";
      inputs = [
        pkgs.coreutils
        pkgs.curl
        pkgs.gawk
        pkgs.gnused
        pkgs.gnugrep
      ];
      execer = [ "cannot:${pkgs.gnused}/bin/sed" ];
    };

    postFixup = ''
      substituteInPlace $out/bin/update-nordvpn \
        --replace '@moduleFile@' '${flakeRoot}/modules/core/nordvpn/package.nix'
    '';

    meta = {
      description = "Update NordVPN package version and hash automatically";
      license = licenses.mit;
      platforms = platforms.linux;
      mainProgram = "update-nordvpn";
    };
  };
in
{
  options.services.nordvpn = {
    enable = mkEnableOption "NordVPN daemon";

    users = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of users to add to the nordvpn group";
    };

    enableGui = mkOption {
      type = types.bool;
      default = false;
      description = "Enable NordVPN GUI application";
    };

    includeUpdateScript = mkOption {
      type = types.bool;
      default = true;
      description = "Include the update-nordvpn script in system packages";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.checkReversePath = false;

    environment.systemPackages = [
      nordVpnPkg
    ]
    ++ lib.optional cfg.enableGui nordVpnGuiPkg
    ++ lib.optional cfg.includeUpdateScript updateScript;

    users.groups.nordvpn = { };
    users.users = builtins.listToAttrs (
      map (user: {
        name = user;
        value = {
          extraGroups = [ "nordvpn" ];
        };
      }) cfg.users
    );

    systemd.services.nordvpn = {
      description = "NordVPN daemon";
      serviceConfig = {
        ExecStart = "${nordVpnPkg}/bin/nordvpnd";
        ExecStartPre = pkgs.writeShellScript "nordvpn-start" ''
          mkdir -m 700 -p /var/lib/nordvpn
          if [ -z "$(ls -A /var/lib/nordvpn)" ]; then
            cp -r ${nordVpnPkg}/var/lib/nordvpn/* /var/lib/nordvpn
          fi
        '';
        NonBlocking = true;
        KillMode = "process";
        Restart = "on-failure";
        RestartSec = 5;
        RuntimeDirectory = "nordvpn";
        RuntimeDirectoryMode = "0750";
        Group = "nordvpn";
      };
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };
  };
}
