{ pkgs, lib, inputs, ... }:

{
  programs.vscode = {
    enable = true;
    package = inputs.vscode-insiders.packages.${pkgs.system}.vscode-insider.overrideAttrs (oldAttrs: {
      # Wrap insiders and expose it as 'code' for convenience
      postInstall =
        (oldAttrs.postInstall or "")
        + ''
          # Prefer insiders if present; otherwise wrap stable
          if [ -x "$out/bin/code-insiders" ]; then
            rm -f "$out/bin/code" || true
            ln -s "$out/bin/code-insiders" "$out/bin/code"
          fi
        '';
    });
  };

  # Provide a base settings fragment for both VS Code and VS Code Insiders
  xdg.configFile."Code/User/settings.base.json" = {
    source = ./vscode.settings.base.jsonc;
  };

  xdg.configFile."Code - Insiders/User/settings.base.json" = {
    source = ./vscode.settings.base.jsonc;
  };

  home.activation.mergeVscodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -eu
    CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"

    # Function to merge settings for a specific VS Code variant
    merge_settings() {
      local SETTINGS_DIR="$1"
      local BASE="$SETTINGS_DIR/settings.base.json"
      local USER_SETTINGS="$SETTINGS_DIR/settings.json"
      local TMP="$SETTINGS_DIR/.settings.json.hm-merge"

      mkdir -p "$SETTINGS_DIR"
      if [ -f "$BASE" ]; then
        # Strip comments from JSONC before merging
        local BASE_CLEAN="$SETTINGS_DIR/.settings.base.clean.json"
        ${pkgs.jq}/bin/jq . "$BASE" > "$BASE_CLEAN" 2>/dev/null || cp "$BASE" "$BASE_CLEAN"

        if [ -f "$USER_SETTINGS" ]; then
          ${pkgs.jq}/bin/jq -s 'add' "$BASE_CLEAN" "$USER_SETTINGS" > "$TMP" && mv "$TMP" "$USER_SETTINGS"
        else
          cp "$BASE_CLEAN" "$USER_SETTINGS"
        fi

        rm -f "$BASE_CLEAN"
      fi
    }

    # Merge settings for both stable and insiders
    merge_settings "$CONFIG_HOME/Code/User"
    merge_settings "$CONFIG_HOME/Code - Insiders/User"
  '';
}
