{ pkgs, ... }: {
  # Install 1Password CLI for WSL (no GUI needed)
  home.packages = with pkgs; [
    _1password-cli  # CLI only
  ];

  # Configure SSH to use Windows 1Password SSH agent via WSL interop
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;  # Disable defaults to avoid future warnings
    matchBlocks = {
      # Default configuration for all hosts
      "*" = {
        identityAgent = "\\\\\.\\pipe\\openssh-ssh-agent";
      };

      # Specific configurations for Git hosting services
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityAgent = "\\\\\.\\pipe\\openssh-ssh-agent";
      };

      "gitlab.com" = {
        hostname = "gitlab.com";
        user = "git";
        identityAgent = "\\\\\.\\pipe\\openssh-ssh-agent";
      };

      "bitbucket.org" = {
        hostname = "bitbucket.org";
        user = "git";
        identityAgent = "\\\\\.\\pipe\\openssh-ssh-agent";
      };
    };
  };  # Set up environment for WSL 1Password integration
  home.sessionVariables = {
    # Use Windows SSH agent through named pipe
    SSH_AUTH_SOCK = "\\.\pipe\openssh-ssh-agent";
  };
}
