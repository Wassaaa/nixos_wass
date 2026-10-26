{ pkgs, inputs, ... }:

{
  programs.vscode = {
    enable = true;
    package =
      inputs.vscode-insiders.packages.${pkgs.stdenv.hostPlatform.system}.vscode-insider.overrideAttrs
        (oldAttrs: {
          postPatch = ''
            # Disable update checks
            tmpProductJson="$(mktemp)"
            jq 'del(.updateUrl, .backupUpdateUrl)' resources/app/product.json > "$tmpProductJson"
            mv "$tmpProductJson" resources/app/product.json

            # Fix "save as root" functionality
            packed="resources/app/node_modules.asar"
            unpacked="resources/app/node_modules"
            asar extract "$packed" "$unpacked"
            substituteInPlace $unpacked/@vscode/sudo-prompt/index.js \
              --replace-fail "/usr/bin/pkexec" "/run/wrappers/bin/pkexec" \
              --replace-fail "/bin/bash" "${pkgs.bash}/bin/bash"

            rm -rf "$packed"

            # Keep the unpacked node_modules reachable
            ln -rs "$unpacked" "$packed"

            # Replace the bundled ripgrep with Nixpkgs ripgrep,
            # creating the directory if newer Insiders archives omit it.
            rgPath="resources/app/node_modules/@vscode/ripgrep-universal/bin/linux-x64/rg"
            mkdir -p "$(dirname "$rgPath")"
            rm -f "$rgPath"
            ln -s ${pkgs.ripgrep}/bin/rg "$rgPath"
          '';

          postInstall = (oldAttrs.postInstall or "") + ''
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
    onChange = ''
      CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
      echo "Merging VS Code settings for Code..."

      SETTINGS_DIR="$CONFIG_HOME/Code/User"
      BASE="$SETTINGS_DIR/settings.base.json"
      USER_SETTINGS="$SETTINGS_DIR/settings.json"
      TMP="$SETTINGS_DIR/.settings.json.hm-merge"

      if [ -f "$BASE" ]; then
        BASE_CLEAN="$SETTINGS_DIR/.settings.base.clean.json"
        USER_CLEAN="$SETTINGS_DIR/.settings.user.clean.json"

        # Strip comments from JSONC files
        ${pkgs.gnused}/bin/sed -e 's|//.*$||' -e '/\/\*/,/\*\//d' "$BASE" | ${pkgs.jq}/bin/jq . > "$BASE_CLEAN" 2>/dev/null || cp "$BASE" "$BASE_CLEAN"

        if [ -f "$USER_SETTINGS" ]; then
          # Strip comments from user settings too (VS Code supports JSONC)
          ${pkgs.gnused}/bin/sed -e 's|//.*$||' -e '/\/\*/,/\*\//d' "$USER_SETTINGS" | ${pkgs.jq}/bin/jq . > "$USER_CLEAN" 2>/dev/null || cp "$USER_SETTINGS" "$USER_CLEAN"

          # Deep merge: base * user (user values override base)
          ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$BASE_CLEAN" "$USER_CLEAN" > "$TMP" && mv "$TMP" "$USER_SETTINGS"
          rm -f "$USER_CLEAN"
        else
          cp "$BASE_CLEAN" "$USER_SETTINGS"
        fi

        rm -f "$BASE_CLEAN"
      fi
    '';
  };

  xdg.configFile."Code - Insiders/User/settings.base.json" = {
    source = ./vscode.settings.base.jsonc;
    onChange = ''
      CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
      echo "Merging VS Code settings for Code - Insiders..."

      SETTINGS_DIR="$CONFIG_HOME/Code - Insiders/User"
      BASE="$SETTINGS_DIR/settings.base.json"
      USER_SETTINGS="$SETTINGS_DIR/settings.json"
      TMP="$SETTINGS_DIR/.settings.json.hm-merge"

      if [ -f "$BASE" ]; then
        BASE_CLEAN="$SETTINGS_DIR/.settings.base.clean.json"
        USER_CLEAN="$SETTINGS_DIR/.settings.user.clean.json"

        # Strip comments from JSONC files
        ${pkgs.gnused}/bin/sed -e 's|//.*$||' -e '/\/\*/,/\*\//d' "$BASE" | ${pkgs.jq}/bin/jq . > "$BASE_CLEAN" 2>/dev/null || cp "$BASE" "$BASE_CLEAN"

        if [ -f "$USER_SETTINGS" ]; then
          # Strip comments from user settings too (VS Code supports JSONC)
          ${pkgs.gnused}/bin/sed -e 's|//.*$||' -e '/\/\*/,/\*\//d' "$USER_SETTINGS" | ${pkgs.jq}/bin/jq . > "$USER_CLEAN" 2>/dev/null || cp "$USER_SETTINGS" "$USER_CLEAN"

          # Deep merge: base * user (user values override base)
          ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$BASE_CLEAN" "$USER_CLEAN" > "$TMP" && mv "$TMP" "$USER_SETTINGS"
          rm -f "$USER_CLEAN"
        else
          cp "$BASE_CLEAN" "$USER_SETTINGS"
        fi

        rm -f "$BASE_CLEAN"
      fi
    '';
  };
}
