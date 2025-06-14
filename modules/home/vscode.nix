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
    # baseline extensions baked by Nix
    extensions = with pkgs.vscode-extensions; [
      # microsoft
      ms-vscode-remote.remote-ssh
      ms-vscode-remote.remote-ssh-edit

      # ts
      dbaeumer.vscode-eslint
      christian-kohler.npm-intellisense

      # utilities
      ms-vscode.hexeditor
      github.copilot
      github.copilot-chat
      eamodio.gitlens

      # UI
      catppuccin.catppuccin-vsc
      catppuccin.catppuccin-vsc-icons

      # NIX
      jnoortheen.nix-ide
      # pinage404.nix-extension-pack
      arrterian.nix-env-selector
      mkhl.direnv
    ];

    # users are free to add/remove more via the normal UI
    mutableExtensionsDir = true;
  };
}
