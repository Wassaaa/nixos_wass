{ pkgs, inputs, ... }: {
  # Use the actual pinned upstream palettes, opacity, padding and cursor settings.
  # The upstream module also provides a Darkman action for running Foot processes.
  imports = [ "${inputs.fufexan-dotfiles}/home/terminal/emulators/foot.nix" ];
  home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
  home.sessionVariables.TERMINAL = "footclient";
}
