{
  host,
  flakeRoot,
  ...
}:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix")
    browser
    terminal
    keyboardLayout
    ;
in
{
  xdg.configFile."hypr/variables.lua".text = ''
    -- Generated from hosts/${host}/variables.nix

    browser = "${browser}"
    terminal = "${terminal}"
    keyboardLayout = "${keyboardLayout}"
  '';
}
