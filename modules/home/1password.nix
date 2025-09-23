{ pkgs, ... }: {
  # Install 1Password GUI for desktop
  home.packages = with pkgs; [
    _1password-gui  # GUI for desktop environments
  ];

  # Configure SSH to use 1Password agent by default
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;  # Disable defaults to avoid future warnings
    matchBlocks = {
      # Default configuration for all hosts
      "*" = {
        identityAgent = "~/.1password/agent.sock";
      };

      # Specific configurations for Git hosting services
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityAgent = "~/.1password/agent.sock";
      };

      "gitlab.com" = {
        hostname = "gitlab.com";
        user = "git";
        identityAgent = "~/.1password/agent.sock";
      };

      "bitbucket.org" = {
        hostname = "bitbucket.org";
        user = "git";
        identityAgent = "~/.1password/agent.sock";
      };
    };
  };

  # Set 1Password SSH agent as the default
  home.sessionVariables = {
    SSH_AUTH_SOCK = "$HOME/.1password/agent.sock";
  };
}
