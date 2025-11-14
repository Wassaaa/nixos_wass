{
  host,
  flakeRoot,
  config,
  pkgs,
  ...
}:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix")
    browser
    terminal
    stylixImage
    ;

  # Import modular config parts
  startupConfig = import ./startup.nix { inherit stylixImage flakeRoot; };
  keybindsConfig = import ./keybinds.nix { inherit browser terminal; };
  layoutConfig = import ./layout.nix { inherit config; };
in
{
  # Install niri and X11 compatibility
  home.packages = with pkgs; [
    niri
    xwayland-satellite
    grim
    slurp
    wl-clipboard
    swww
    xdg-desktop-portal-gnome
  ];

  # Niri configuration - modular structure
  xdg.configFile."niri/config.kdl".text = ''
    // Niri Configuration - Modular Setup

    input {
        keyboard {
            xkb {
                layout "us,ee"
                options "grp:alt_caps_toggle"
            }
        }

        touchpad {
            tap
            natural-scroll
            dwt
            dwtp
        }

        mouse {
            accel-speed 0.0
        }
    }

    output "DP-3" {
        mode "2560x1440@144"
        position x=0 y=0
    }

    output "HDMI-A-1" {
        mode "1920x1080@60"
        position x=2560 y=120
    }

    prefer-no-csd

    screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

    ${layoutConfig}

    environment {
        XDG_CURRENT_DESKTOP "niri"
        GTK_USE_PORTAL "1"
        MOZ_ENABLE_WAYLAND "1"
        QT_QPA_PLATFORM "wayland"
        ELECTRON_OZONE_PLATFORM_HINT "wayland"
        NIXOS_OZONE_WL "1"
        TERMINAL "${terminal}"

        // NVIDIA Gaming Optimizations
        __GL_GSYNC_ALLOWED "1"
        __GL_VRR_ALLOWED "1"
        PROTON_ENABLE_NVAPI "1"
        PROTON_HIDE_NVIDIA_GPU "0"
        PROTON_ENABLE_NGX_UPDATER "1"
    }

    ${startupConfig}

    ${keybindsConfig}
  '';

  # XWayland satellite service for X11 app support (Discord, etc.)
  systemd.user.services.xwayland-satellite = {
    Unit = {
      Description = "Xwayland outside Wayland";
      BindsTo = "graphical-session.target";
      After = "graphical-session.target";
    };
    Service = {
      Type = "notify";
      NotifyAccess = "all";
      ExecStart = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
      StandardOutput = "journal";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # XDG Desktop Portal services - for screen sharing, file picker, etc.
  systemd.user.services.xdg-desktop-portal = {
    Unit = {
      Description = "Portal service";
      After = [
        "graphical-session.target"
        "pipewire.service"
      ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "dbus";
      BusName = "org.freedesktop.portal.Desktop";
      ExecStart = "${pkgs.xdg-desktop-portal}/libexec/xdg-desktop-portal";
      Restart = "on-failure";
      Environment = [
        "XDG_CURRENT_DESKTOP=niri"
        "WAYLAND_DISPLAY=wayland-1"
      ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.xdg-desktop-portal-gnome = {
    Unit = {
      Description = "Portal service (GNOME implementation)";
      After = [
        "graphical-session.target"
        "pipewire.service"
        "xdg-desktop-portal.service"
      ];
      PartOf = [ "graphical-session.target" ];
      Requires = [ "pipewire.service" ];
    };
    Service = {
      Type = "dbus";
      BusName = "org.freedesktop.impl.portal.desktop.gnome";
      ExecStart = "${pkgs.xdg-desktop-portal-gnome}/libexec/xdg-desktop-portal-gnome";
      Restart = "on-failure";
      Environment = [
        "XDG_CURRENT_DESKTOP=niri"
      ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.xdg-desktop-portal-gtk = {
    Unit = {
      Description = "Portal service (GTK/GNOME implementation)";
      After = [
        "graphical-session.target"
        "xdg-desktop-portal.service"
      ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "dbus";
      BusName = "org.freedesktop.impl.portal.desktop.gtk";
      ExecStart = "${pkgs.xdg-desktop-portal-gtk}/libexec/xdg-desktop-portal-gtk";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # XDG Desktop Portal configuration
  xdg.configFile."xdg-desktop-portal/portals.conf".text = ''
    [preferred]
    default=gtk
    org.freedesktop.impl.portal.FileChooser=gtk
    org.freedesktop.impl.portal.Screenshot=gnome
    org.freedesktop.impl.portal.ScreenCast=gnome
  '';

  xdg.configFile."xdg-desktop-portal/niri-portals.conf".text = ''
    [preferred]
    default=gtk
    org.freedesktop.impl.portal.FileChooser=gtk
    org.freedesktop.impl.portal.Screenshot=gnome
    org.freedesktop.impl.portal.ScreenCast=gnome
  '';
}
