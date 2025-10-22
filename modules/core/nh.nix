{
  pkgs,
  host,
  flakeRoot,
  ...
}:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") flakeDir;
in
{
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 5";
    };
    flake = flakeDir;
  };

  environment.systemPackages = with pkgs; [
    nix-output-monitor
    nvd
  ];
}
