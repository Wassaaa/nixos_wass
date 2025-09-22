{ config, ... }:
let
  isEd = k: k.type == "ed25519";
  getKeyPath = k: k.path;
  keys = builtins.filter isEd config.services.openssh.hostKeys;
in
{
  sops = {
    age = {
      # Use host SSH keys
      sshKeyPaths = map getKeyPath keys;
      # Also support a persistent age key file managed on the machine
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };
  };
}
