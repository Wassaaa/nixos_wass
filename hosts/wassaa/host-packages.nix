{ ... }:
{
  services.nordvpn.enable = true;
  users.users.wassaa.extraGroups = [ "nordvpn" ];
  systemd.tmpfiles.rules = [
    "d /var/lib/nordvpn/data 0750 nordvpn nordvpn - -"
  ];
  networking.firewall.checkReversePath = "loose";
  services.tailscale.enable = true;
}
