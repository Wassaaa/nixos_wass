{ pkgs, inputs, ... }: {
  # Caelestia's CLI supplies the palette at runtime through terminal escape
  # sequences; this module owns stable Foot preferences and transparency.
  programs.foot = {
    enable = true;
    server.enable = true;
    settings = {
      main = {
        font = "JetBrains Mono Nerd Font:size=12";
        pad = "12x12 center";
        selection-target = "clipboard";
      };
      cursor = {
        style = "beam";
        beam-thickness = "1.5";
      };
      scrollback.lines = 10000;
      colors-dark = {
        alpha = "0.78";
        alpha-mode = "matching";
        blur = "yes";
      };
    };
  };

  home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
  home.sessionVariables.TERMINAL = "footclient";
}
