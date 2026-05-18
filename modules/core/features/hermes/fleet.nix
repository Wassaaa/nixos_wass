{ pkgs, ... }:

let
  gatewayUsers = {
    hermes-admin = {
      description = "Hermes admin gateway user";
      home = "/home/hermes-admin";
    };
    hermes-user = {
      description = "Hermes restricted gateway user";
      home = "/home/hermes-user";
    };
  };
in
{
  # Step 1 of the Hermes fleet rollout: create the gateway identities only.
  # Each user gets its own HOME and eventually its own mutable ~/.hermes state.
  # Do not add wheel/sudo/secrets/services here yet; those are later steps in
  # docs/plans/hermes-fleet.md.
  users.users = builtins.mapAttrs (_name: userCfg: {
    isNormalUser = true;
    inherit (userCfg) description home;
    createHome = true;
    group = "users";
    extraGroups = [ ];
    shell = pkgs.bashInteractive;
  }) gatewayUsers;
}
