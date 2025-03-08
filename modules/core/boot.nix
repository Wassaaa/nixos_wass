{ pkgs, config, lib, ... }:

{
  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    kernelModules = [ "v4l2loopback" ];
    extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    kernel.sysctl = { "vm.max_map_count" = 2147483642; };
    # Appimage Support
    binfmt.registrations.appimage = {
      wrapInterpreterInShell = false;
      interpreter = "${pkgs.appimage-run}/bin/appimage-run";
      recognitionType = "magic";
      offset = 0;
      mask = "\\xff\\xff\\xff\\xff\\x00\\x00\\x00\\x00\\xff\\xff\\xff";
      magicOrExtension = "\\x7fELF....AI\\x02";
    };
    plymouth.enable = true;
    loader = {
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
        # theme = pkgs.fetchzip {
        #   # https://github.com/AdisonCavani/distro-grub-themes
        #   url =
        #     "https://github.com/AdisonCavani/distro-grub-themes/raw/master/themes/nixos.tar";
        #   hash = "sha256-ivi68lkV2mypf99BOEnRiTpc4bqupfGJR7Q0Fm898kM=";
        #   stripRoot = false;
        # };
      };
    };
  };

}
