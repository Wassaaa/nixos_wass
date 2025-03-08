{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode.overrideAttrs (oldAttrs: {
      # Create a wrapper script that adds Wayland flags
      postInstall =
        (oldAttrs.postInstall or "")
        + ''
          wrapProgram $out/bin/code \
            --add-flags "--disable-gpu-compositing"
        '';
    });
    enableExtensionUpdateCheck = false;
    mutableExtensionsDir = false;

    extensions = with pkgs.vscode-extensions; [
      # microsoft
      ms-vscode-remote.remote-ssh
      ms-vscode-remote.remote-ssh-edit
      ms-azuretools.vscode-docker
      catppuccin.catppuccin-vsc

      # ts
      yoavbls.pretty-ts-errors
      dbaeumer.vscode-eslint
      christian-kohler.npm-intellisense
      esbenp.prettier-vscode

      # utilities
      ms-vscode.hexeditor
      github.copilot
      eamodio.gitlens

      # UI
      naumovs.color-highlight
      oderwat.indent-rainbow
      jnoortheen.nix-ide
    ];
    userSettings = {
      # General
      "editor.fontSize" = 16;
      "editor.fontFamily" = "'Jetbrains Mono', 'monospace', monospace";
      "terminal.integrated.fontSize" = 14;
      "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font', 'monospace', monospace";
      "window.zoomLevel" = 1;
      "editor.multiCursorModifier" = "ctrlCmd";
      "workbench.startupEditor" = "none";
      "explorer.compactFolders" = false;
      # Whitespace
      "files.trimTrailingWhitespace" = true;
      "files.trimFinalNewlines" = true;
      "files.insertFinalNewline" = true;
      "diffEditor.ignoreTrimWhitespace" = false;
      # Styling
      "workbench.colorTheme" = "Catppuccin Mocha";
      # Set to `true` to disable folding arrows next to folder icons.
      "catppuccin-icons.hidesExplorerArrows" = false;
      # Set to `false` to only use the default folder icon.
      "catppuccin-icons.specificFolders" = true;
      # Set to `true` to only use the `text` fill color for all icons.
      "catppuccin-icons.monochrome" = false;
    };
  };
}
