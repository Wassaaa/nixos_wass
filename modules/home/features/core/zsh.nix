{ host, flakeRoot, ... }:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") flakeDir;
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

    shellAliases = {
      c = "clear";
      fr = "nh os switch --hostname ${host}";
      fb = "nh os boot --hostname ${host}";
      fu = "nh os switch --hostname ${host} --update";
      ncg = "nix-collect-garbage --delete-old && sudo nix-collect-garbage -d && sudo /run/current-system/bin/switch-to-configuration boot";
      cat = "bat";
      man = "batman";
      ls = "eza --icons --group-directories-first -1";
      ll = "eza --icons -a --group-directories-first -1 --no-user --long";
      tree = "eza --icons --tree --group-directories-first";
      code-update = "nix flake update vscode-insiders --flake ${flakeDir} && fr -q";
      usage = "ncdu -xt 12";
    };
  };
}
