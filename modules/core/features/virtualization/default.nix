# Virtualization Features
{ pkgs, username, ... }:
{
  imports = [
    ./packages.nix
  ];

  # Container and VM support
  virtualisation = {
    libvirtd.enable = true;
    docker.enable = true;
    podman.enable = false; # Use either docker or podman, not both
    # virtualbox.host.enable = true;
  };

  # User groups for virtualization
  users.users.${username}.extraGroups = [
    "libvirtd"
    "docker"
    "vboxusers"
  ];
}
