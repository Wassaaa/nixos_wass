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

      # SSH signing configuration
      gpg = {
        format = "ssh";
        ssh.program = 
          if isWSL
          then "/mnt/c/Users/allar/AppData/Local/1Password/app/8/op-ssh-sign-wsl"
          else "${pkgs._1password-gui}/bin/op-ssh-sign";
      };
      
      # Use Windows SSH for Git operations on WSL
      core.sshCommand = if isWSL then "ssh.exe" else "ssh";
    };
  };
  # Create the allowed signers file
  home.file.".ssh/allowed_signers".text = ''
    ${gitEmail} ${gitSigningKey}
  '';
}
