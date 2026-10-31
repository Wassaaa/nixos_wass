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
    (inputs.omp.packages.${pkgs.stdenv.hostPlatform.system}.default.override (
      { craneLib, ... }:
      let
        # The pinned Rust compiler overflows its stack while building OMP dependencies.
        withStack = build: args: build (args // {
          env = (args.env or { }) // { RUST_MIN_STACK = "35651584"; };
        });
      in
      {
        craneLib = craneLib // {
          buildDepsOnly = withStack craneLib.buildDepsOnly;
          buildPackage = withStack craneLib.buildPackage;
        };
      }
    ))
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
