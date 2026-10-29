{
  config,
  flakeRoot,
  host,
  lib,
  pkgs,
  ...
}:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") flakeDir;
  graph = "${flakeDir}/hosts/${host}/audio-routing.qpwgraph";
  graphLink = "${config.xdg.configHome}/qpwgraph/audio-routing.qpwgraph";
  startQpwgraph = pkgs.writeShellScript "start-qpwgraph" ''
    set -eu
    graph=${lib.escapeShellArg graph}

    if [ ! -e "$graph" ] && [ ! -L "$graph" ]; then
      if [ ! -d "$(dirname "$graph")" ]; then
        echo "qpwgraph: host checkout directory is missing: $(dirname "$graph")" >&2
        exit 1
      fi
      set -C
      printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' \
        '<!DOCTYPE patchbay>' \
        '<patchbay name="audio-routing" version="0.5.0"><items/></patchbay>' > "$graph"
      set +C
    fi

    if [ ! -f "$graph" ] || [ ! -r "$graph" ] || [ ! -w "$graph" ]; then
      echo "qpwgraph: graph is not a readable, writable file: $graph" >&2
      exit 1
    fi

    case ":''${XDG_CURRENT_DESKTOP:-}:" in
      *:Hyprland:*)
        export QT_QPA_PLATFORMTHEME=qtengine
        export QT_PLUGIN_PATH="${pkgs.qtengine}/${pkgs.qt6.qtbase.qtPluginPrefix}:${pkgs.darkly}/${pkgs.qt6.qtbase.qtPluginPrefix}''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
        ;;
    esac

    exec ${pkgs.qpwgraph}/bin/qpwgraph --activated --nonexclusive --minimized ${lib.escapeShellArg graphLink}
  '';
in
{
  xdg.configFile."qpwgraph/audio-routing.qpwgraph".source =
    config.lib.file.mkOutOfStoreSymlink graph;

  xdg.configFile."autostart/qpwgraph.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=qpwgraph
    Exec=${startQpwgraph}
  '';
}