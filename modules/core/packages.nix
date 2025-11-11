{ pkgs, ... }:
{
  # Core programs available everywhere
  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    fuse.userAllowOther = true;
    mtr.enable = true;
  };

  nixpkgs.config.allowUnfree = true;

  # Core CLI utilities - available on all systems (including WSL)
  environment.systemPackages = with pkgs; [
    # Security & Secrets
    sops
    age
    ssh-to-age

    # CLI Utilities
    cmatrix
    cowsay
    duf # Disk usage viewer
    eza # Better ls
    htop # System monitor
    inxi # System info
    jq # JSON processor
    killall
    lolcat
    lshw # Hardware info
    ncdu # Disk analyzer
    pciutils
    pkg-config
    ripgrep # Better grep
    unrar
    unzip
    wget
    socat
  ];
}
