{ inputs, lib, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  quickshell = inputs.caelestia-shell.inputs.quickshell.packages.${system}.default;
  hyprland = inputs.hyprland.packages.${system}.hyprland;
  revision = "f28c5a38626cd0a5a13939748c9693d6c5401f9a";
  upstream = name: hash: pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/erikrjohansson/omarchy-extended-keybindings-viewer/${revision}/${name}";
    inherit hash;
  };
  viewerSource = upstream "ExtendedKeybindingsViewer.qml" "sha256-hrztCzzQPKnZHlJuTWKYT39LN1EymxK19wb7XMB8EL4=";
  keyboardSource = upstream "Keyboard.qml" "sha256-oZdr+eCEkdpGCTkS7qxijD5wVKk10s9/xxy5xY+wh7Y=";
  modelSource = upstream "Model.js" "sha256-xgaVdMDKUKGlW0rKoWQhUkmWyS58RE4SR7Ee752JKkk=";
  helperSource = upstream "extended-keybindings-viewer" "sha256-ek0c7GbijqT7Mwqvau2h6XVbaDG5LpKJ8/J4YAIX4hc=";
  bindingsSource = upstream "bindings.lua" "sha256-C+ILUe5YirUFC8FGRboykf00btXex8TFHWkv9yCkz9k=";
  licenseSource = upstream "LICENSE" "sha256-zbuNRqOLinXihrp+6JmWYbPXtXinmNNdSI5mbGTsy+U=";
  viewer = pkgs.runCommand "omarchy-keybindings-viewer" { } ''
    mkdir -p "$out/viewer"
    cp -R ${./keybindings-viewer/Commons} "$out/Commons"
    cp -R ${./keybindings-viewer/Ui} "$out/Ui"
    cp ${./keybindings-viewer/shell.qml} "$out/shell.qml"
    cp ${viewerSource} "$out/viewer/ExtendedKeybindingsViewer.qml"
    cp ${keyboardSource} "$out/viewer/Keyboard.qml"
    cp ${modelSource} "$out/viewer/Model.js"
    cp ${helperSource} "$out/viewer/extended-keybindings-viewer"
    cp ${bindingsSource} "$out/viewer/bindings.lua"
    cp ${licenseSource} "$out/viewer/LICENSE"
    chmod u+w "$out/viewer/ExtendedKeybindingsViewer.qml" "$out/viewer/extended-keybindings-viewer" "$out/viewer/bindings.lua"
    chmod +x "$out/viewer/extended-keybindings-viewer"
    patchShebangs "$out/viewer/extended-keybindings-viewer"
    substituteInPlace "$out/viewer/extended-keybindings-viewer" \
      --replace-fail '/usr/bin/python3' '${pkgs.python3}/bin/python3' \
      --replace-fail '  setup) setup ;;' '  setup) fail "The viewer is managed by Home Manager." ;;' \
      --replace-fail '  unsetup) unsetup ;;' '  unsetup) fail "The viewer is managed by Home Manager." ;;' \
      --replace-fail '  # Bindings Hyprland keeps active in every submap still run while the key' \
        $'  omarchy-menu-keybindings --physical || fail "Could not read physical key bindings."\n\n  # Bindings Hyprland keeps active in every submap still run while the key'
    substituteInPlace "$out/viewer/ExtendedKeybindingsViewer.qml" \
      --replace-fail ' + "/omarchy/extensions"' ' + "/keybindings-viewer"'
    substituteInPlace "$out/viewer/bindings.lua" \
      --replace-fail '"SUPER + K"' 'keybindingsViewerShortcut' \
      --replace-fail 'o.bind(keybindingsViewerShortcut, "Keybindings", "omarchy-shell shell toggle " .. viewer_id)' \
        'hl.bind(keybindingsViewerShortcut, hl.dsp.exec_cmd("keybindings-viewer toggle"), { description = "Show keybindings" })' \
      --replace-fail '"omarchy-shell shell hide " .. viewer_id' '"keybindings-viewer hide"'
  '';
  records = pkgs.writeShellApplication {
    name = "omarchy-menu-keybindings";
    runtimeInputs = [ hyprland pkgs.python3 ];
    text = ''exec ${pkgs.python3}/bin/python ${./keybindings-viewer/records.py} "$@"'';
  };
  command = pkgs.writeShellApplication {
    name = "keybindings-viewer";
    runtimeInputs = [ quickshell pkgs.libnotify ];
    text = ''
      case "''${1:-}" in
        toggle|hide) action="$1" ;;
        *) echo "Usage: keybindings-viewer toggle|hide" >&2; exit 2 ;;
      esac
      if ! output=$(qs -p ${viewer}/shell.qml ipc call keybindings-viewer "$action" 2>&1); then
        printf 'Keybindings viewer: %s\n' "$output" >&2
        notify-send -u critical "Keybindings viewer" "Could not contact the viewer service."
        exit 1
      fi
    '';
  };
in {
  home.packages = [ command ];

  wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
    dofile("${viewer}/viewer/bindings.lua")
  '';

  systemd.user.services.keybindings-viewer = {
    Unit = {
      Description = "Experimental keybindings viewer";
      After = [ "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };
    Service = {
      Type = "exec";
      ExecStart = "${quickshell}/bin/qs -p ${viewer}/shell.qml";
      Environment = [
        "QT_QPA_PLATFORM=wayland"
        "PATH=${lib.makeBinPath [ records command hyprland pkgs.jq pkgs.gawk pkgs.gnugrep pkgs.coreutils pkgs.libxkbcommon pkgs.python3 ]}"
        "LD_LIBRARY_PATH=${lib.makeLibraryPath [ pkgs.libxkbcommon ]}"
      ];
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };
}
