{ pkgs, config, lib, ... }:
let
  sockPath = "${config.home.homeDirectory}/.1password/agent.sock";
  extensionId = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";
  chromeExtension = pkgs.writeText "1password-chrome-extension.json" (builtins.toJSON {
    external_update_url = "https://clients2.google.com/service/update2/crx";
  });
in
{
  programs.brave.extensions = [ extensionId ];
  programs.google-chrome.package = lib.mkIf config.programs.google-chrome.enable (
    pkgs.google-chrome.overrideAttrs (oldAttrs: {
      postInstall = (oldAttrs.postInstall or "") + ''
        mkdir -p "$out/share/google/chrome/extensions"
        cp ${chromeExtension} "$out/share/google/chrome/extensions/${extensionId}.json"
      '';
    })
  );

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
    enableDefaultConfig = false;
    settings = {
      "*" = {
        IdentityAgent = sockPath;
        ForwardAgent = lib.mkDefault false;
        AddKeysToAgent = lib.mkDefault "no";
        Compression = lib.mkDefault false;
        ServerAliveInterval = lib.mkDefault 0;
        ServerAliveCountMax = lib.mkDefault 3;
        HashKnownHosts = lib.mkDefault false;
        UserKnownHostsFile = lib.mkDefault "~/.ssh/known_hosts";
        ControlMaster = lib.mkDefault "no";
        ControlPath = lib.mkDefault "~/.ssh/master-%r@%n:%p";
        ControlPersist = lib.mkDefault "no";
      };

      # Host Aliases
      "github.com" = {
        HostName = "github.com";
        User = "git";
      };

      "gitlab.com" = {
        HostName = "gitlab.com";
        User = "git";
      };

      "bitbucket.org" = {
        HostName = "bitbucket.org";
        User = "git";
      };
    };
  };
  home.sessionVariables = {
    SSH_AUTH_SOCK = sockPath;
  };
}
