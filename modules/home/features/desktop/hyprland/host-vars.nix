{ host, config, flakeRoot, ... }:
let
  variables = import "${flakeRoot}/hosts/${host}/variables.nix";
  terminal = if config.programs.foot.enable then "footclient" else variables.terminal;
in {
  xdg.configFile."hypr/variables.lua".text = ''
    -- Host settings with the desktop terminal selected by Home Manager.
    browser = ${builtins.toJSON variables.browser}
    terminal = ${builtins.toJSON terminal}
    keyboardLayout = ${builtins.toJSON variables.keyboardLayout}
  '';
}
