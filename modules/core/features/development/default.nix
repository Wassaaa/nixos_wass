# Development Features
{ pkgs, config, ... }:
{
  imports = [
    ./packages.nix
  ];
  
  # Critical for VSCode Remote and binary compatibility
  programs.nix-ld.enable = true;

  # Appimage Support for development tools
  boot.binfmt.registrations.appimage = {
    wrapInterpreterInShell = false;
    interpreter = "${pkgs.appimage-run}/bin/appimage-run";
    recognitionType = "magic";
    offset = 0;
    mask = "\\xff\\xff\\xff\\xff\\x00\\x00\\x00\\x00\\xff\\xff\\xff";
    magicOrExtension = "\\x7fELF....AI\\x02";
  };

  # Development services
  services.postgresql = {
    enable = false; # Enable per-project
    package = pkgs.postgresql_15;
  };

  # Development shell configurations
  programs.zsh.enable = true;
  programs.fish.enable = true;
}
