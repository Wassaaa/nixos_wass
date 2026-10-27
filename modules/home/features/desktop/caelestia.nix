{ host, flakeRoot, inputs, pkgs, ... }:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") terminal;
  reloadHyprlandTheme = pkgs.writeShellScript "reload-caelestia-hyprland-theme" ''
    if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
      if ! ${inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland}/bin/hyprctl reload; then
        ${pkgs.libnotify}/bin/notify-send -u critical \
          "Caelestia theme" "Failed to reload Hyprland after changing the theme."
        exit 1
      fi
    fi
  '';
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
          postHook = "${reloadHyprlandTheme}";
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
