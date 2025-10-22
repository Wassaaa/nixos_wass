{
  host,
  pkgs,
  flakeRoot,
  ...
}:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix")
    browser
    terminal
    ;
in
{
  home.packages = with pkgs; [ hyprsome ];
  wayland.windowManager.hyprland.settings = {
    bind = [
      "$modifier,Return,exec,${terminal}"
      "$modifier,V,exec,rofi -modi clipboard:clipvault_rofi.sh -show clipboard -show-icons"
      "$modifier,R,exec,rofi-launcher"
      "$modifier SHIFT,W,exec,web-search"
      "$modifier ALT,W,exec,wallsetter"
      "$modifier SHIFT,N,exec,swaync-client -rs"
      "$modifier,W,exec,${browser}"
      "$modifier,E,exec,emopicker9000"
      "$modifier,S,exec,screenshootin"
      "$modifier,D,exec,discord"
      "$modifier,O,exec,obs"
      "$modifier,C,exec,hyprpicker -a"
      "$modifier,G,exec,gamescope-steam"
      "$modifier,T,exec,pypr toggle term"
      "$modifier SHIFT,T,exec,pypr toggle thunar"
      "$modifier,M,exec,pavucontrol"
      "$modifier,Q,killactive,"
      "$modifier,P,exec,pypr toggle volume"
      "$modifier SHIFT,P,pseudo,"
      "$modifier SHIFT,I,togglesplit,"
      "$modifier,F,fullscreen,"
      "$modifier SHIFT,F,togglefloating,"
      "$modifier SHIFT,C,exit,"
      "$modifier SHIFT,left,movewindow,l"
      "$modifier SHIFT,right,movewindow,r"
      "$modifier SHIFT,up,movewindow,u"
      "$modifier SHIFT,down,movewindow,d"
      "$modifier SHIFT,h,movewindow,l"
      "$modifier SHIFT,l,movewindow,r"
      "$modifier SHIFT,k,movewindow,u"
      "$modifier SHIFT,j,movewindow,d"
      "$modifier ALT, left, swapwindow,l"
      "$modifier ALT, right, swapwindow,r"
      "$modifier ALT, up, swapwindow,u"
      "$modifier ALT, down, swapwindow,d"
      "$modifier ALT, 43, swapwindow,l"
      "$modifier ALT, 46, swapwindow,r"
      "$modifier ALT, 45, swapwindow,u"
      "$modifier ALT, 44, swapwindow,d"
      "$modifier,left,movefocus,l"
      "$modifier,right,movefocus,r"
      "$modifier,up,movefocus,u"
      "$modifier,down,movefocus,d"
      "$modifier,h,movefocus,l"
      "$modifier,l,movefocus,r"
      "$modifier,k,movefocus,u"
      "$modifier,j,movefocus,d"
      "$modifier,1,exec,hyprsome workspace 1"
      "$modifier,2,exec,hyprsome workspace 2"
      "$modifier,3,exec,hyprsome workspace 3"
      "$modifier,4,exec,hyprsome workspace 4"
      "$modifier,5,exec,hyprsome workspace 5"
      "$modifier,6,exec,hyprsome workspace 6"
      "$modifier,7,exec,hyprsome workspace 7"
      "$modifier,8,exec,hyprsome workspace 8"
      "$modifier,9,exec,hyprsome workspace 9"

      "$modifier SHIFT,1,exec,hyprsome move 1"
      "$modifier SHIFT,2,exec,hyprsome move 2"
      "$modifier SHIFT,3,exec,hyprsome move 3"
      "$modifier SHIFT,4,exec,hyprsome move 4"
      "$modifier SHIFT,5,exec,hyprsome move 5"
      "$modifier SHIFT,6,exec,hyprsome move 6"
      "$modifier SHIFT,7,exec,hyprsome move 7"
      "$modifier SHIFT,8,exec,hyprsome move 8"
      "$modifier SHIFT,9,exec,hyprsome move 9"

      "$modifier SHIFT,SPACE,movetoworkspace,special"
      "$modifier,SPACE,togglespecialworkspace"
      "$modifier CONTROL,right,workspace,e+1"
      "$modifier CONTROL,left,workspace,e-1"
      "$modifier,mouse_down,exec,hyprsomescroll 1"
      "$modifier,mouse_up,exec,hyprsomescroll -1"
      "ALT,Tab,cyclenext"
      "ALT,Tab,bringactivetotop"
      ",XF86AudioRaiseVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
      ",XF86AudioLowerVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      " ,XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ",XF86AudioPlay, exec, playerctl play-pause"
      ",XF86AudioPause, exec, playerctl play-pause"
      ",XF86AudioNext, exec, playerctl next"
      ",XF86AudioPrev, exec, playerctl previous"
      ",XF86MonBrightnessDown,exec,brightnessctl set 5%-"
      ",XF86MonBrightnessUp,exec,brightnessctl set +5%"
    ];

    bindm = [
      "$modifier, mouse:272, movewindow"
      "$modifier, mouse:273, resizewindow"
    ];
  };
}
