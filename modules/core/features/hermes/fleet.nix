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

  # Step 2: bootstrap the mutable Hermes state directories. These directories
  # are intentionally state, not Nix-owned config: config.yaml, .env, auth.json,
  # sessions, memory, and installed skills remain editable by each gateway user.
  systemd.tmpfiles.rules = builtins.concatLists (
    builtins.attrValues (
      builtins.mapAttrs (_name: userCfg: [
        "d ${userCfg.home}/.hermes 0700 ${_name} users - -"
        "d ${userCfg.home}/.hermes/logs 0700 ${_name} users - -"
        "d ${userCfg.home}/.hermes/sessions 0700 ${_name} users - -"
      ]) gatewayUsers
    )
  );
}
