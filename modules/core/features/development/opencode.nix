{ pkgs, inputs, ... }:
let
  system = pkgs.system;
  opencode = inputs.opencode.packages.${system}.default;
in
{
  environment.systemPackages = [
    opencode
  ];
}
