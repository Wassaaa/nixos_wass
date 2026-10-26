{ host, flakeRoot, ... }:
let
  variables = import "${flakeRoot}/hosts/${host}/variables.nix";
in {
  xdg.configFile."hypr/variables.lua".text = ''
    -- Host settings. Foot is the selected desktop terminal.
    browser = ${builtins.toJSON variables.browser}
    terminal = "footclient"
    keyboardLayout = ${builtins.toJSON variables.keyboardLayout}
  '';
}
