{pkgs, ...}: {
  # WSL-specific packages
  environment.systemPackages = with pkgs; [
    # Essential CLI tools
    wget
    curl
    git
    vim
    nano
    htop
    btop
    tree
    unzip
    zip
    rsync
    
    # Development tools
    gcc
    gnumake
    cmake
    
    # Network tools
    dig
    iputils  # includes ping
    traceroute
    
    # File management
    fd
    ripgrep
    fzf
    bat
    eza
    
    # System tools
    systemd
    procps
    
    # WSL integration tools
    wslu  # WSL utilities
  ];
}