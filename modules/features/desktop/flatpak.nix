{ pkgs, ... }:
{
  services.flatpak.enable = true;

  # Ensure Flathub repo is added
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };

  # Install VS Code Insiders automatically
  # This runs after the flatpak-repo service
  systemd.services.flatpak-install-vscode = {
    wantedBy = [ "multi-user.target" ];
    after = [ "flatpak-repo.service" ];
    path = [ pkgs.flatpak ];
    script = ''
      # Install VS Code Insiders if not already installed
      if ! flatpak list --app | grep -q "com.visualstudio.code.insiders"; then
        flatpak install -y --noninteractive flathub com.visualstudio.code.insiders
      fi

      # Grant full system access - act like a native app
      flatpak override --user com.visualstudio.code.insiders \
        --filesystem=host \
        --filesystem=/var \
        --filesystem=/tmp \
        --filesystem=/run \
        --filesystem=/etc \
        --socket=wayland \
        --socket=x11 \
        --socket=fallback-x11 \
        --socket=pulseaudio \
        --socket=session-bus \
        --socket=system-bus \
        --share=ipc \
        --share=network \
        --device=all \
        --talk-name=org.freedesktop.Flatpak \
        --talk-name=org.freedesktop.secrets \
        --allow=devel \
        --allow=multiarch || true
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}
