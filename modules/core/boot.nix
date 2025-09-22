# Core boot configuration - desktop-specific features moved to modules/features/desktop
{ pkgs, lib, config, host, ... }: let
  inherit (import ../../hosts/${host}/variables.nix) enableDesktop;
  # Check if we're in WSL to avoid boot conflicts
  isWSL = host == "wsl";
in {
  boot = {
    # Core kernel configuration
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    
    # Basic loader configuration for non-desktop, non-WSL systems
    loader = lib.mkIf (!enableDesktop && !isWSL) {
      grub.enable = lib.mkDefault false;
      systemd-boot.enable = lib.mkDefault true;
      efi.canTouchEfiVariables = lib.mkDefault true;
    };
  };
}
