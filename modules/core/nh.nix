{
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

  # Export NH_OS_FLAKE for nh to use automatically
  environment.sessionVariables = {
    NH_FLAKE = flakeDir;
  };
}
