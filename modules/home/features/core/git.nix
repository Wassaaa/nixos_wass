{host, pkgs, profile, flakeRoot, ...}: let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") gitUsername gitEmail gitSigningKey;
  isWSL = profile == "wsl";
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

      core.sshCommand = if isWSL then "ssh.exe" else "ssh";

      gpg = {
        format = "ssh";
        ssh = {
          # 1. The Program
          program =
            if isWSL
            then "op-ssh-sign-wsl.exe"
            else "${pkgs._1password-gui}/bin/op-ssh-sign";
          allowedSignersFile = "~/.ssh/allowed_signers";
        };
      };
    };
  };

  # Create the file content
  home.file.".ssh/allowed_signers".text = ''
    ${gitEmail} ${gitSigningKey}
  '';
}
