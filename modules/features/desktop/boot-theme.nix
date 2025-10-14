{ pkgs, lib, ... }:
{
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
}
