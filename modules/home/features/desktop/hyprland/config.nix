{
  host,
  config,
  flakeRoot,
  ...
}:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix")
    # extraMonitorSettings
    keyboardLayout
    ;
in
{
  wayland.windowManager.hyprland = {
    # Fix for systemd services (hypridle, etc.) - exports all environment variables
    systemd.variables = ["--all"];

    settings = {
      exec-once = [
        # Start compositor-dependent services
        "lxqt-policykit-agent &"
        "nm-applet --indicator &"
        # Start UI components
        "waybar &"
        "pypr &"
        # Start background services
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "killall -q swww-daemon;sleep .5 && swww-daemon"
      ];

      input = {
        kb_layout = "${keyboardLayout}";
        kb_options = [
          "grp:alt_caps_toggle"
        ];
        numlock_by_default = true;
        repeat_delay = 300;
        follow_mouse = 1;
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
          scroll_factor = 0.8;
        };
      };

      general = {
        "$modifier" = "SUPER";
        layout = "dwindle";
        gaps_in = 6;
        gaps_out = 8;
        border_size = 2;
        resize_on_border = true;
        "col.active_border" =
          "rgb(${config.lib.stylix.colors.base08}) rgb(${config.lib.stylix.colors.base0C}) 45deg";
        "col.inactive_border" = "rgb(${config.lib.stylix.colors.base01})";
      };

      misc = {
        layers_hog_keyboard_focus = true;
        initial_workspace_tracking = 0;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = false;
      };

      plugin = {
        hyprexpo = {
          columns = 3;
          gap_size = 5;
          bg_col = "rgb(111111)";
          workspace_method = "center current";
          enable_gesture = true;
          gesture_fingers = 3;
          gesture_distance = 300;
        };
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 5;
          passes = 3;
          ignore_opacity = false;
          new_optimizations = true;
        };
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "wind, 0.05, 0.9, 0.1, 1.05"
          "winIn, 0.1, 1.1, 0.1, 1.1"
          "winOut, 0.3, -0.3, 0, 1"
          "liner, 1, 1, 1, 1"
        ];
        animation = [
          "windows, 1, 6, wind, slide"
          "windowsIn, 1, 6, winIn, slide"
          "windowsOut, 1, 5, winOut, slide"
          "windowsMove, 1, 5, wind, slide"
          "border, 1, 1, liner"
          "fade, 1, 10, default"
          "workspaces, 1, 5, wind"
        ];
      };

      env = [
        "NIXOS_OZONE_WL, 1"
        "NIXPKGS_ALLOW_UNFREE, 1"
        "XDG_CURRENT_DESKTOP, Hyprland"
        "XDG_SESSION_TYPE, wayland"
        "XDG_SESSION_DESKTOP, Hyprland"
        "GDK_BACKEND, wayland, x11"
        "CLUTTER_BACKEND, wayland"
        "QT_QPA_PLATFORM=wayland;xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION, 1"
        "QT_AUTO_SCREEN_SCALE_FACTOR, 1"
        "SDL_VIDEODRIVER, x11"
        "MOZ_ENABLE_WAYLAND, 1"
      ];

      # Window rules converted to new Hyprland syntax
      # Note: windowrulev2 is deprecated, using extraConfig with new syntax
    };

    extraConfig = ''
      # Window rules - new syntax for Hyprland 0.52.0+
      windowrule = match:class ^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$, tag +file-manager
      windowrule = match:class ^(Alacritty|kitty|kitty-dropterm)$, tag +terminal
      windowrule = match:class ^(Brave-browser(-beta|-dev|-unstable)?)$, tag +browser
      windowrule = match:class ^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr)$, tag +browser
      windowrule = match:class ^([Gg]oogle-chrome(-beta|-dev|-unstable|-stable)?)$, tag +browser
      windowrule = match:class ^([Tt]horium-browser|[Cc]achy-browser)$, tag +browser
      windowrule = match:class ^(codium|codium-url-handler|VSCodium)$, tag +projects
      windowrule = match:class ^(VSCode|code-url-handler)$, tag +projects
      windowrule = match:class ^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$, tag +im
      windowrule = match:class ^([Ff]erdium)$, tag +im
      windowrule = match:class ^([Ww]hatsapp-for-linux)$, tag +im
      windowrule = match:class ^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$, tag +im
      windowrule = match:class ^(teams-for-linux)$, tag +im
      windowrule = match:class ^(gamescope)$, tag +games
      windowrule = match:class ^(steam_app_\d+)$, tag +games
      windowrule = match:title ^(World of Warcraft)$, tag +games
      windowrule = match:title ^(Battle\.net)$, tag +gamestore
      windowrule = match:class ^([Ss]team)$, tag +gamestore
      windowrule = match:title ^([Ll]utris)$, tag +gamestore
      windowrule = match:class ^(com.heroicgameslauncher.hgl)$, tag +gamestore
      windowrule = match:class ^(gnome-disks|wihotspot(-gui)?)$, tag +settings
      windowrule = match:class ^([Rr]ofi)$, tag +settings
      windowrule = match:class ^(file-roller|org.gnome.FileRoller)$, tag +settings
      windowrule = match:class ^(nm-applet|nm-connection-editor|blueman-manager)$, tag +settings
      windowrule = match:class ^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$, tag +settings
      windowrule = match:class ^(nwg-look|qt5ct|qt6ct|[Yy]ad)$, tag +settings
      windowrule = match:class (xdg-desktop-portal-gtk), tag +settings
      windowrule = match:class ^(lxqt-policykit-agent|org.kde.polkit-kde-authentication-agent-1)$, tag +polkit
      windowrule = match:title ^(PolicyKit|Authentication)$, tag +polkit
      windowrule = match:class ^(1password)$ match:title ^(.*SSH.*|.*Unlock.*|.*Authorize.*|.*Authentication.*)$, tag +1password-prompt
      windowrule = match:class ^(1password)$ match:title ^(1Password)$ match:float true, tag +1password-prompt
      windowrule = match:class ^(1password)$ match:float true match:maxsize 600 400, tag +1password-prompt
      windowrule = match:title ^(Picture-in-Picture)$, move 72% 7%
      windowrule = match:class ^([Ff]erdium)$, center 1
      windowrule = match:class ^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$, center 1
      windowrule = match:class ([Tt]hunar) match:title negative:(.*[Tt]hunar.*), center 1
      windowrule = match:title ^(Authentication Required)$, center 1
      windowrule = match:class ^(*)$, idle_inhibit fullscreen
      windowrule = match:title ^(*)$, idle_inhibit fullscreen
      windowrule = match:fullscreen true, idle_inhibit fullscreen
      windowrule = match:tag settings*, float 1
      windowrule = match:class ^([Ff]erdium)$, float 1
      windowrule = match:title ^(Picture-in-Picture)$, float 1
      windowrule = match:class ^(mpv|com.github.rafostar.Clapper)$, float 1
      windowrule = match:title ^(Authentication Required)$, float 1
      windowrule = match:class (codium|codium-url-handler|VSCodium) match:title negative:(.*codium.*|.*VSCodium.*), float 1
      windowrule = match:class ^(com.heroicgameslauncher.hgl)$ match:title negative:(Heroic Games Launcher), float 1
      windowrule = match:class ([Tt]hunar) match:title negative:(.*[Tt]hunar.*), float 1
      windowrule = match:initial_title (Add Folder to Workspace), float 1
      windowrule = match:initial_title (Open Files), float 1
      windowrule = match:initial_title (wants to save), float 1
      windowrule = match:tag polkit*, float 1
      windowrule = match:tag polkit*, center 1
      windowrule = match:tag 1password-prompt*, float 1
      windowrule = match:tag 1password-prompt*, center 1
      windowrule = match:tag 1password-prompt*, pin 1
      windowrule = match:tag 1password-prompt*, min_size 800 600
      windowrule = match:initial_title (Open Files), size 70% 60%
      windowrule = match:initial_title (Add Folder to Workspace), size 70% 60%
      windowrule = match:tag polkit*, size 30% 25%
      windowrule = match:tag 1password-prompt*, size 800 600
      windowrule = match:tag settings*, size 70% 70%
      windowrule = match:class ^([Ff]erdium)$, size 60% 70%
      windowrule = match:tag browser*, opacity 1.0 1.0
      windowrule = match:tag projects*, opacity 0.9 0.8
      windowrule = match:tag im*, opacity 0.94 0.86
      windowrule = match:tag file-manager*, opacity 0.9 0.8
      windowrule = match:tag terminal*, opacity 0.9 0.8
      windowrule = match:tag settings*, opacity 0.9 0.8
      windowrule = match:class ^(gedit|org.gnome.TextEditor|mousepad)$, opacity 0.9 0.8
      windowrule = match:class ^(seahorse)$, opacity 0.9 0.8
      windowrule = match:title ^(Picture-in-Picture)$, opacity 0.95 0.75
      windowrule = match:title ^(Picture-in-Picture)$, pin 1
      windowrule = match:title ^(Picture-in-Picture)$, keep_aspect_ratio 1
      windowrule = match:tag games*, workspace 14 silent
      windowrule = match:tag games*, fullscreen 1
      windowrule = match:tag games*, no_blur 1
      windowrule = match:tag games*, immediate 1
      windowrule = match:tag games*, suppress_event maximize
      windowrule = match:tag games*, suppress_event fullscreen
      windowrule = match:title ^([Ss]urvive)$, tag +sfml
      windowrule = match:title ^([Tt]ower [Dd]efense)$, tag +sfml
      windowrule = match:title ^([Rr]unner)$, tag +sfml
      windowrule = match:tag sfml*, float 1
    '';
  };
}
