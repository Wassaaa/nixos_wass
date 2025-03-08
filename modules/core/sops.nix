{ config, ... }:
let
  isEd = k: k.type == "ed25519";
  getKeyPath = k: k.path;
  keys = builtins.filter isEd config.services.openssh.hostKeys;
in
{
  sops = {
    age.sshKeyPaths = map getKeyPath keys;
  };
}
