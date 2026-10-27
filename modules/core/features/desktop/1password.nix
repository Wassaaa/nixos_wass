# 1Password System Integration - Minimal setup for desktop
{ pkgs, username, ... }:
{
  environment.systemPackages = with pkgs; [
    _1password-gui
  ];

  # Enable 1Password system integration
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Integrate with system polkit for browser extension support
    polkitPolicyOwners = [ username ];
  };
}
