# 1Password System Integration - Minimal setup for desktop
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    _1password-gui
  ];

  # Enable 1Password system integration
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Integrate with system polkit for browser extension support
    polkitPolicyOwners = [ "wassaa" ];
  };
}
