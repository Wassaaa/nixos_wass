{ pkgs, lib, ... }:

let
  vscodePkg =
    if pkgs ? vscode-insiders then pkgs.vscode-insiders
    else if pkgs ? visual-studio-code-insiders then pkgs.visual-studio-code-insiders
    else pkgs.vscode;
in {
  programs.vscode = {
    enable = true;
    package = vscodePkg.overrideAttrs (oldAttrs: {
      # Wrap insiders and expose it as 'code' for convenience
      postInstall =
        (oldAttrs.postInstall or "")
        + ''
          # Prefer insiders if present; otherwise wrap stable
          if [ -x "$out/bin/code-insiders" ]; then
            wrapProgram "$out/bin/code-insiders" \
              --add-flags "--disable-gpu-compositing"
            rm -f "$out/bin/code" || true
            ln -s "$out/bin/code-insiders" "$out/bin/code"
          elif [ -x "$out/bin/code" ]; then
            wrapProgram "$out/bin/code" \
              --add-flags "--disable-gpu-compositing"
          fi
        '';
    });
    mutableExtensionsDir = true;

    # Keep only a minimal, opinionated baseline; everything else is user-managed
    profiles.default.extensions = with pkgs.vscode-extensions; [
      # Nix
      jnoortheen.nix-ide
      arrterian.nix-env-selector
      mkhl.direnv

      # Theme
      catppuccin.catppuccin-vsc
      catppuccin.catppuccin-vsc-icons
    ];
  };

  # Provide a base settings fragment and merge it into settings.json on activation
  xdg.configFile."Code/User/settings.base.json" = {
    source = ./vscode.settings.base.json;
  };

  home.activation.mergeVscodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -eu
    CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
    SETTINGS_DIR="$CONFIG_HOME/Code/User"
    BASE="$SETTINGS_DIR/settings.base.json"
    USER_SETTINGS="$SETTINGS_DIR/settings.json"
    TMP="$SETTINGS_DIR/.settings.json.hm-merge"

    mkdir -p "$SETTINGS_DIR"
    if [ -f "$BASE" ]; then
      if [ -f "$USER_SETTINGS" ]; then
        ${pkgs.jq}/bin/jq -s 'add' "$BASE" "$USER_SETTINGS" > "$TMP" && mv "$TMP" "$USER_SETTINGS"
      else
        cp "$BASE" "$USER_SETTINGS"
      fi
    fi
  '';
}
