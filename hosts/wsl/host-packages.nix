{ pkgs, ... }:
{

  # WSL & GPU Integration ---
  wsl.useWindowsDriver = true;
  hardware.nvidia-container-toolkit.enable = true;
  hardware.nvidia-container-toolkit.suppressNvidiaDriverAssertion = true;
  hardware.graphics.enable = true;

  # WSL-specific packages
  environment.systemPackages = with pkgs; [
    # Essential CLI tools
    curl
    git
    vim
    nano
    btop
    tree
    zip
    rsync

    # Development tools
    gcc
    gnumake
    cmake

    # Network tools
    dig
    iputils # includes ping
    traceroute

    # File management
    fd
    fzf
    bat

    # System tools
    systemd
    procps

    # WSL integration tools
    # wslu was removed from nixpkgs after upstream was archived; keep basic
    # Windows "open with default app" integration via the maintained replacement.
    wsl-open
  ];
}
