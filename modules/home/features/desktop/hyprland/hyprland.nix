{
  pkgs,
  inputs,
  username,
  flakeRoot,
  ...
}:
{
  home.packages = with pkgs; [
    swww
    grim
    slurp
    swappy
    ydotool
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
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    xwayland = {
      enable = true;
      # hidpi = true;
    };
    plugins = [
      inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprexpo
    ];
    # enableNvidiaPatches = false;
    systemd = {
      enable = true;
      variables = [ "--all" ];
    };
  };

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
