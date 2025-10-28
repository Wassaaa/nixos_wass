{ pkgs, ... }:
{
  # Virtualization programs
  programs.virt-manager.enable = true;

  # Virtualization packages
  environment.systemPackages = with pkgs; [
    # VM management
    # virt-manager
    # virt-viewer
    # spice
    # spice-gtk
    # spice-protocol
    # virtualbox
    # libvirt

    # Container tools
    docker-compose
    distrobox

    # Kubernetes tools (optional)
    # kubectl
    # kubernetes-helm
    # k9s

    # USB and device support
    usbutils
    v4l-utils
  ];
}
