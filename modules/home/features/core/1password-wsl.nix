{ pkgs, ... }: {
  # Install 1Password CLI for WSL
  home.packages = with pkgs; [
    _1password-cli  # 1Password CLI
  ];
  home.shellAliases = {
    ssh = "ssh.exe";
    ssh-add = "ssh-add.exe";
  };
}
