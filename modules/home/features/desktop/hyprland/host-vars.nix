{ host, flakeRoot, ... }:
let
  variables = import "${flakeRoot}/hosts/${host}/variables.nix";
in {
  xdg.configFile."hypr/variables.lua".text = ''
    -- Host settings.
    browser = ${builtins.toJSON variables.browser}
    terminal = ${builtins.toJSON variables.terminal}
    keyboardLayout = ${builtins.toJSON variables.keyboardLayout}
    monitorProfilePriority = ${
      if builtins.length (variables.monitorProfiles or [ ]) > 1 then
        "{ ${builtins.concatStringsSep ", " (map (monitor: builtins.toJSON monitor.name) variables.monitors)} }"
      else
        "nil"
    }
  '';
}
