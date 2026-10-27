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
      extraArgs = import ./nh-clean-policy.nix;
    };
    flake = flakeDir;
  };

  # Export NH_OS_FLAKE for nh to use automatically
  environment.sessionVariables = {
    NH_FLAKE = flakeDir;
  };
}
