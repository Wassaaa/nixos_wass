{ pkgs, config, ... }:
let
  sockPath = "${config.home.homeDirectory}/.1password/agent.sock";
in
{
  systemd.user.services.onepassword = {
    Unit = {
      Description = "1Password";
      After = [ "graphical-session.target" ];
      Wants = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs._1password-gui}/bin/1password --silent";
      Restart = "on-failure";
      RestartSec = "5";
      Type = "simple";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # 2. SSH Client Configuration
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "*" = {
        identityAgent = sockPath;
      };

      # Host Aliases
      "github.com" = {
        hostname = "github.com";
        user = "git";
      };

      "gitlab.com" = {
        hostname = "gitlab.com";
        user = "git";
      };

      "bitbucket.org" = {
        hostname = "bitbucket.org";
        user = "git";
      };
    };
  };
  home.sessionVariables = {
    SSH_AUTH_SOCK = sockPath;
  };
}
