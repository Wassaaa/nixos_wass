# Development Home Manager Features - Programming tools and environments
{ ... }: {
  imports = [
    # Development tools
    ../../nvf.nix        # Neovim configuration
    ../../gh.nix         # GitHub CLI
    ../../git.nix        # Git configuration
    
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
    
    # Basic theming (works everywhere)
    ../../stylix.nix     # Base16 theming
  ];
}