{ pkgs, ... }:
{
  # Development tools and packages
  environment.systemPackages = with pkgs; [
    # Version control
    git
    git-lfs
    gh

    # Editors and IDEs
    vim

    # Build tools
    gcc
    man-pages
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
    nixd # Nix LSP server
    nixfmt-rfc-style # Nix Formatter
    just
    hyperfine
    tokei

    # Debugging and profiling
    gdb
    valgrind
    strace
    ltrace

    # Additional tools
    wget
    curl
    unzip
    zip
    ffmpeg # Terminal video/audio editing
  ];
}
