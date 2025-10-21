# Core Home Manager Features - Basic modules that work everywhere
{ profile, lib, ... }: {
  imports = [
    # Always available basic tools (CLI)
    ./bat.nix         # Better cat
    ./bash.nix        # Bash shell config
    ./btop.nix        # Better top
    ./direnv.nix      # Environment loader
    ./gh.nix          # GitHub CLI
    ./git.nix         # Git configuration
    ./starship.nix    # Cross-shell prompt
    ./zsh.nix         # Zsh shell config
    ./emoji.nix       # Emoji support
    ./kitty.nix       # Terminal emulator (works everywhere, even without GUI)
    ./fastfetch       # System info
  ]
  # Profile-specific configurations
  ++ lib.optionals (profile == "wsl") [
    ./1password-wsl.nix  # 1Password via Windows SSH agent
  ];
}
