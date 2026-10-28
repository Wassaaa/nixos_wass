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
  xdg.configFile."swappy/config".text = ''
    [Default]
    save_dir="$HOME/Pictures/Screenshots"
    save_filename_format=Screenshot-%Y%m%d-%H%M%S.png
    auto_save=true
  '';

  home.packages = with pkgs; [
    grimblast grim slurp wl-clipboard
    wireplumber ocr
  ];
}
