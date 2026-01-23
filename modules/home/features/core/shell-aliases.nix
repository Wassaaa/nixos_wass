{ host, flakeRoot, ... }:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") flakeDir;
in
{
  # Common shell aliases shared across fish, zsh, and bash
  # Import this in each shell config via: shellAliases = (import ./shell-aliases.nix { inherit host flakeRoot; }).shellAliases;

  shellAliases = {
    # Clear screen
    c = "clear";

    # NixOS rebuild shortcuts
    fr = "nh os switch";
    fb = "nh os boot";
    fu = "nh os switch --update";

    # Garbage collection
    ncg = "nix-collect-garbage --delete-old && sudo nix-collect-garbage -d && sudo /run/current-system/bin/switch-to-configuration boot";

    # Better defaults
    cat = "bat";
    man = "batman";

    # Eza (better ls)
    ls = "eza --icons --group-directories-first -1";
    ll = "eza --icons -a --group-directories-first -1 --no-user --long";
    la = "eza -lah --icons --grid --group-directories-first";
    tree = "eza --icons --tree --group-directories-first";

    # Custom flake updates
    code-update = "nix flake update vscode-insiders --flake ${flakeDir} && fr -q";
    nordvpn-update = "update-nordvpn";
    opencode-update = "nix flake update opencode --flake ${flakeDir} && fr -q";

    # Disk usage
    usage = "ncdu -xt 12";
  };
}
