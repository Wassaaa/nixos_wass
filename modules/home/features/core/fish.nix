{ host, flakeRoot, ... }:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") flakeDir;
in
{
  programs.fish = {
    enable = true;

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
      nordvpn-update = "update-nordvpn";

      usage = "ncdu -xt 12";
    };

    # The Fish equivalent of your 'initContent'
    interactiveShellInit = ''
      # Note the 'test' and 'end' keywords
      if test -f $HOME/.config/fish/config.fish.personal
         source $HOME/.config/fish/config.fish.personal
      end
    '';
  };
}
