{
  browser,
  terminal,
  ...
}:
''
  binds {
        // === System & Overview ===
      Mod+X repeat=false { toggle-overview; }
      Mod+O repeat=false { toggle-overview; }
      Mod+Shift+Slash { show-hotkey-overlay; }

      // === Essential Applications ===
      Mod+Return { spawn "${terminal}"; }
      Mod+W { spawn "${browser}"; }
      Mod+R { spawn "rofi" "-show" "drun"; }
      Mod+E { spawn "emopicker9000"; }
      Mod+C { spawn-sh "niri msg pick-color | grep 'Hex:' | cut -d' ' -f2 | wl-copy"; }

      // === Window Management ===
      Mod+Q { close-window; }
      Mod+Shift+Q { quit; }
      Mod+F { fullscreen-window; }
      Mod+Shift+F { maximize-column; }
      Mod+Shift+Space { toggle-window-floating; }

      // === Focus Navigation (Arrow Keys) ===
      Mod+Left { focus-column-left; }
      Mod+Right { focus-column-right; }
      Mod+Up { focus-window-up; }
      Mod+Down { focus-window-down; }
      Mod+Shift+WheelScrollDown cooldown-ms=150 { focus-column-right; }
      Mod+Shift+WheelScrollUp cooldown-ms=150 { focus-column-left; }

      // === Window Movement (Shift + Arrows) ===
      Mod+Shift+Left { move-column-left; }
      Mod+Shift+Right { move-column-right; }
      Mod+Shift+Up { move-window-up; }
      Mod+Shift+Down { move-window-down; }

      // === Column Navigation ===
      Mod+Home { focus-column-first; }
      Mod+End  { focus-column-last; }
      Mod+Ctrl+Home { move-column-to-first; }
      Mod+Ctrl+End  { move-column-to-last; }

      // === Monitor Navigation ===
      Mod+Ctrl+Left { focus-monitor-left; }
      Mod+Ctrl+Right { focus-monitor-right; }
      Mod+Shift+Ctrl+Left { move-column-to-monitor-left; }
      Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }

      // === Numbered Workspaces (1-9) ===
      Mod+1 { focus-workspace 1; }
      Mod+2 { focus-workspace 2; }
      Mod+3 { focus-workspace 3; }
      Mod+4 { focus-workspace 4; }
      Mod+5 { focus-workspace 5; }
      Mod+6 { focus-workspace 6; }
      Mod+7 { focus-workspace 7; }
      Mod+8 { focus-workspace 8; }
      Mod+9 { focus-workspace 9; }

      // === Move Window to Numbered Workspaces (Shift+Mod+Number) ===
      Mod+Shift+1 { move-column-to-workspace 1; }
      Mod+Shift+2 { move-column-to-workspace 2; }
      Mod+Shift+3 { move-column-to-workspace 3; }
      Mod+Shift+4 { move-column-to-workspace 4; }
      Mod+Shift+5 { move-column-to-workspace 5; }
      Mod+Shift+6 { move-column-to-workspace 6; }
      Mod+Shift+7 { move-column-to-workspace 7; }
      Mod+Shift+8 { move-column-to-workspace 8; }
      Mod+Shift+9 { move-column-to-workspace 9; }

      // === Workspace Navigation (Up/Down with Ctrl) ===
      Mod+Ctrl+Up { focus-workspace-up; }
      Mod+Ctrl+Down { focus-workspace-down; }
      Mod+Ctrl+Alt+Up { move-column-to-workspace-up; }
      Mod+Ctrl+Alt+Down { move-column-to-workspace-down; }

      // === Mouse Wheel Workspace Navigation ===
      Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
      Mod+WheelScrollUp cooldown-ms=150 { focus-workspace-up; }
      Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
      Mod+Ctrl+WheelScrollUp cooldown-ms=150 { move-column-to-workspace-up; }

      // === Column Management (Niri-specific) ===
      Mod+BracketLeft { consume-or-expel-window-left; }
      Mod+BracketRight { consume-or-expel-window-right; }
      Mod+Period { expel-window-from-column; }

      // === Sizing & Layout ===
      Mod+Comma { switch-preset-column-width; }
      Mod+Shift+Comma { switch-preset-window-height; }
      Mod+Ctrl+Comma { reset-window-height; }
      Mod+Minus { set-column-width "-10%"; }
      Mod+Equal { set-column-width "+10%"; }
      Mod+Shift+Minus { set-window-height "-10%"; }
      Mod+Shift+Equal { set-window-height "+10%"; }

      // === Screenshots (using grim + slurp) ===
      Mod+S { spawn "screenshootin"; }
      Mod+Shift+S { spawn "grim" "-g" "$(slurp)" "~/Pictures/Screenshots/$(date +'Screenshot_%Y-%m-%d_%H-%M-%S.png')"; }
      Print { spawn "grim" "~/Pictures/Screenshots/$(date +'Screenshot_%Y-%m-%d_%H-%M-%S.png')"; }
      Ctrl+Print { spawn "grim" "-o" "$(niri msg outputs | jq -r '.[] | select(.focused) | .name')" "~/Pictures/Screenshots/$(date +'Screenshot_%Y-%m-%d_%H-%M-%S.png')"; }
      Alt+Print { spawn "grim" "-g" "$(slurp)" "~/Pictures/Screenshots/$(date +'Screenshot_%Y-%m-%d_%H-%M-%S.png')"; }

      // === System ===
      Mod+V { spawn "rofi" "-modi" "clipboard:clipvault_rofi.sh" "-show" "clipboard" "-show-icons"; }
  }
''
