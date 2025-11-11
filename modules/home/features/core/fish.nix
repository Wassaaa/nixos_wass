{ host, flakeRoot, ... }:
let
  aliases = import ./shell-aliases.nix { inherit host flakeRoot; };
in
{
  programs.fish = {
    enable = true;

    shellAliases = aliases.shellAliases;

    # The Fish equivalent of your 'initContent'
    interactiveShellInit = ''
      # Note the 'test' and 'end' keywords
      if test -f $HOME/.config/fish/config.fish.personal
         source $HOME/.config/fish/config.fish.personal
      end
    '';
  };
}
