{
  pkgs,
  inputs,
  username,
  host,
  profile,
  lib,
  flakeRoot,
  ...
}: let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") gitUsername;
  secretsPath = "${flakeRoot}/hosts/${host}/secrets.yaml";
in {
  imports = [inputs.home-manager.nixosModules.home-manager];
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {inherit inputs username host profile flakeRoot;};
    users.${username} = {
      imports = [./../home];
      home = {
        username = "${username}";
        homeDirectory = "/home/${username}";
        stateVersion = "23.11";
      };
      programs.home-manager.enable = true;
    };
  };
  users.mutableUsers = true;
  users.users.${username} = {
    isNormalUser = true;
    description = "${gitUsername}";
    extraGroups = [
      "adbusers"
      "docker"
      "libvirtd"
      "lp"
      "networkmanager"
      "scanner"
      "wheel"
    ];
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;
  };
  nix.settings.allowed-users = ["${username}"];

  sops.secrets.password = lib.mkIf (builtins.pathExists secretsPath) {
    sopsFile = secretsPath;
  };
}
