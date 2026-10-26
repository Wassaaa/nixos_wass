{ pkgs, lib, inputs, host, flakeRoot, ... }:
let
  variables = import "${flakeRoot}/hosts/${host}/variables.nix";
  monitors = lib.filter (m: m.enabled or true) (variables.monitors or [ ]);
  primary = lib.findFirst (m: m.primary or false)
    (if monitors == [ ] then { name = ""; } else builtins.head monitors) monitors;
  shellConfig = pkgs.runCommand "wass-quickshell-config" { } ''
    mkdir -p "$out"
    cp -R ${inputs.fufexan-dotfiles}/home/services/quickshell/. "$out/"
    chmod -R u+w "$out"
    substituteInPlace "$out/utils/Config.qml" \
      --replace-fail 'return [...Quickshell.screens].find(e => e.name == "eDP-1");' \
      'return screens.find(e => e.name == ${builtins.toJSON primary.name}) ?? screens[0];'
  '';
  dependencies = with pkgs; [
    bash coreutils dconf gawk lsof ripgrep procps util-linux
    playerctl wireplumber brightnessctl networkmanager bluez
  ];
  qmlPath = lib.concatStringsSep ":" [
    "${pkgs.quickshell}/lib/qt-6/qml"
    "${pkgs.kdePackages.qtdeclarative}/lib/qt-6/qml"
    "${pkgs.kdePackages.kirigami.unwrapped}/lib/qt-6/qml"
  ];
in {
  home.packages = [ pkgs.quickshell pkgs.material-symbols ];
  xdg.configFile."quickshell".source = shellConfig;
  systemd.user.services.quickshell = {
    Unit = {
      Description = "Fufexan Quickshell desktop";
      PartOf = [ "hyprland-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Environment = [
        "PATH=/run/wrappers/bin:${lib.makeBinPath dependencies}"
        "QML2_IMPORT_PATH=${qmlPath}"
      ];
      ExecStart = lib.getExe pkgs.quickshell;
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };
}
