{ pkgs, ... }:
{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
    stdlib = ''
      use_devenv() {
        local devenv_direnvrc
        if ! devenv_direnvrc="$(${pkgs.devenv}/bin/devenv direnvrc)"; then
          log_error "Could not load the devenv direnv integration"
          return 1
        fi
        if ! eval "$devenv_direnvrc"; then
          log_error "Could not initialize the devenv direnv integration"
          return 1
        fi
        use_devenv "$@"
      }
    '';
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
