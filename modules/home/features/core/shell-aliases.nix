{ host, flakeRoot, lib, ... }:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") flakeDir;
  cleanArgs = import ../../../core/nh-clean-policy.nix;
in
{
  # Common shell aliases shared across fish, zsh, and bash
  # Import this in each shell config via: shellAliases = (import ./shell-aliases.nix { inherit host flakeRoot lib; }).shellAliases;

  shellAliases = {
    # Clear screen
    c = "clear";

    # NixOS rebuild shortcuts
    fr = "nh os switch";
    frb = "nh os boot";
    fu = "nh os switch --update";
    fb = "nh os build";
    fbd = "nix build ${lib.escapeShellArg "${flakeDir}#nixosConfigurations.${host}.config.system.build.toplevel"} --dry-run --no-link";

    # Garbage collection
    ncg = "nh clean all ${cleanArgs}";

    # Better defaults
    # cat = "bat";
    # man = "batman";

    # Eza (better ls)
    ls = "eza --icons --group-directories-first -1";
    ll = "eza --icons -a --group-directories-first -1 --no-user --long";
    la = "eza -lah --icons --grid --group-directories-first";
    tree = "eza --icons --tree --group-directories-first";

    # Custom flake updates
    code-update = "nix flake update vscode-insiders --flake ${lib.escapeShellArg flakeDir} && fr -q";

    # Disk usage
    usage = "ncdu -xt 12";
  };
}
