{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode-insiders.overrideAttrs (oldAttrs: {
      # Wrap insiders and expose it as 'code' for convenience
      postInstall =
        (oldAttrs.postInstall or "")
        + ''
          # Wrap insiders binary with flags
          if [ -x "$out/bin/code-insiders" ]; then
            wrapProgram "$out/bin/code-insiders" \
              --add-flags "--disable-gpu-compositing"
          fi

          # Provide a 'code' alias pointing to insiders
          rm -f "$out/bin/code" || true
          ln -s "$out/bin/code-insiders" "$out/bin/code"
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
}
