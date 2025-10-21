# Multimedia Home Manager Features - Audio/video and media tools
{ ... }:
{
  imports = [
    # Audio visualization and controls
    ../desktop/cava.nix # Audio visualizer

    # Media-related utilities
    ../core/emoji.nix # Emoji picker (desktop dependent)
    ../desktop/transmission.nix # Torrent client (CLI)
    ../desktop/obs.nix # OBS Studio settings

    # Note: Most multimedia apps are system-level (VLC, etc.)
    # This is mainly for user-level media configurations
  ];
}
