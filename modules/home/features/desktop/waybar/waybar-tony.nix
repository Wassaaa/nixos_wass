{
  pkgs,
  lib,
  host,
  config,
  flakeRoot,
  ...
}: let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") clock24h;
  timeFormat = if clock24h then "%H:%M" else "%I:%M %p";
in
  with lib; {
    # Configure & Theme Waybar (Tony)

    programs.waybar = {
      enable = true;
      package = pkgs.waybar;
      settings = [
        {
          layer = "top";
          position = "top";
          height = 30;
          spacing = 4;

          modules-left = [
            "custom/startmenu"
            "custom/sep"
            "hyprland/workspaces"
            "niri/workspaces"
            "custom/sep"
            "hyprland/window"
            "niri/window"
            "custom/sep"
          ];
          modules-center = [
            #"custom/sep"
            "idle_inhibitor"
            "custom/weather"
            "custom/notification"
            #"custom/sep"
          ];
          modules-right = [
            "custom/sep"
            "tray"
            "custom/sep"
            "pulseaudio"
            #"network"
            "cpu"
            #"memory"
            "clock"
            "custom/sep"
            "custom/power"
          ];

          "hyprland/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
            warp-on-scroll = false;
            format = "{name}";
            persistent-workspaces = {
              "*" = 9;
            };
          };
          "hyprland/window" = {
            max-length = 40;
            seperate-outputs = false;
          };
          "niri/workspaces" = {
            format = "{icon}";
            format-icons = {
              "1" = "1";
              "2" = "2";
              "3" = "3";
              "4" = "4";
              "5" = "5";
              "6" = "6";
              "7" = "7";
              "8" = "8";
              "9" = "9";
              "10" = "10";
            };
          };
          "niri/window" = {
            format = "{title}";
            max-length = 40;
            seperate-outputs = false;
          };
          tray = {
            spacing = 10;
          };
          clock = {
            format = "{:${timeFormat}}";
            format-alt = "{:%Y-%m-%d}";
          };
          cpu = {
            format = "CPU: {usage}%";
            tooltip = false;
          };
          memory = {
            format = "Mem: {used}GiB";
          };
          disk = {
            interval = 60;
            path = "/";
            format = "Disk: {free}";
          };
          battery = {
            states = {
              good = 95;
              warning = 30;
              critical = 15;
            };
            format = "Bat: {capacity}% {icon} {time}";
            format-plugged = "{capacity}% ";
            format-alt = "Bat {capacity}%";
            format-time = "{H}:{M}";
            format-icons = [
              ""
              ""
              ""
              ""
              ""
            ];
          };
          network = {
            format-icons = [
              "󰤯"
              "󰤟"
              "󰤢"
              "󰤥"
              "󰤨"
            ];
            format-ethernet = "{ifname} {ipaddr}";
            format-wifi = "{essid} {signalStrength}% {ipaddr}";
            format-disconnected = "󰤮";
            tooltip = true;
            tooltip-format = "{ifname}\nIPv4: {ipaddr}/{cidr}\nGateway: {gwaddr}\nSSID: {essid}\nSignal: {signalStrength}%";
            on-click = "nmtui";
          };
          "custom/sep" = {
            format = "|";
            interval = 0;
          };
          "idle_inhibitor" = {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
            tooltip = true;
          };
          "custom/startmenu" = {
            format = "";
            tooltip = true;
            "tooltip-format" = "App menu";
            on-click = "rofi -show drun";
          };

          "custom/notification" = {
            tooltip = false;
            format = "{icon} {}";
            format-icons = {
              notification = "<span foreground='red'><sup></sup></span>";
              none = "";
              dnd-notification = "<span foreground='red'><sup></sup></span>";
              dnd-none = "";
              inhibited-notification = "<span foreground='red'><sup></sup></span>";
              inhibited-none = "";
              dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
              dnd-inhibited-none = "";
            };
            return-type = "json";
            exec-if = "which swaync-client";
            exec = "swaync-client -swb";
            on-click = "swaync-client -t";
            escape = true;
          };
          "custom/weather" = {
            return-type = "json";
            exec = "sh -lc 'WEATHER_ICON_STYLE=emoji WEATHER_TOOLTIP_MARKUP=1 ~/.config/waybar/scripts/Weather.py'";
            interval = 600;
            tooltip = true;
          };
          pulseaudio = {
            format = "{icon} {volume}% {format_source}";
            format-bluetooth = "{volume}% {icon} {format_source}";
            format-bluetooth-muted = " {icon} {format_source}";
            format-muted = " {format_source}";
            format-source = " {volume}%";
            format-source-muted = "";
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = [
                ""
                ""
                ""
              ];
            };
            on-click = "pavucontrol";
          };
          "custom/power" = {
            format = " ⏻ ";
            tooltip = false;
            on-click = "sleep 0.1 && wlogout";
          };
        }
      ];
      style = concatStrings [
        ''
          @define-color bg    #1a1b26;
          @define-color fg    #a9b1d6;
          @define-color blk   #32344a;
          @define-color red   #f7768e;
          @define-color grn   #9ece6a;
          @define-color ylw   #e0af68;
          @define-color blu   #7aa2f7;
          @define-color mag   #ad8ee6;
          @define-color cyn   #0db9d7;
          @define-color brblk #444b6a;
          @define-color white #ffffff;

          * {
              font-family: "JetBrainsMono Nerd Font", monospace;
              font-size: 16px;
              font-weight: bold;
          }

          window#waybar {
              background-color: @bg;
              color: @fg;
          }

          #workspaces button {
              padding: 0 6px;
              color: @cyn;
              background: transparent;
              border-bottom: 3px solid @bg;
          }
          #workspaces button.active {
              color: @cyn;
              border-bottom: 3px solid @mag;
          }
          #workspaces button.empty {
              color: @white;
          }
          #workspaces button.empty.active {
              color: @cyn;
              border-bottom: 3px solid @mag;
          }

          #workspaces button.urgent {
              background-color: @red;
          }

          button:hover {
              background: inherit;
              box-shadow: inset 0 -3px #ffffff;
          }

          #clock,
          #custom-sep,
          #battery,
          #cpu,
          #memory,
          #disk,
          #network,
          #tray,
          #pulseaudio,
          #idle_inhibitor,
          #custom-notification,
          #custom-power {
              padding: 0 8px;
              color: @white;
          }
          /* Rounded, raised bottom effect for center/right modules */
          #clock,
          #battery,
          #cpu,
          #memory,
          #disk,
          #network,
          #tray,
          #pulseaudio,
          #idle_inhibitor,
          #custom-notification,
          #custom-power {
              border-bottom-left-radius: 10px;
              border-bottom-right-radius: 10px;
              box-shadow: inset 0 -2px rgba(255,255,255,0.07);
          }
          /* Tighten spacing between the two QS buttons */
          #group-qs_wallpapers { margin: 0; padding: 0; }

          /* Make QS icons match startmenu color and background (bright green) */
          /* Start menu stays bright green; QS icons switch to clock blue (@cyn) */
          #custom-startmenu {
              color: @grn;
              background: transparent;
              font-size: 21px; /* ~30% larger than base 16px */
          }
          #custom-qs_wallpapers_apply,
          #custom-qs_vid_wallpapers_apply {
              color: @cyn; /* match clock color */
              background: transparent;
              font-size: 21px; /* ~30% larger than base 16px */
          }
          /* Prevent QS icons from being clipped; add a tiny internal pad */
          #custom-qs_wallpapers_apply,
          #custom-qs_vid_wallpapers_apply {
              padding: 0 2px;
              min-width: 20px;
          }
          #custom-startmenu { margin-right: 6px; }

          #custom-sep {
              color: @brblk;
          }
          /* Width for gap spacer between QS icons */
          #custom-sep_gap { padding: 0 1px; }
          #custom-sep_gap_left { padding: 0 2px; }

          #clock {
              color: @cyn;
              border-bottom: 4px solid @cyn;
          }

          #battery {
              color: @mag;
              border-bottom: 4px solid @mag;
          }

          #disk {
              color: @ylw;
              border-bottom: 4px solid @ylw;
          }

          #memory {
              color: @mag;
              border-bottom: 4px solid @mag;
          }

          #cpu {
              color: @grn;
              border-bottom: 4px solid @grn;
          }

          #network {
              color: @blu;
              border-bottom: 4px solid @blu;
          }

          #network.disconnected {
              background-color: @red;
          }

            #pulseaudio {
                color: @blu;
                border-bottom: 4px solid @blu;
            }

            /* Center the idle_inhibitor icon within its pill */
            #idle_inhibitor {
                /* Center visually via symmetric padding + fixed min width */
                padding-left: 10px;
                padding-right: 10px;
                min-width: 26px;            /* keep a consistent hit area */
                border-bottom: 4px solid @brblk; /* default raised strip */
                border-bottom-left-radius: 10px;
                border-bottom-right-radius: 10px;
            }
            #idle_inhibitor label {
                margin: 0;                  /* remove any label offset */
                padding: 0;
            }

            #idle_inhibitor.deactivated {
                color: @red;
                border-bottom: 4px solid @red;
            }

            #idle_inhibitor.activated {
                color: @grn;
                border-bottom: 4px solid @grn;
                margin-right: 5px;
            }

          #custom-notification {
              color: @grn; /* default green */
              border-bottom: 4px solid @grn;
          }
          /* Turn red on new alerts */
          #custom-notification.notification,
          #custom-notification.dnd-notification,
          #custom-notification.inhibited-notification {
              color: @red;
              border-bottom: 4px solid @red;
          }
          /* Add subtle raised effect to center modules too */
          #custom-notification,
          #idle_inhibitor {
              box-shadow: inset 0 -3px @brblk;
          }

          #tray {
              background-color: @bg; /* match bar background */
              border-bottom: 4px solid @brblk; /* restore raised strip */
              border-bottom-left-radius: 10px;
              border-bottom-right-radius: 10px;
          }

          #custom-power {
              color: @red;
              border-bottom: 4px solid @red;
          }

        ''
      ];
    };
  }
