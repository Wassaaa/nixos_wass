{ host, flakeRoot, ... }:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") terminal;
in {
  programs.caelestia = {
    enable = true;
    # Start from Hyprland's Lua startup, preserving the live-editable workflow.
    systemd.enable = false;

    settings = {
      general.apps = {
        terminal = [ terminal ];
        audio = [ "pavucontrol" ];
        playback = [ "mpv" ];
        explorer = [ "thunar" ];
      };

      bar = {
        workspaces = {
          perMonitor = true;
          shown = 10;
        };
      };
    };

    cli = {
      enable = true;
      settings = {
        theme = {
          enableTerm = true;
          enableHypr = true;
          enableGtk = true;
          enableQt = true;
          # Keep unrelated application integrations off for this first trial.
          enableDiscord = false;
          enableSpicetify = false;
          enablePandora = false;
          enableFuzzel = false;
          enableBtop = false;
          enableNvtop = false;
          enableHtop = false;
          enableWarp = false;
          enableChromium = false;
          enableZed = false;
          enableCava = false;
          iconTheme = "Papirus-Dark";
          iconThemeDark = "Papirus-Dark";
          iconThemeLight = "Papirus-Light";
        };
      };
    };
  };
}
