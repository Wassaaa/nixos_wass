{ host, flakeRoot, ... }:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix")
    browser
    terminal
    ;
in
{
  # Basic niri configuration with essential keybinds
  xdg.configFile."niri/config.kdl".text = ''
    // Niri configuration
    // See https://github.com/YaLTeR/niri/wiki/Configuration:-Overview

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
            click-method "clickfinger"
        }

        mouse {
            natural-scroll
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

    layout {
        gaps 8
        center-focused-column "never"

        preset-column-widths {
            proportion 0.33333
            proportion 0.5
            proportion 0.66667
        }

        default-column-width { proportion 0.5; }

        border {
            width 2
            active-gradient from="#${
              builtins.substring 0 6 (builtins.readFile "${flakeRoot}/.config/stylix/colors")
            }" to="#0C96F9" angle=45
            inactive-color "#657DC2"
        }
    }

    animations {
        slowdown 1.0
    }

    window-rule {
        geometry-corner-radius 10
        clip-to-geometry true
    }

    spawn-at-startup "${terminal}"

    prefer-no-csd

    screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

    hotkey-overlay {
        skip-at-startup
    }

    binds {
        // Essential keybinds for testing

        // Window management
        Mod+Return { spawn "${terminal}"; }
        Mod+Q { close-window; }
        Mod+Shift+Q { quit; }

        // Applications
        Mod+W { spawn "${browser}"; }
        Mod+R { spawn "rofi" "-show" "drun"; }
        Mod+E { spawn "emopicker9000"; }

        // Navigation
        Mod+H     { focus-column-left; }
        Mod+L     { focus-column-right; }
        Mod+J     { focus-window-down; }
        Mod+K     { focus-window-up; }
        Mod+Left  { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Down  { focus-window-down; }
        Mod+Up    { focus-window-up; }

        // Moving windows
        Mod+Shift+H     { move-column-left; }
        Mod+Shift+L     { move-column-right; }
        Mod+Shift+J     { move-window-down; }
        Mod+Shift+K     { move-window-up; }
        Mod+Shift+Left  { move-column-left; }
        Mod+Shift+Right { move-column-right; }
        Mod+Shift+Down  { move-window-down; }
        Mod+Shift+Up    { move-window-up; }

        // Workspaces
        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }

        // Move to workspaces
        Mod+Shift+1 { move-column-to-workspace 1; }
        Mod+Shift+2 { move-column-to-workspace 2; }
        Mod+Shift+3 { move-column-to-workspace 3; }
        Mod+Shift+4 { move-column-to-workspace 4; }
        Mod+Shift+5 { move-column-to-workspace 5; }
        Mod+Shift+6 { move-column-to-workspace 6; }
        Mod+Shift+7 { move-column-to-workspace 7; }
        Mod+Shift+8 { move-column-to-workspace 8; }
        Mod+Shift+9 { move-column-to-workspace 9; }

        // Window sizing
        Mod+Comma  { consume-window-into-column; }
        Mod+Period { expel-window-from-column; }
        Mod+F { maximize-column; }
        Mod+Shift+F { fullscreen-window; }

        // Screenshots
        Mod+S { screenshot; }
        Mod+Shift+S { screenshot-window; }

        // Media keys
        XF86AudioRaiseVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
        XF86AudioLowerVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
        XF86AudioMute        { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
        XF86AudioPlay        { spawn "playerctl" "play-pause"; }
        XF86AudioNext        { spawn "playerctl" "next"; }
        XF86AudioPrev        { spawn "playerctl" "previous"; }

        // Monitor brightness (if applicable)
        XF86MonBrightnessDown { spawn "brightnessctl" "set" "5%-"; }
        XF86MonBrightnessUp   { spawn "brightnessctl" "set" "+5%"; }
    }
  '';

  # Most packages are already available from Hyprland setup
  # Niri will use rofi, waybar, and other tools you already have configured
}
