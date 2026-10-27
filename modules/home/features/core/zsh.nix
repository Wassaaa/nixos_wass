{ host, flakeRoot, lib, ... }:
let
  aliases = import ./shell-aliases.nix { inherit host flakeRoot lib; };
in
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = ''
      if [ -f $HOME/.zshrc-personal ]; then
         source $HOME/.zshrc-personal
       fi
    '';

    shellAliases = aliases.shellAliases;
  };
}
