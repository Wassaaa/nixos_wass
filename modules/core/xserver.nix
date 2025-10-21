{host, flakeRoot, ...}: let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") keyboardLayout;
in {
  services.xserver = {
    enable = false;
    xkb = {
      layout = "${keyboardLayout}";
      variant = "";
    };
  };
}
