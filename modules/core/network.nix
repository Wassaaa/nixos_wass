{
  pkgs,
  host,
  options,
  lib,
  ...
}:
{
  networking = {
    hostName = "${host}";
    networkmanager.enable = if host == "wsl" then false else true;
    timeServers = options.networking.timeServers.default ++ [ "pool.ntp.org" ];
    hosts = {
      "127.0.0.1" = [ "tool-tracker.local" ];
    };

    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
        443
        1194 # NordVPN OpenVPN TCP
        59010
        59011
        8080
      ];
      allowedUDPPorts = [
        1194 # NordVPN OpenVPN UDP
        59010
        59011
      ];
    };
  };

  environment.systemPackages = with pkgs; lib.optionals (host != "wsl") [ networkmanagerapplet ];
}
