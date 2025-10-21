# Multimedia Home Manager Features - Audio/video and media tools
{ ... }:
{
  imports = [
    # Audio visualization and controls
    ../../cava.nix # Audio visualizer

    # Media-related utilities
    ../../emoji.nix # Emoji picker (desktop dependent)
    ../../transmission.nix # Torrent client (CLI)
    ../../obs.nix # OBS Studio settings

    # Note: Most multimedia apps are system-level (VLC, etc.)
    # This is mainly for user-level media configurations
  ];
}
