{ pkgs, ... }:

{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };

  programs.zsh.initContent = ''
    # Direnv hook for zsh
    eval "$(direnv hook zsh)"
  '';

  # Ensure direnv loads before other shell configurations
  programs.bash.initExtra = ''
    # Direnv hook for bash
    eval "$(direnv hook bash)"
  '';
}
