{host, flakeRoot, ...}: let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") enableNFS;
in {
  services = {
    rpcbind.enable = enableNFS;
    nfs.server.enable = enableNFS;
  };
}
