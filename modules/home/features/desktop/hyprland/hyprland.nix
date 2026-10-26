{ config, pkgs, inputs, flakeRoot, ... }:
let
  editable = name: config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/nixos_wass/modules/home/features/desktop/hyprland/config/${name}";
in {
  home.packages = with pkgs; [ lxqt.lxqt-policykit networkmanagerapplet ];
  systemd.user.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    GDK_BACKEND = "wayland,x11";
  };
  systemd.user.targets.hyprland-session.Unit.Wants = [ "xdg-desktop-autostart.target" ];
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    xwayland.enable = true;
    systemd = { enable = true; variables = [ "--all" ]; };
    settings = { };
    extraConfig = ''
      require("variables")
      require("settings")
      require("animations")
      require("binds")
      require("rules")
      require("monitors")
      hl.permission({ binary = "${pkgs.grim}/bin/grim", type = "screencopy", mode = "allow" })
    '';
  };
  xdg.configFile = {
    "hypr/plugins/split-monitor-workspaces".source = inputs.split-monitor-workspaces;
    "hypr/settings.lua".source = editable "settings.lua";
    "hypr/animations.lua".source = editable "animations.lua";
    "hypr/binds.lua".source = editable "binds.lua";
    "hypr/binds".source = editable "binds";
    "hypr/rules.lua".source = editable "rules.lua";
    "hypr/rules".source = editable "rules";
  };
  home.file = {
    "Pictures/Wallpapers" = { source = "${flakeRoot}/wallpapers"; recursive = true; };
    ".face.icon".source = ./face.jpg;
    ".config/face.jpg".source = ./face.jpg;
  };
}
