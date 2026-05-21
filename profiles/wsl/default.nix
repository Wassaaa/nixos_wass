{
  host,
  inputs,
  username,
  flakeRoot,
  pkgs,
  ...
}:
{
  imports = [
    "${flakeRoot}/hosts/${host}"
    "${flakeRoot}/modules/core" # Now uses feature-based loading
  ];

  # WSL configuration
  wsl.enable = true;
  wsl.defaultUser = "wsl";
  # Required when custom binfmt registrations are present, otherwise Windows
  # .exe interop can stop working in WSL2.
  wsl.interop.register = true;
  programs.nix-ld.enable = true;

  # WSL-specific Nix daemon fixes
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # WSL-specific daemon settings to prevent connection issues
    keep-outputs = true;
    keep-derivations = true;
    # Ensure daemon can be reached
    use-xdg-base-directories = false;
    # Allow the WSL user to connect to the system nix daemon
    trusted-users = [
      "root"
      "@wheel"
      "wsl"
    ];
  };

  # Ensure systemd works properly in WSL
  systemd.services.nix-daemon.serviceConfig = {
    # WSL-specific overrides for nix-daemon
    StandardOutput = "journal";
    StandardError = "journal";
  };

  # WSL-specific environment setup
  environment.variables = {
    # Ensure proper WSL integration
    NIXOS_WSL = "1";
  };

  # Some Windows-launched CLIs assume an FHS-ish shell path inside WSL and
  # call /usr/bin/bash directly. NixOS normally exposes bash at /bin/bash and
  # in the Nix store, so provide this compatibility symlink for tools like
  # the Windows Codex CLI without changing the actual shell package source.
  systemd.tmpfiles.rules = [
    "L+ /usr/bin/bash - - - - ${pkgs.bashInteractive}/bin/bash"
  ];

  # Enable essential services for WSL
  services.openssh.enable = true;

  # System version
  system.stateVersion = "25.05";
}
