# ----------------------------------------------------------------------------
# SOPS quick manual (cheat sheet)
#
# New host (run on the host after first boot):
#   1) Save SSH host pubkey into repo
#        sudo cat /etc/ssh/ssh_host_ed25519_key.pub > hosts/HOST/ssh_host_ed25519_key.pub
#   2) Get age recipient for that host
#        ssh-to-age < hosts/HOST/ssh_host_ed25519_key.pub   # -> age1...
#   3) In .sops.yaml add:
#        - &host_HOST age1...
#        creation_rules entry for hosts/HOST/secrets.ya?ml with:
#        - *host_HOST and your *user_... key
#   4) Create/edit secrets
#        sops hosts/HOST/secrets.yaml
#
# User editing key (on your workstation):
#   1) Create age private key from your SSH key
#        mkdir -p ~/.config/sops/age && \
#        ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt
#   2) Get your public age key
#        ssh-to-age < ~/.ssh/id_ed25519.pub   # -> age1...
#   3) In .sops.yaml add:
#        - &user_you age1...
#      Then update any existing secrets to include your key:
#        sops updatekeys hosts/HOST/secrets.yaml
#
# Note: sops-nix uses the machine's SSH host key automatically for decryption
# via sops.age.sshKeyPaths. No extra key file is needed on the host.
# ----------------------------------------------------------------------------
{ config, ... }:
let
  isEd = k: k.type == "ed25519";
  getKeyPath = k: k.path;
  keys = builtins.filter isEd config.services.openssh.hostKeys;
in
{
  sops = {
    age = {
      # Use host SSH keys for decryption at build time
      # This automatically uses /etc/ssh/ssh_host_ed25519_key
      sshKeyPaths = map getKeyPath keys;
    };
  };
}
