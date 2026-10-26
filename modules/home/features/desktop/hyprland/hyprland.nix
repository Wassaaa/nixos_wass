{
  config,
  lib,
  pkgs,
  inputs,
  username,
  flakeRoot,
  ...
}:
{
  home.packages = with pkgs; [
    waybar
    rofi-wayland
    hyprsome
    hyprsomescroll
    pyprland
    swww
    grim
    slurp
    swappy
    ydotool
    cliphist
    wl-clipboard
  ];

  # Export environment variables for systemd user services
  systemd.user.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    GDK_BACKEND = "wayland,x11";
    CLUTTER_BACKEND = "wayland";
  };

  systemd.user.targets.hyprland-session.Unit.Wants = [
    "xdg-desktop-autostart.target"
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";

    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;

    xwayland = {
      enable = true;
      # hidpi = true;
    };

    # plugins = [
    #   inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprexpo
    # ];

    # enableNvidiaPatches = false;

    systemd = {
      enable = true;
      variables = [ "--all" ];
    };

    settings = { };

    extraConfig = ''
      require("variables")
      require("settings")
      require("animations")
      require("binds")
      require("rules")
      require("monitors")
    '';
  };

  # Live-editable Hyprland Lua configuration.
  # These files stay in the repository and are symlinked into ~/.config/hypr.
  xdg.configFile."hypr/settings.lua".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos_wass/modules/home/features/desktop/hyprland/config/settings.lua";

  xdg.configFile."hypr/animations.lua".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos_wass/modules/home/features/desktop/hyprland/config/animations.lua";

  xdg.configFile."hypr/binds.lua".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos_wass/modules/home/features/desktop/hyprland/config/binds.lua";

  xdg.configFile."hypr/rules.lua".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos_wass/modules/home/features/desktop/hyprland/config/rules.lua";

  # Place Files Inside Home Directory
  home.file = {
    "Pictures/Wallpapers" = {
      source = "${flakeRoot}/wallpapers";
      recursive = true;
    };

    ".face.icon".source = ./face.jpg;
    ".config/face.jpg".source = ./face.jpg;

    ".config/swappy/config".text = ''
      [Default]
      save_dir=/home/${username}/Pictures/Screenshots
      save_filename_format=swappy-%Y%m%d-%H%M%S.png
      show_panel=false
      line_size=5
      text_size=20
      text_font=Ubuntu
      paint_mode=brush
      early_exit=true
      fill_shape=false
    '';
  };
}
