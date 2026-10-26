{ pkgs, inputs, ... }: {
  # Caelestia's CLI supplies the palette at runtime; this module owns stable
  # Foot preferences only. Its CLI theme integration writes terminal escape
  # sequences to accessible pseudo-terminals.
  programs.foot = {
    enable = true;
    server.enable = true;
    settings = {
      main = {
        font = "JetBrains Mono Nerd Font:size=11";
        pad = "12x12 center";
        selection-target = "clipboard";
      };
      cursor = {
        style = "beam";
        beam-thickness = 1;
      };
      scrollback.lines = 10000;
    };
  };
  home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
  home.sessionVariables.TERMINAL = "footclient";
}
