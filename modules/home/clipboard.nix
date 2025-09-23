{ pkgs, ... }: {
  home.packages = with pkgs; [
    cliphist
    wl-clipboard
  ];

  # Systemd service to run cliphist daemon
  systemd.user.services.cliphist = {
    Unit = {
      Description = "Clipboard history service";
      After = [ "graphical-session.target" ];
      Wants = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
      RestartSec = "5";
      Type = "simple";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # Shell aliases for easy clipboard management
  programs.zsh.shellAliases = {
    clipshow = "cliphist list";
    clipclear = "cliphist wipe";
    clipdel = "cliphist delete";
  };
}
