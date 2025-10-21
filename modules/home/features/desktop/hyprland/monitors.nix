{ host, lib, flakeRoot, ... }:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix")
    monitors
    ;
in
{
  wayland.windowManager.hyprland.settings = {
    # Map the monitors set to hyprland config strings. Uses monitor description by default if set, otherwise name (e.g. DP-2)
    monitor = map (
      m:
      let
        resolution = "${toString m.width}x${toString m.height}@${toString m.refreshRate}";
        position = "${toString m.x}x${toString m.y}";
        monitorString = "${m.name}";
        vrr = "";
      in
      "${monitorString},${if m.enabled then "${resolution},${position},1${vrr}" else "disable,1"}"
    ) monitors;

    workspace = builtins.concatMap (
      m:
      let
        monitorString = "${m.name}";
      in
      map (w: "${w},monitor:${monitorString}") m.workspace
    ) (lib.filter (m: m.enabled && m.workspace != null) monitors);
  };
}
