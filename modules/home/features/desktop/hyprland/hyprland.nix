{
  config,
  lib,
  pkgs,
  inputs,
  flakeRoot,
  ...
}:
let
  editable =
    name:
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos_wass/modules/home/features/desktop/hyprland/config/${name}";
in
{
  home.packages = with pkgs; [
    networkmanagerapplet
  ];
  systemd.user.targets.hyprland-session.Unit.Wants = [ "xdg-desktop-autostart.target" ];
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = null;
    xwayland.enable = true;
    systemd = {
      enable = true;
      variables = [
        "DISPLAY"
        "HYPRLAND_INSTANCE_SIGNATURE"
        "WAYLAND_DISPLAY"
        "XDG_CURRENT_DESKTOP"
        "XDG_SESSION_TYPE"
        "XDG_SESSION_DESKTOP"
      ];
    };
    settings = { };
    extraConfig = ''
      hl.env("NIXOS_OZONE_WL", "1")
      hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
      hl.env("XDG_SESSION_TYPE", "wayland")
      hl.env("XDG_SESSION_DESKTOP", "Hyprland")
      hl.env("MOZ_ENABLE_WAYLAND", "1")
      hl.env("GDK_BACKEND", "wayland,x11")
      hl.env("QT_QPA_PLATFORM", "wayland;xcb")
      hl.env("QT_QPA_PLATFORMTHEME", "qtengine")
      local qtPluginPath = os.getenv("QT_PLUGIN_PATH")
      local caelestiaQtPlugins = "${pkgs.qtengine}/${pkgs.qt6.qtbase.qtPluginPrefix}:${pkgs.darkly}/${pkgs.qt6.qtbase.qtPluginPrefix}"
      if qtPluginPath and qtPluginPath ~= "" then
        if qtPluginPath == caelestiaQtPlugins or qtPluginPath:sub(1, #caelestiaQtPlugins + 1) == caelestiaQtPlugins .. ":" then
          caelestiaQtPlugins = qtPluginPath
        else
          caelestiaQtPlugins = caelestiaQtPlugins .. ":" .. qtPluginPath
        end
      end
      hl.env("QT_PLUGIN_PATH", caelestiaQtPlugins)
      hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
      hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
      hl.env("SDL_VIDEODRIVER", "wayland,x11,windows")
      hl.env("CLUTTER_BACKEND", "wayland")
      hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
      hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

      require("variables")
      require("settings")
      require("theme")
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
    "hypr/theme.lua".source = editable "theme.lua";
    "hypr/animations.lua".source = editable "animations.lua";
    "hypr/binds.lua".source = editable "binds.lua";
    "hypr/binds".source = editable "binds";
    "hypr/rules.lua".source = editable "rules.lua";
    "hypr/rules".source = editable "rules";
  };
  home.file = {
    "Pictures/Wallpapers" = {
      source = "${flakeRoot}/wallpapers";
      recursive = true;
    };
  };
  home.activation.initializeProfilePicture = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    source ${./initialize-profile-picture.sh} ${./face.jpg}
  '';
}
