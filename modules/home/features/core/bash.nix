{ host, flakeRoot, ... }:
let
  aliases = import ./shell-aliases.nix { inherit host flakeRoot; };
in
{
  programs.bash = {
    enable = false;
    enableCompletion = true;
    initExtra = ''
      fastfetch
      if [ -f $HOME/.bashrc-personal ]; then
        source $HOME/.bashrc-personal
      fi
    '';
    shellAliases = aliases.shellAliases;
  };
}
