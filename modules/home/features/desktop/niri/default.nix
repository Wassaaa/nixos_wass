{ ... }:
{
  imports = [
    ./niri.nix
    ./waybar-service.nix
    # Modular parts are imported within niri.nix:
    # - startup.nix (wallpaper, clipboard, auto-launch apps)
    # - keybinds.nix (all keyboard shortcuts)
    # - layout.nix (gaps, borders, animations, window rules)
  ];
}
