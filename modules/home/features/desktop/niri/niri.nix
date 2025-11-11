{
  host,
  flakeRoot,
  pkgs,
  ...
}:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix")
    browser
    terminal
    ;
in
{
  # Install niri and X11 compatibility
  home.packages = with pkgs; [
    xwayland-satellite # For X11 apps like Discord
    grim
    slurp
    wl-clipboard
  ];

  # Minimal niri config - uses sensible defaults
  xdg.configFile."niri/config.kdl".text = ''
    // Minimal Niri configuration - relying on defaults
    // Customize later as needed

    input {
        keyboard {
            xkb {
                layout "us,ee"
                options "grp:alt_caps_toggle"
            }
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

    environment {
      XDG_CURRENT_DESKTOP "niri"
      GTK_USE_PORTAL "1"
      MOZ_ENABLE_WAYLAND "1"
      QT_QPA_PLATFORM "wayland"
      ELECTRON_OZONE_PLATFORM_HINT "wayland"
      TERMINAL "${terminal}"
    }

    binds {
        // Essential keybinds
        Mod+Return { spawn "${terminal}"; }
        Mod+Q { close-window; }
        Mod+Shift+Q { quit; }
        Mod+W { spawn "${browser}"; }
        Mod+R { spawn "rofi" "-show" "drun"; }
    }
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

  # XDG Desktop Portal configuration for screencasting
  xdg.configFile."xdg-desktop-portal/niri-portals.conf".text = ''
    [preferred]
    default=gtk
    org.freedesktop.impl.portal.Screenshot=gnome
    org.freedesktop.impl.portal.ScreenCast=gnome
  '';
}
