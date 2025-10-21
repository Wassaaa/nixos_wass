{ lib, host, flakeRoot, ... }:
let
  hostsDir = "${flakeRoot}/hosts";
  isHost = name: builtins.pathExists (hostsDir + "/${name}/ssh_host_ed25519_key.pub");

  # Get all directories in the hosts directory and put the directory NAMES into a list
  hostDirs = builtins.attrNames (builtins.readDir hostsDir);
  hostNames = builtins.filter (name:
    isHost name
  ) hostDirs;

  hosts = builtins.listToAttrs (map (name: { inherit name; value = {}; }) hostNames);

  pubKey = host: "${flakeRoot}/hosts/${host}/ssh_host_ed25519_key.pub";

in {
  services.openssh = {
    enable = true;
    settings = {
      # Harden
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      # Automatically remove stale sockets
      StreamLocalBindUnlink = "yes";
      # Allow forwarding ports to everywhere
      GatewayPorts = "clientspecified";
    };

    hostKeys = [{
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
  };

  programs.ssh = {
    knownHosts = builtins.mapAttrs (name: _: {
      publicKeyFile = pubKey name;
      extraHostNames = lib.optional (name == host)
        "localhost"; # Alias for localhost if it's the same host
    }) hosts;
  };

  # Passwordless sudo when SSH'ing with keys
  security.pam.sshAgentAuth = {
    enable = true;
    authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
  };
}
