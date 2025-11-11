# Core boot configuration - desktop-specific features moved to modules/features/desktop
{
  host,
  lib,
  pkgs,
  flakeRoot,
  ...
}:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") enableDesktop;
  # Check if we're in WSL to avoid boot conflicts
  isWSL = host == "wsl";
in
{
  boot = {
    # Core kernel configuration
    kernelPackages = lib.mkDefault pkgs.linuxPackages_xanmod_latest;

    # Kernel parameters for performance and hardware optimization
    kernelParams = [
      "quiet" # Cleaner boot messages
      "mitigations=off" # Disable CPU vulnerability mitigations for better performance
      "amd_pstate=active" # Enable AMD P-State drivr efor better CPU power management
      "nvidia-drm.modeset=1" # Enable NVIDIA DRM kernel mode setting (required for Wayland)
    ];

    # Basic loader configuration for non-desktop, non-WSL systems
    loader = lib.mkIf (!enableDesktop && !isWSL) {
      grub.enable = lib.mkDefault false;
      systemd-boot.enable = lib.mkDefault true;
      efi.canTouchEfiVariables = lib.mkDefault true;
    };
  };
}
