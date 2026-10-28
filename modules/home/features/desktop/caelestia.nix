{ config, host, flakeRoot, inputs, pkgs, ... }:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") terminal;
  swappyClipboard = pkgs.writeShellApplication {
    name = "swappy";
    runtimeInputs = with pkgs; [ coreutils libnotify swappy wl-clipboard ];
    text = builtins.readFile ./swappy-clipboard.sh;
  };
  startCheck = pkgs.writeShellApplication {
    name = "caelestia-start-check";
    runtimeInputs = [ config.programs.caelestia.package pkgs.jq pkgs.libnotify ];
    text = builtins.readFile ./caelestia-start-check.sh;
  };
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
  systemd.user.services.caelestia.Service.ExecCondition = "${startCheck}/bin/caelestia-start-check";

  programs.caelestia = {
    enable = true;
    package = inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli.override {
      swappy = swappyClipboard;
    };
    systemd = {
      enable = true;
      target = "hyprland-session.target";
    };

    settings = {
      general.apps = {
        terminal = [ terminal ];
        audio = [ "pavucontrol" ];
        playback = [ "mpv" ];
        explorer = [ "thunar" ];
      };

      general.idle = {
        inhibitWhenAudio = false;
        timeouts = [
          { timeout = 900; idleAction = "lock"; }
          { timeout = 1200; idleAction = "dpms off"; returnAction = "dpms on"; }
        ];
      };

      launcher.useFuzzy.apps = true;

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
