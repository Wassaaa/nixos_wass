{ pkgs, username, ... }:
{
  services.greetd = {
    enable = true;
    settings.default_session = {
      user = username;
      command = ''
        ${pkgs.tuigreet}/bin/tuigreet \
          --time --remember --remember-session \
          --sessions /etc/xdg/wayland-sessions
      '';
    };
  };
  services.xserver.enable = false;
}
