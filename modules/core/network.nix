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

    firewall.enable = true;
  };

  environment.systemPackages = with pkgs; lib.optionals (host != "wsl") [ networkmanagerapplet ];
}
