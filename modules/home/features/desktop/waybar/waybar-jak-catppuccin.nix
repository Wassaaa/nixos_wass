{pkgs, config, ...}: let

  # Inline, improved Cava script packaged via Nix so we don't rely on an external bash file
  waybarCava = pkgs.writeShellScriptBin "WaybarCava" ''
    set -euo pipefail

    # Ensure cava exists
    if ! command -v cava >/dev/null 2>&1; then
      echo "cava not found in PATH" >&2
      exit 1
    fi

    # Characters for vertical bars (0..7)
    bar="▁▂▃▄▅▆▇█"

    # Build sed script that:
    # - strips semicolons (cava RAW ASCII delimiter)
    # - maps digits 0..7 to the corresponding glyph in $bar
    dict="s/;//g"
    bar_length=''${#bar}
    for ((i = 0; i < bar_length; i++)); do
      dict+=";s/$i/''${bar:$i:1}/g"
    done

    # Single-instance guard (kill prior instance cleanly)
    RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/tmp}"
    pidfile="$RUNTIME_DIR/waybar-cava.pid"
    if [ -f "$pidfile" ]; then
      oldpid=$(cat "$pidfile" || true)
      if [ -n "''${oldpid:-}" ] && kill -0 "$oldpid" 2>/dev/null; then
        kill "$oldpid" 2>/dev/null || true
        # Give the old pipeline a moment to exit
        sleep 0.1 || true
      fi
    fi
    echo $$ > "$pidfile"

    # Use a unique temporary config and clean it up on exit
    config_file=$(mktemp "''${RUNTIME_DIR}/waybar-cava.XXXXXX.conf")
    cleanup() {
      rm -f "$config_file" "$pidfile"
    }
    trap cleanup EXIT INT TERM

    cat >"$config_file" <<EOF
    [general]
    framerate = 30
    bars = 10

    [input]
    method = pulse
    source = auto

    [output]
    method = raw
    raw_target = /dev/stdout
    data_format = ascii
    ascii_max_range = 7
    EOF

    # Stream cava output and transform
    exec cava -p "$config_file" | sed -u "$dict"
  '';

  # Use Stylix colors from the current wallpaper theme
  # This replaces the hardcoded Catppuccin palette with dynamic colors
  inherit (config.lib.stylix) colors;

  # Map Stylix base16 colors to Catppuccin-style names for compatibility
  catppuccinColors = {
    rosewater = "#${colors.base06}";
    flamingo = "#${colors.base0F}";
    pink = "#${colors.base0E}";
    mauve = "#${colors.base0E}";
    red = "#${colors.base08}";
    maroon = "#${colors.base08}";
    peach = "#${colors.base09}";
    yellow = "#${colors.base0A}";
    green = "#${colors.base0B}";
    teal = "#${colors.base0C}";
    sky = "#${colors.base0C}";
    sapphire = "#${colors.base0C}";
    blue = "#${colors.base0D}";
    lavender = "#${colors.base0E}";
    text = "#${colors.base05}";
    subtext1 = "#${colors.base04}";
    subtext0 = "#${colors.base04}";
    overlay2 = "#${colors.base03}";
    overlay1 = "#${colors.base03}";
    overlay0 = "#${colors.base03}";
    surface2 = "#${colors.base02}";
    surface1 = "#${colors.base01}";
    surface0 = "#${colors.base01}";
    base = "#${colors.base00}";
    mantle = "#${colors.base00}";
    crust = "#${colors.base00}";
  };
