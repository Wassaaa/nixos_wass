{ inputs, pkgs, ... }:
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
    python314
    uv
    python314Packages.playwright
    rustc
    cargo
    go

    # Development utilities
    inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    direnv
    devenv
    nixd # Nix LSP server
    nixfmt # Nix Formatter
    just
    hyperfine
    tokei

    # Debugging and profiling
    gdb
    valgrind
    strace
    ltrace

    # Additional tools
    curl
    zip
    ffmpeg # Terminal video/audio editing
  ];
}
