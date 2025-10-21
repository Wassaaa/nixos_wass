{host, pkgs, flakeRoot, ...}: let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") gitUsername gitEmail gitSigningKey;
in
{
  programs.git = {
    enable = true;

    signing = {
      key = "${gitSigningKey}";
      signByDefault = true;
    };

    settings = {
      user.name = "${gitUsername}";
      user.email = "${gitEmail}";
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
  # Create the allowed signers file
  home.file.".ssh/allowed_signers".text = ''
    ${gitEmail} ${gitSigningKey}
  '';
}
