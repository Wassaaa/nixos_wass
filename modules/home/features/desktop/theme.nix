{ config, pkgs, lib, inputs, ... }:
let
  hyprctl = "${inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland}/bin/hyprctl";
  apply = pkgs.writeShellApplication {
    name = "desktop-theme-apply";
    runtimeInputs = with pkgs; [ coreutils procps dconf glib ];
    text = ''
      mode="''${1:-dark}"
      case "$mode" in dark|light) ;; *) echo "Expected dark or light" >&2; exit 2 ;; esac
      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/wass-desktop"
      mkdir -p "$state_dir"
      temporary=$(mktemp "$state_dir/.theme.XXXXXX")
      printf '%s\n' "$mode" > "$temporary"
      mv "$temporary" "$state_dir/theme"
      dconf write /org/gnome/desktop/interface/color-scheme "'prefer-$mode'"
      variant=""
      signal=USR2
      if [ "$mode" = dark ]; then variant=-dark; signal=USR1; fi
      gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3$variant"
      pkill -"$signal" -x foot || true
      if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        ${hyprctl} eval "require('theme').apply('$mode')" || true
      fi
    '';
  };
  switch = pkgs.writeShellApplication {
    name = "desktop-theme";
    runtimeInputs = [ pkgs.coreutils pkgs.darkman ];
    text = ''
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/wass-desktop/theme"
      current=dark
      if [ -r "$state" ]; then current=$(cat "$state"); fi
      case "''${1:-toggle}" in
        dark|light) mode="$1" ;;
        toggle) if [ "$current" = dark ]; then mode=light; else mode=dark; fi ;;
        refresh) mode="$current" ;;
        *) echo "Usage: desktop-theme [dark|light|toggle|refresh]" >&2; exit 2 ;;
      esac
      if ! darkman set "$mode"; then
        echo "Darkman unavailable; applying the desktop theme directly" >&2
      fi
      exec ${apply}/bin/desktop-theme-apply "$mode"
    '';
  };
in {
  home.packages = [ switch ];
  services.darkman = {
    enable = true;
    settings.usegeoclue = false;
    scripts.desktop = ''${apply}/bin/desktop-theme-apply "$1"'';
  };
  systemd.user.services.darkman.Unit.After = [ "graphical-session.target" ];
  systemd.user.services.desktop-theme-sync = {
    Unit = {
      Description = "Initialize the coordinated desktop theme";
      After = [ "darkman.service" "foot.service" ];
      Requires = [ "darkman.service" ];
      PartOf = [ "hyprland-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${switch}/bin/desktop-theme dark";
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };
  xdg.configFile."hypr/theme.lua".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixos_wass/modules/home/features/desktop/hyprland/config/theme.lua";
  wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
    require("theme")
  '';
}
