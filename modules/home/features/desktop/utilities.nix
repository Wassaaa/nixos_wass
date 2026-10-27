{ pkgs, ... }:
let
  ocr = pkgs.writeShellApplication {
    name = "wl-ocr";
    runtimeInputs = with pkgs; [ grim slurp tesseract5 wl-clipboard libnotify ];
    text = ''
      region=$(slurp) || exit 0
      [ -n "$region" ] || exit 0
      result=$(grim -g "$region" -t ppm - | tesseract -l eng - -)
      printf '%s' "$result" | wl-copy
      notify-send "Screen text copied" "OCR result is in the clipboard"
    '';
  };
in {
  home.packages = with pkgs; [
    grimblast grim slurp wl-clipboard
    wireplumber ocr
  ];
  home.sessionVariables.SCREENSHOT_DIR = "$HOME/Pictures/Screenshots";
}
