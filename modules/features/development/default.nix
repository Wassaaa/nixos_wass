# Development Features
{ pkgs, config, ... }: {
  # Development tools
  environment.systemPackages = with pkgs; [
    # Version control
    git
    git-lfs
    gh
    
    # Editors and IDEs
    vim
    neovim
    vscode
    
    # Build tools
    gcc
    gnumake
    cmake
    meson
    ninja
    
    # Language toolchains
    nodejs
    python3
    rustc
    cargo
    go
    
    # Development utilities
    direnv
    just
    hyperfine
    tokei
    
    # Debugging and profiling
    gdb
    valgrind
    strace
    ltrace
  ];

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