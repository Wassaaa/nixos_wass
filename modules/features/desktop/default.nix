# Desktop Environment Features
{ pkgs, username, lib, ... }: {
  # Display Manager
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = username;
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
      };
    };
  };

  # Desktop Portals
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal
    ];
    configPackages = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal
    ];
  };

  # GUI App Support
  services.flatpak.enable = true;
  systemd.services.flatpak-repo = {
    wantedBy = ["multi-user.target"];
    path = [pkgs.flatpak];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };

  # Desktop Boot Configuration
  boot.plymouth.enable = true;
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
      configurationLimit = 10;
      default = "saved";
      gfxmodeEfi = "2560x1440";
      theme = lib.mkForce (pkgs.fetchzip {
        url = "https://github.com/AdisonCavani/distro-grub-themes/raw/master/themes/nixos.tar";
        hash = "sha256-ivi68lkV2mypf99BOEnRiTpc4bqupfGJR7Q0Fm898kM=";
        stripRoot = false;
      });
    };
  };

  # Desktop Theming
  stylix.cursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
  };
  stylix.fonts.sizes = {
    desktop = 11;
    popups = 12;
  };
}
