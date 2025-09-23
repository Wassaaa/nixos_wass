{ host, ... }:
let
  inherit (import ../../hosts/${host}/variables.nix) gitUsername gitEmail;
in
{
  programs.git = {
    enable = true;
    userName = "${gitUsername}";
    userEmail = "${gitEmail}";

    extraConfig = {
      # Use 1Password SSH signing for commits (optional but recommended)
      commit.gpgsign = false; # Set to true if you want to sign commits with SSH

      # Configure SSH signing (if desired)
      # gpg.format = "ssh";
      # user.signingkey = "ssh-ed25519 AAAA..."; # Your 1Password SSH key

      # Better Git defaults
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;

      # Use 1Password credential helper for HTTPS if needed
      # credential.helper = "!op-git-credential-helper";
    };
  };
}
