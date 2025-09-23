# 1Password System Integration - Minimal setup for desktop
{ pkgs, ... }: {
  # Install 1Password system packages
  environment.systemPackages = with pkgs; [
    _1password-gui
    _1password-cli
  ];

  # Enable 1Password system integration
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Integrate with system polkit for browser extension support
    polkitPolicyOwners = [ "wassaa" ];
  };
}