in {
  programs.waybar = {
    enable = true;
    package = pkgs.waybar;

    settings = [
      {
        layer = "top";
        # mode = "dock"; # optional
        exclusive = true;
        passthrough = false;
        position = "top";
        height = 10;
        spacing = 3;
        "fixed-center" = true;
        ipc = true;
        "margin-top" = 4;
        "margin-left" = 8;
        "margin-right" = 8;

        modules-left = [
          "custom/startmenu"
          "custom/separator#line"
          "custom/separator#blank"
          "custom/cava_mviz"
          "custom/separator#blank"
          "custom/separator#line"
          "tray"
          "custom/separator#line"
        ];

        modules-center = [
          "custom/separator#line"
          "hyprland/workspaces#rw"
          "niri/workspaces"
          "custom/separator#line"
        ];

        modules-right = [
          "custom/separator#line"
          "custom/swaync"
          "custom/separator#line"
          "idle_inhibitor"
          "custom/separator#line"
          "clock"
          "custom/separator#line"
          "custom/weather"
          "custom/separator#line"
          "group/audio"
          "custom/separator#line"
          "custom/power"
        ];

        # ---------- Modules (merged from jak-waybar/Modules) ----------
        temperature = {
          interval = 10;
          tooltip = true;
          "hwmon-path" = [
            "/sys/class/hwmon/hwmon1/temp1_input"
            "/sys/class/thermal/thermal_zone0/temp"
          ];
          "critical-threshold" = 82;
          "format-critical" = "{temperatureC}°C {icon}";
          format = "{temperatureC}°C {icon}";
          "format-icons" = ["󰈸"];
          "on-click-right" = "$HOME/.config/hypr/scripts/WaybarScripts.sh --nvtop";
        };

        # backlight module removed per request

        battery = {
          align = 0;
          rotate = 0;
          "full-at" = 100;
          "design-capacity" = false;
          states = {
            good = 95;
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          "format-charging" = " {capacity}%";
          "format-plugged" = "󱘖 {capacity}%";
          "format-alt-click" = "click";
          "format-full" = "{icon} Full";
          "format-alt" = "{icon} {time}";
          "format-icons" = [
            "󰂎"
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
          "format-time" = "{H}h {M}min";
          tooltip = true;
          "tooltip-format" = "{timeTo} {power}w";
          "on-click-middle" = "$HOME/.config/hypr/scripts/ChangeBlur.sh";
          "on-click-right" = "$HOME/.config/hypr/scripts/Wlogout.sh";
        };

        bluetooth = {
          format = " ";
          "format-disabled" = "󰂳";
          "format-connected" = "󰂱 {num_connections}";
          "tooltip-format" = " {device_alias}";
          "tooltip-format-connected" = "{device_enumerate}";
          "tooltip-format-enumerate-connected" = " {device_alias} 󰂄{device_battery_percentage}%";
          tooltip = true;
          "on-click" = "blueman-manager";
        };

        clock = {
          interval = 1;
          format = " {:%I:%M %p}";
          "format-alt" = " {:%H:%M   %Y, %d %B, %A}";
          "tooltip-format" = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "year";
            "mode-mon-col" = 3;
            "weeks-pos" = "right";
            "on-scroll" = 1;
            format = {
              months = "<span color='#ffead3'><b>{}</b></span>";
              days = "<span color='#ecc6d9'><b>{}</b></span>";
              weeks = "<span color='#99ffdd'><b>W{:%V}</b></span>";
              weekdays = "<span color='#ffcc66'><b>{}</b></span>";
              today = "<span color='#ff6699'><b><u>{}</u></b></span>";
            };
          };
          actions = {
            "on-click-right" = "mode";
            "on-click-forward" = "tz_up";
            "on-click-backward" = "tz_down";
            "on-scroll-up" = "shift_up";
            "on-scroll-down" = "shift_down";
          };
        };

        cpu = {
          format = "{usage}% 󰍛";
          interval = 1;
          "min-length" = 5;
          "format-alt-click" = "click";
          "format-alt" = "{icon0}{icon1}{icon2}{icon3} {usage:>2}% 󰍛";
          "format-icons" = [
            "▁"
            "▂"
            "▃"
            "▄"
            "▅"
            "▆"
            "▇"
            "█"
          ];
          "on-click-right" = "gnome-system-monitor";
        };

        disk = {
          interval = 30;
          path = "/";
          format = "{percentage_used}% 󰋊";
          "tooltip-format" = "{used} used out of {total} on {path} ({percentage_used}%)";
        };

        "hyprland/window" = {
          format = "{}";
          "max-length" = 25;
          "separate-outputs" = true;
          "offscreen-css" = true;
          "offscreen-css-text" = "(inactive)";
          rewrite = {
            "(.*) — Mozilla Firefox" = " $1";
            "(.*) - fish" = "> [$1]";
            "(.*) - zsh" = "> [$1]";
          };
        };

        idle_inhibitor = {
          tooltip = true;
          "tooltip-format-activated" = "Idle_inhibitor active";
          "tooltip-format-deactivated" = "Idle_inhibitor not active";
          format = "{icon}";
          # Requested change: coffee mug icon for both states
          "format-icons" = {
            activated = " ";
            deactivated = " ";
          };
        };

        "keyboard-state" = {
          capslock = true;
          format = {
            numlock = "N {icon}";
            capslock = "󰪛 {icon}";
          };
          "format-icons" = {
            locked = "";
            unlocked = "";
          };
        };

        memory = {
          interval = 10;
          format = "{used:0.1f}G 󰾆";
          "format-alt" = "{percentage}% 󰾆";
          "format-alt-click" = "click";
          tooltip = true;
          "tooltip-format" = "{used:0.1f}GB/{total:0.1f}G";
          "on-click-right" = "$HOME/.config/hypr/scripts/WaybarScripts.sh --btop";
        };

        network = {
          format = "{ifname}";
          "format-wifi" = "{icon}";
          "format-ethernet" = "󰌘";
          "format-disconnected" = "󰌙";
          "tooltip-format" = "{ipaddr}  {bandwidthUpBits}  {bandwidthDownBits}";
          "format-linked" = "󰈁 {ifname} (No IP)";
          "tooltip-format-wifi" = "{essid} {icon} {signalStrength}%";
          "tooltip-format-ethernet" = "{ifname} 󰌘";
          "tooltip-format-disconnected" = "󰌙 Disconnected";
          "max-length" = 30;
          "format-icons" = [
            "󰤯"
            "󰤟"
            "󰤢"
            "󰤥"
            "󰤨"
          ];
          "on-click-right" = "$HOME/.config/hypr/scripts/WaybarScripts.sh --nmtui";
        };

        "network#speed" = {
          interval = 1;
          format = "{ifname}";
          "format-wifi" = "{icon}  {bandwidthUpBytes}  {bandwidthDownBytes}";
          "format-ethernet" = "󰌘  {bandwidthUpBytes}  {bandwidthDownBytes}";
          "format-disconnected" = "󰌙";
          "tooltip-format" = "{ipaddr}";
          "format-linked" = "󰈁 {ifname} (No IP)";
          "tooltip-format-wifi" = "{essid} {icon} {signalStrength}%";
          "tooltip-format-ethernet" = "{ifname} 󰌘";
          "tooltip-format-disconnected" = "󰌙 Disconnected";
          "min-length" = 24;
          "max-length" = 24;
          "format-icons" = [
            "󰤯"
            "󰤟"
            "󰤢"
            "󰤥"
            "󰤨"
          ];
        };

        "power-profiles-daemon" = {
          format = "{icon} ";
          "tooltip-format" = "Power profile: {profile}\nDriver: {driver}";
          tooltip = true;
          "format-icons" = {
            default = "";
            performance = "";
            balanced = "";
            "power-saver" = "";
          };
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          "format-bluetooth" = "{icon} 󰂰 {volume}%";
          "format-muted" = "󰖁";
          "format-icons" = {
            headphone = "";
            "hands-free" = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [
              ""
              ""
              "󰕾"
              ""
            ];
            "ignored-sinks" = ["Easy Effects Sink"];
          };
          "scroll-step" = 5.0;
          "on-click" = "$HOME/.config/hypr/scripts/Volume.sh --toggle";
          "on-click-right" = "pavucontrol -t 3";
          "on-scroll-up" = "$HOME/.config/hypr/scripts/Volume.sh --inc";
          "on-scroll-down" = "$HOME/.config/hypr/scripts/Volume.sh --dec";
          "tooltip-format" = "{icon} {desc} | {volume}%";
          "smooth-scrolling-threshold" = 1;
        };

        "pulseaudio#microphone" = {
          format = "{format_source}";
          "format-source" = " {volume}%";
          "format-source-muted" = "";
          "on-click" = "$HOME/.config/hypr/scripts/Volume.sh --toggle-mic";
          "on-click-right" = "pavucontrol -t 4";
          "on-scroll-up" = "$HOME/.config/hypr/scripts/Volume.sh --mic-inc";
          "on-scroll-down" = "$HOME/.config/hypr/scripts/Volume.sh --mic-dec";
          "tooltip-format" = "{source_desc} | {source_volume}%";
          "scroll-step" = 5;
        };

        tray = {
          "icon-size" = 16;
          spacing = 4;
        };

        # ---------- Workspaces variants (from ModulesWorkspaces) ----------
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
        "hyprland/workspaces#rw" = {
          "disable-scroll" = true;
          "all-outputs" = true;
          "warp-on-scroll" = false;
          "sort-by-number" = true;
          "show-special" = false;
          "on-click" = "activate";
          "on-scroll-up" = "hyprctl dispatch workspace e+1";
          "on-scroll-down" = "hyprctl dispatch workspace e-1";
          "persistent-workspaces" = {
            "*" = 1;
          };
          format = "{icon} {windows}";
          "format-window-separator" = " ";
          "window-rewrite-default" = " ";
          "window-rewrite" = {
            "title<.*amazon.*>" = " ";
            "title<.*reddit.*>" = " ";
            "class<firefox|org.mozilla.firefox|librewolf|floorp|mercury-browser|[Cc]achy-browser>" = " ";
            "class<zen>" = "󰰷 ";
            "class<waterfox|waterfox-bin>" = " ";
            "class<microsoft-edge>" = " ";
            "class<Chromium|Thorium|[Cc]hrome>" = " ";
            "class<brave-browser>" = "🦁 ";
            "class<tor browser>" = " ";
            "class<firefox-developer-edition>" = "🦊 ";
            "class<kitty|konsole>" = " ";
            "class<kitty-dropterm>" = " ";
            "class<com.mitchellh.ghostty>" = " 󰊠";
            "class<org.wezfurlong.wezterm>" = " ";
            "class<Warp|warp|dev.warp.Warp|warp-terminal>" = "󰰭 ";
            "class<[Tt]hunderbird|[Tt]hunderbird-esr>" = " ";
            "class<eu.betterbird.Betterbird>" = " ";
            "title<.*gmail.*>" = "󰊫 ";
            "class<[Tt]elegram-desktop|org.telegram.desktop|io.github.tdesktop_x64.TDesktop>" = " ";
            "class<discord|discord-canary|[Ww]ebcord|[Vv]esktop|com.discordapp.Discord|dev.vencord.Vesktop>" = " ";
            "title<.*whatsapp.*>" = " ";
            "title<.*zapzap.*>" = " ";
            "title<.*messenger.*>" = " ";
            "title<.*facebook.*>" = " ";
            "class<[Ss]ignal|signal-desktop|org.signal.Signal>" = "󰍩 ";
            "title<.*Signal.*>" = "󰍩 ";
            "title<.*ChatGPT.*>" = "󰚩 ";
            "title<.*deepseek.*>" = "󰚩 ";
            "title<.*qwen.*>" = "󰚩 ";
            "class<subl>" = "󰅳 ";
            "class<slack>" = " ";
            "class<mpv>" = " ";
            "class<celluloid|Zoom>" = " ";
            "class<Cider>" = "󰎆 ";
            "title<.*Picture-in-Picture.*>" = " ";
            "title<.*youtube.*>" = " ";
            "class<vlc>" = "󰕼 ";
            "class<[Kk]denlive|org.kde.kdenlive>" = "🎬 ";
            "title<.*Kdenlive.*>" = "🎬 ";
            "title<.*cmus.*>" = " ";
            "class<[Ss]potify>" = " ";
            "class<virt-manager>" = " ";
            "class<.virt-manager-wrapped>" = " ";
            "class<remote-viewer|virt-viewer>" = " ";
            "class<virtualbox manager>" = "💽 ";
            "title<virtualbox>" = "💽 ";
            "class<remmina|org.remmina.Remmina>" = "🖥️ ";
            "class<VSCode|code-url-handler|code-oss|codium|codium-url-handler|VSCodium>" = "󰨞 ";
            "class<dev.zed.Zed>" = "󰵁";
            "class<codeblocks>" = "󰅩 ";
            "title<.*github.*>" = " ";
            "class<mousepad>" = " ";
            "class<libreoffice-writer>" = " ";
            "class<libreoffice-startcenter>" = "󰏆 ";
            "class<libreoffice-calc>" = " ";
            "title<.*nvim ~.*>" = " ";
            "title<.*vim.*>" = " ";
            "title<.*nvim.*>" = " ";
            "title<.*Discord.*>" = " ";
            "title<.*figma.*>" = " ";
            "title<.*jira.*>" = " ";
            "class<jetbrains-idea>" = " ";
            "class<obs|com.obsproject.Studio>" = " ";
            "class<polkit-gnome-authentication-agent-1>" = "󰒃 ";
            "class<nwg-look>" = " ";
            "class<[Pp]avucontrol|org.pulseaudio.pavucontrol>" = "󱡫 ";
            "class<steam>" = " ";
            "class<thunar|nemo>" = "󰝰 ";
            "class<Gparted>" = "";
            "class<gimp>" = " ";
            "class<emulator>" = "📱 ";
            "class<android-studio>" = " ";
            "class<org.pipewire.Helvum>" = "󰓃";
            "class<localsend>" = "";
            "class<PrusaSlicer|UltiMaker-Cura|OrcaSlicer>" = "󰹛";

            "class<[Bb]ox[Bb]uddy|io.github.dvlv.boxbuddy|io.github.dvlv.BoxBuddy>" = " ";
            "title<.*BoxBuddy.*>" = " ";

            # qs-* apps
            "title<Hyprland Keybinds>" = " ";
            "title<Niri Keybinds>" = " ";
            "title<BSPWM Keybinds>" = " ";
            "title<DWM Keybinds>" = " ";
            "title<Emacs Leader Keybinds>" = " ";
            "title<Kitty Configuration>" = " ";
            "title<WezTerm Configuration>" = " ";
            "title<Yazi Configuration>" = " ";
            "title<Cheatsheets Viewer>" = " ";
            "title<Documentation Viewer>" = " ";
            "title<^Wallpapers$>" = " ";
            "title<^Video Wallpapers$>" = " ";
            "title<^qs-wlogout$>" = " ";
          };
        };

        # ---------- Groups (from ModulesGroups) ----------
        "group/app_drawer" = {
          orientation = "inherit";
          drawer = {
            "transition-duration" = 500;
            "children-class" = "custom/menu";
            "transition-left-to-right" = true;
          };
          modules = [
            "custom/menu"
            "custom/light_dark"
            "custom/file_manager"
            "custom/tty"
            "custom/browser"
            "custom/settings"
          ];
        };

        "group/mobo_drawer" = {
          orientation = "inherit";
          drawer = {
            "transition-duration" = 500;
            "children-class" = "cpu";
            "transition-left-to-right" = true;
          };
          modules = [
            "temperature"
            "cpu"
            "power-profiles-daemon"
            "memory"
            "disk"
          ];
        };

        "group/laptop" = {
          orientation = "inherit";
          modules = ["battery"];
        };

        "group/audio" = {
          orientation = "inherit";
          drawer = {
            "transition-duration" = 500;
            "children-class" = "pulseaudio";
            "transition-left-to-right" = true;
          };
          modules = [
            "pulseaudio"
            "pulseaudio#microphone"
          ];
        };

        "group/status" = {
          orientation = "inherit";
          drawer = {
            "transition-duration" = 500;
            "children-class" = "custom/power";
            "transition-left-to-right" = false;
          };
          modules = [
            "custom/power"
            "custom/lock"
            "keyboard-state"
          ];
        };

        # ---------- Custom modules (from ModulesCustom) ----------
        "custom/weather" = {
          return-type = "json";
          exec = "sh -lc 'WEATHER_ICON_STYLE=emoji WEATHER_TOOLTIP_MARKUP=1 ~/.config/waybar/scripts/Weather.py'";
          interval = 600;
          tooltip = true;
        };

        "custom/file_manager" = {
          format = " ";
          "on-click" = "$HOME/.config/hypr/scripts/WaybarScripts.sh --files";
          tooltip = true;
          "tooltip-format" = "File Manager";
        };
        "custom/tty" = {
          format = " ";
          "on-click" = "$HOME/.config/hypr/scripts/WaybarScripts.sh --term";
          tooltip = true;
          "tooltip-format" = "Launch Terminal";
        };
        "custom/browser" = {
          format = " ";
          "on-click" = "xdg-open https://";
          tooltip = true;
          "tooltip-format" = "Launch Browser";
        };
        "custom/settings" = {
          format = " ";
          "on-click" = "$HOME/.config/hypr/scripts/Kool_Quick_Settings.sh";
          tooltip = true;
          "tooltip-format" = "Launch KooL Hyprland Settings Menu";
        };
        "custom/qs_wallpapers_apply" = {
          # Image wallpaper apply (qs-wallpapers-apply)
          format = " ";
          "on-click" = "qs-wallpapers-apply";
          tooltip = true;
          "tooltip-format" = "Set wallpaper";
        };
        "custom/qs_vid_wallpapers_apply" = {
          # Video wallpaper apply (qs-vid-wallpapers-apply)
          format = " ";
          "on-click" = "qs-vid-wallpapers-apply";
          tooltip = true;
          "tooltip-format" = "Set video wallpaper";
        };
        "custom/cycle_wall" = {
          format = " ";
          "on-click" = "$HOME/.config/hypr/UserScripts/WallpaperSelect.sh";
          "on-click-right" = "$HOME/.config/hypr/UserScripts/WallpaperRandom.sh";
          "on-click-middle" = "$HOME/.config/hypr/scripts/WaybarStyles.sh";
          tooltip = true;
          "tooltip-format" = "Left Click: Wallpaper Menu\nMiddle Click: Random wallpaper\nRight Click: Waybar Styles Menu";
        };
        "custom/hint" = {
          format = "󰺁 HINT!";
          "on-click" = "$HOME/.config/hypr/scripts/KeyHints.sh";
          "on-click-right" = "$HOME/.config/hypr/scripts/KeyBinds.sh";
          tooltip = true;
          "tooltip-format" = "Left Click: Quick Tips\nRight Click: Keybinds";
        };
        "custom/dot_update" = {
          format = " 󰁈 ";
          "on-click" = "$HOME/.config/hypr/scripts/KooLsDotsUpdate.sh";
          tooltip = true;
          "tooltip-format" = "Check KooL Dots update\nIf available";
        };
        "custom/hypridle" = {
          format = "󱫗 ";
          "return-type" = "json";
          escape = true;
          "exec-on-event" = true;
          interval = 60;
          exec = "$HOME/.config/hypr/scripts/Hypridle.sh status";
          "on-click" = "$HOME/.config/hypr/scripts/Hypridle.sh toggle";
          "on-click-right" = "hyprlock";
        };
        "custom/light_dark" = {
          format = "󰔎 ";
          "on-click" = "$HOME/.config/hypr/scripts/DarkLight.sh";
          "on-click-right" = "$HOME/.config/hypr/scripts/WaybarStyles.sh";
          "on-click-middle" = "$HOME/.config/hypr/UserScripts/WallpaperSelect.sh";
          tooltip = true;
          "tooltip-format" = "Left Click: Switch Dark-Light Themes\nMiddle Click: Wallpaper Menu\nRight Click: Waybar Styles Menu";
        };
        "custom/lock" = {
          format = "󰌾";
          "on-click" = "$HOME/.config/hypr/scripts/LockScreen.sh";
          tooltip = true;
          "tooltip-format" = "󰷛 Screen Lock";
        };
        "custom/menu" = {
          format = "  ";
          "on-click" = "pkill rofi || rofi -show drun -modi run,drun,filebrowser,window";
          "on-click-middle" = "$HOME/.config/hypr/UserScripts/WallpaperSelect.sh";
          "on-click-right" = "$HOME/.config/hypr/scripts/WaybarLayout.sh";
          tooltip = true;
          "tooltip-format" = "Left Click: Rofi Menu\nMiddle Click: Wallpaper Menu\nRight Click: Waybar Layout Menu";
        };
        "custom/startmenu" = {
          tooltip = true;
          "tooltip-format" = "App menu";
          format = "";
          on-click = "rofi -show drun";
        };

        # Integrated CAVA visualizer using the inline script above
        "custom/cava_mviz" = {
          exec = "${waybarCava}/bin/WaybarCava";
          format = "<span color='#a6e3a1'>[</span> {} <span color='#a6e3a1'>]</span>";
        };

        "custom/playerctl" = {
          format = "<span>{}</span>";
          "return-type" = "json";
          "max-length" = 25;
          exec = "playerctl -a metadata --format '{\"text\": \"{{artist}}  {{markup_escape(title)}}\", \"tooltip\": \"{{playerName}} : {{markup_escape(title)}}\", \"alt\": \"{{status}}\", \"class\": \"{{status}}\"}' -F";
          "on-click-middle" = "playerctl play-pause";
          "on-click" = "playerctl previous";
          "on-click-right" = "playerctl next";
          "scroll-step" = 5.0;
          "on-scroll-up" = "$HOME/.config/hypr/scripts/Volume.sh --inc";
          "on-scroll-down" = "$HOME/.config/hypr/scripts/Volume.sh --dec";
          "smooth-scrolling-threshold" = 1;
        };

        "custom/power" = {
          format = " ⏻ ";
          "on-click" = "sleep 0.1 && wlogout";
          tooltip = false;
        };
        "custom/reboot" = {
          format = "󰜉";
          "on-click" = "systemctl reboot";
          tooltip = true;
          "tooltip-format" = "Left Click: Reboot";
        };
        "custom/quit" = {
          format = "󰗼";
          "on-click" = "hyprctl dispatch exit";
          tooltip = true;
          "tooltip-format" = "Left Click: Exit Hyprland";
        };

        "custom/swaync" = {
          tooltip = true;
          "tooltip-format" = "Left Click: Launch Notification Center\nRight Click: Do not Disturb";
          format = "{} {icon} ";
          "format-icons" = {
            notification = "<span foreground='red'><sup></sup></span>";
            none = "";
            "dnd-notification" = "<span foreground='red'><sup></sup></span>";
            "dnd-none" = "";
            "inhibited-notification" = "<span foreground='red'><sup></sup></span>";
            "inhibited-none" = "";
            "dnd-inhibited-notification" = "<span foreground='red'><sup></sup></span>";
            "dnd-inhibited-none" = "";
          };
          "return-type" = "json";
          "exec-if" = "which swaync-client";
          exec = "swaync-client -swb";
          "on-click" = "systemctl --user start swaync.service; swaync-client -t";
          "on-click-right" = "systemctl --user start swaync.service; swaync-client -d";
          escape = true;
        };

        # Separators
        "custom/separator#dot" = {
          format = "";
          interval = "once";
          tooltip = false;
        };
        "custom/separator#dot-line" = {
          format = "";
          interval = "once";
          tooltip = false;
        };
        "custom/separator#line" = {
          format = "|";
          interval = "once";
          tooltip = false;
        };
        "custom/separator#blank" = {
          format = "";
          interval = "once";
          tooltip = false;
        };
        "custom/separator#blank_2" = {
          format = "  ";
          interval = "once";
          tooltip = false;
        };
        "custom/separator#blank_3" = {
          format = "   ";
          interval = "once";
          tooltip = false;
        };
      }
    ];

    # Consolidated style (Catppuccin Mocha) inlined
    style = let
      c = catppuccinColors;
    in ''
      @define-color rosewater ${c.rosewater};
      @define-color flamingo  ${c.flamingo};
      @define-color pink      ${c.pink};
      @define-color mauve     ${c.mauve};
      @define-color red       ${c.red};
      @define-color maroon    ${c.maroon};
      @define-color peach     ${c.peach};
      @define-color yellow    ${c.yellow};
      @define-color green     ${c.green};
      @define-color teal      ${c.teal};
      @define-color sky       ${c.sky};
      @define-color sapphire  ${c.sapphire};
      @define-color blue      ${c.blue};
      @define-color lavender  ${c.lavender};
      @define-color text      ${c.text};
      @define-color subtext1  ${c.subtext1};
      @define-color subtext0  ${c.subtext0};
      @define-color overlay2  ${c.overlay2};
      @define-color overlay1  ${c.overlay1};
      @define-color overlay0  ${c.overlay0};
      @define-color surface2  ${c.surface2};
      @define-color surface1  ${c.surface1};
      @define-color surface0  ${c.surface0};
      @define-color base      ${c.base};
      @define-color mantle    ${c.mantle};
      @define-color crust     ${c.crust};

      * {
        font-family: "JetBrainsMono Nerd Font";
        font-weight: bold;
        min-height: 0;
        font-size: 95%;
        font-feature-settings: '"zero", "ss01", "ss02", "ss03", "ss04", "ss05", "cv31"';
      }

      window#waybar {
        background-color: rgba(30, 30, 46, 0.95);
        border-radius: 12px;
      }

      tooltip {
        background: @base;
        opacity: 1;
        border-radius: 10px;
        border-width: 2px;
        border-style: solid;
        border-color: @sapphire;
      }
      tooltip label { color: @blue; }

      /* Extra spacing between NixOS start menu and CAVA */
      #custom-startmenu { margin-left: 8px; margin-right: 8px; font-size: 110%; }
      #custom-cava_mviz { margin-left: 4px; }

      #taskbar button, #workspaces button {
        color: @surface2;
        background-color: transparent;
        padding-top: 4px;
        padding-bottom: 4px;
        padding-right: 6px;
        padding-left: 4px;
      }
      #taskbar button.active { color: @maroon; }
      #workspaces button.active { color: @green; }
      #taskbar button.focused, #workspaces button.focused {
        color: @rosewater;
        background: transparent;
        border-radius: 15px;
      }
      #workspaces button.urgent {
        color: #11111b;
        background: transparent;
        border-radius: 15px;
      }
      #taskbar button:hover, #workspaces button:hover {
        background: transparent;
        color: @flamingo;
        border-radius: 15px;
      }
      /* Workspaces colors: inactive= @sapphire (pale blue), active= @green, empty= @red */
      #workspaces button { color: @sapphire; }
      #workspaces button.empty { color: @red; }

      #backlight,
      #backlight-slider,
      #battery,
      #bluetooth,
      #clock,
      #cpu,
      #disk,
      #idle_inhibitor,
      #keyboard-state,
      #memory,
      #mode,
      #mpris,
      #network,
      #power-profiles-daemon,
      #pulseaudio,
      #pulseaudio-slider,
      #taskbar button,
      #taskbar,
      #temperature,
      #tray,
      #window,
      #wireplumber,
      #workspaces,
      #custom-backlight,
      #custom-browser,
      #custom-cava_mviz,
      #custom-cycle_wall,
      #custom-dot_update,
      #custom-file_manager,
      #custom-keybinds,
      #custom-keyboard,
      #custom-light_dark,
      #custom-lock,
      #custom-hint,
      #custom-hypridle,
      #custom-menu,
      #custom-playerctl,
      #custom-power_vertical,
      #custom-power,
      #custom-quit,
      #custom-reboot,
      #custom-settings,
      #custom-spotify,
      #custom-swaync,
      #custom-tty,
      #custom-updater,
      #custom-weather,
      #custom-weather.clearNight,
      #custom-weather.cloudyFoggyDay,
      #custom-weather.cloudyFoggyNight,
      #custom-weather.default,
      #custom-weather.rainyDay,
      #custom-weather.rainyNight,
      #custom-weather.severe,
      #custom-weather.showyIcyDay,
      #custom-weather.snowyIcyNight,
      #custom-weather.sunnyDay {
        opacity: 1;
        padding-top: 4px;
        padding-bottom: 4px;
        padding-right: 6px;
        padding-left: 6px;
      }

      #idle_inhibitor.activated { color: @text; }
      #idle_inhibitor.deactivated { color: @text; }
      #mpris { color: @text; }
      #battery { color: @text; padding-left: 15px; border-radius: 15px 0 0 15px; }
      @keyframes blink { to { background-color: #ffffff; color: #333333; } }
      #battery.critical:not(.charging) {
        color: #f53c3c;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }
      #custom-lock, #custom-power { color: @red; border-radius: 15px; font-weight: bolder; padding-left: 1px; margin-right: 8px; }
      #network { background-color: transparent; color: @text; }
      #backlight { color: @text; }
      #custom-weather { color: @text; border-radius: 15px; background-color: transparent; }
      #custom-menu { color: #89b4fa; }
      #pulseaudio { background-color: transparent; color: @text; }
      #clock, #clock-calender { color: @text; background-color: transparent; }
      /* Use the same color as clock for these icons */
      #custom-qs_wallpapers_apply,
      #custom-qs_vid_wallpapers_apply { color: @text; }

      /* Focused window title */
      #window { color: @lavender; }
      /* When offscreen (offscreen-css = true) */
      #window.offscreen { color: @overlay1; }
      /* Subtle hover effect */
      #window:hover { color: @rosewater; transition: color 120ms ease-in-out; }

      /* Playerctl track text */
      #custom-playerctl { color: @lavender; }
      #custom-playerctl:hover { color: @rosewater; transition: color 120ms ease-in-out; }

      /* Start menu and notifications in green; turn red on new alerts */
      #custom-startmenu { color: @green; }
      #custom-swaync { color: @green; }
      #custom-swaync.notification,
      #custom-swaync.dnd-notification,
      #custom-swaync.inhibited-notification { color: @red; }
      /* Group drawer button color */
      #group-mobo_drawer { color: @green; }

      #backlight-slider slider, #pulseaudio-slider slider {
        min-height: 7px; min-width: 15px; opacity: 0; background-color: @text; border-radius: 3px; box-shadow: 1px 5px 6px 1px #272727;
      }
      #backlight-slider trough, #pulseaudio-slider trough {
        min-height: 100px; min-width: 7px; border-radius: 5px; background-color: @surface0;
      }
      #backlight-slider highlight, #pulseaudio-slider highlight { min-width: 5px; border-radius: 5px; background-color: @blue; }
    '';
  };
}
