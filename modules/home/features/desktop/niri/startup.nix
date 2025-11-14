{
  stylixImage,
  flakeRoot,
  ...
}:
''
  // === Startup Applications ===
  // Wallpaper with swww
  spawn-at-startup "bash" "-c" "killall -q swww; sleep .5 && swww-daemon && sleep 1 && swww img ${flakeRoot}/${stylixImage}"

  // Clipboard history
  spawn-at-startup "bash" "-c" "wl-paste --watch clipvault store &"

  // System tray & auth
  spawn-at-startup "nm-applet" "--indicator"
  spawn-at-startup "lxqt-policykit-agent"

  // Auto-launch apps
  spawn-at-startup "vesktop"
''
