{ pkgs, ... }:
{
  # Waybar service for Hyprland - auto-starts with hyprland session
  systemd.user.services.waybar-hyprland = {
    Unit = {
      Description = "Waybar status bar (Hyprland session)";
      PartOf = "graphical-session.target";
      After = [ "graphical-session.target" "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.waybar}/bin/waybar";
      Restart = "on-failure";
      RestartSec = "1s";
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };
}
