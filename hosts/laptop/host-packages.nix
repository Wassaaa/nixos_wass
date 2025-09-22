{pkgs, ...}: {
  # Laptop-optimized packages - focus on battery life and portability
  environment.systemPackages = with pkgs; [
    # Essential tools
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
    
    # Development (lighter selection)
    gcc
    gnumake
    
    # Network tools
    dig
    iputils
    
    # File management
    fd
    ripgrep
    fzf
    bat
    eza
    
    # Laptop-specific
    powertop      # Power management
    tlp           # Battery optimization
    brightnessctl # Brightness control
    pamixer       # Audio control
    
    # System monitoring
    acpi          # Battery info
    lm_sensors    # Temperature monitoring
  ];
}