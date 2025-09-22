# Virtualization Features
{ pkgs, username, ... }: {
  # Container and VM support
  virtualisation = {
    libvirtd.enable = true;
    docker.enable = true;
    podman.enable = false; # Use either docker or podman, not both
  };

  # Virtualization packages
  environment.systemPackages = with pkgs; [
    # VM management
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    
    # Container tools
    docker-compose
    distrobox
    
    # Kubernetes tools (optional)
    kubectl
    kubernetes-helm
    k9s
  ];

  # User groups for virtualization
  users.users.${username}.extraGroups = [ "libvirtd" "docker" ];
}