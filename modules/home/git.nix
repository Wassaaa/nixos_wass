{ host, pkgs, ... }:
let
  inherit (import ../../hosts/${host}/variables.nix) gitUsername gitEmail;
in
{
  programs.git = {
    enable = true;
    userName = "${gitUsername}";
    userEmail = "${gitEmail}";

    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHlvV1koUZBNdWRfZ8SvOMgAkA8/Z3X7ZvpsRNULmoF2";
      signByDefault = true;
    };

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;

      # SSH signing configuration
      gpg = {
        format = "ssh";
        ssh.program = "${pkgs._1password-gui}/bin/op-ssh-sign";
      };
    };
  };
}
