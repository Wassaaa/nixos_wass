{ pkgs, ... }: {
  # Install 1Password CLI for WSL
  home.packages = with pkgs; [
    _1password  # 1Password CLI
  ];

  # Configure basic SSH settings (Git hosting services)
  programs.ssh = {
    enable = true;
    matchBlocks = {
      # Git hosting services
      "github.com" = {
        hostname = "github.com";
        user = "git";
      };

      "gitlab.com" = {
        hostname = "gitlab.com";
        user = "git";
      };

      "bitbucket.org" = {
        hostname = "bitbucket.org";
        user = "git";
      };
    };
  };

  # Use Windows SSH tools to access 1Password agent
  # The Windows versions can directly communicate with the 1Password agent
  programs.zsh.shellAliases = {
    ssh = "ssh.exe";
    ssh-add = "ssh-add.exe";
  };

  programs.bash.shellAliases = {
    ssh = "ssh.exe";
    ssh-add = "ssh-add.exe";
  };
}
