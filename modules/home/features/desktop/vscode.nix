{ host, flakeRoot, lib, pkgs, inputs, ... }:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") flakeDir;
  updateCheck = pkgs.writeShellApplication {
    name = "check-vscode-insiders-update";
    runtimeInputs = with pkgs; [ coreutils git jq libnotify ];
    text = ''
      fail() {
        printf '%s\n' "$1" >&2
        if ! notify-send --app-name="VS Code Insiders" "Update check failed" "$1"; then
          printf '%s\n' "Could not display the update-check notification" >&2
        fi
        exit 1
      }

      lock=${lib.escapeShellArg "${flakeDir}/flake.lock"}
      if ! info=$(jq -er '
        .nodes as $nodes
        | $nodes[$nodes.root.inputs["vscode-insiders"]].locked
        | select(.type == "github" and (.owner | type == "string")
            and (.repo | type == "string") and (.rev | type == "string"))
        | [.owner, .repo, .rev] | @tsv
      ' "$lock"); then
        fail "Could not read the pinned Insiders revision from $lock."
      fi
      IFS=$'\t' read -r owner repo pinned <<< "$info"
      if [[ ! "$owner" =~ ^[a-zA-Z0-9._-]+$ || ! "$repo" =~ ^[a-zA-Z0-9._-]+$ || ! "$pinned" =~ ^[a-f0-9]{40}$ ]]; then
        fail "The pinned Insiders source in $lock is invalid."
      fi

      export GIT_TERMINAL_PROMPT=0
      if ! remote=$(timeout 20 git ls-remote --exit-code "https://github.com/$owner/$repo.git" HEAD); then
        fail "Could not check the Insiders source on GitHub."
      fi
      read -r latest ref <<< "$remote"
      if [[ ! "$latest" =~ ^[a-f0-9]{40}$ || "$ref" != HEAD ]]; then
        fail "GitHub returned an invalid Insiders revision."
      fi
      if [[ "$latest" != "$pinned" ]]; then
        notify-send --app-name="VS Code Insiders" "Insiders update available" \
          "The Insiders flake has changed. Run code-update to apply it."
      fi
    '';
  };
in
{
  programs.vscode = {
    enable = true;
    package =
      inputs.vscode-insiders.packages.${pkgs.stdenv.hostPlatform.system}.vscode-insider.overrideAttrs
        (oldAttrs: {
          postInstall = (oldAttrs.postInstall or "") + ''
            if [ ! -x "$out/bin/code-insiders" ]; then
              echo "Expected the code-insiders executable in $out/bin" >&2
              exit 1
            fi
            ln -sf "$out/bin/code-insiders" "$out/bin/code"
          '';
        });
  };

  systemd.user.services.vscode-insiders-update-check = {
    Unit = {
      Description = "Check for VS Code Insiders flake updates";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${updateCheck}/bin/check-vscode-insiders-update";
    };
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
