{ pkgs, ... }:
{
  # Waybar service for Niri - auto-starts with niri session
  systemd.user.services.waybar-niri = {
    Unit = {
      Description = "Waybar status bar (Niri session)";
      PartOf = "graphical-session.target";
      After = "graphical-session.target";
      ConditionEnvironment = "XDG_CURRENT_DESKTOP=niri";
    };
    Service = {
      ExecStart = "${pkgs.waybar}/bin/waybar";
      Restart = "on-failure";
      RestartSec = "1s";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
