# Development Home Manager Features - Programming tools and environments
{ ... }: {
  imports = [
    # Development tools
    ../../gh.nix         # GitHub CLI
    ../../git.nix        # Git configuration
    ../../direnv.nix     # Development environment management
    
    # Terminal and shell
    ../../bash.nix       # Bash configuration
    ../../zsh.nix        # Zsh configuration
    ../../starship.nix   # Shell prompt
    ../../kitty.nix      # Terminal emulator (works in both GUI and TTY)
    ../../ghostty.nix    # Alternative terminal
    
    # Development utilities
    ../../bat.nix        # Better cat
    ../../btop.nix       # System monitor
    ../../fastfetch      # System info
  ];
}