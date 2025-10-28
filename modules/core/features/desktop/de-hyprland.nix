{ ... }:
{
  programs.hyprland.enable = true;

  environment.etc."xdg/wayland-sessions/hyprland.desktop".text = ''
    [Desktop Entry]
    Name=Hyprland
    Comment=Hyprland Wayland compositor
    TryExec=Hyprland
    Exec=Hyprland
    Type=Application
  '';
}
