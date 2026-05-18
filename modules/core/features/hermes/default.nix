{ pkgs, inputs, ... }:

{
  # Shared Hermes feature: install the Hermes CLI/package and host-side tools the
  # agent can call from terminal/tools/skills. Runtime state intentionally stays
  # mutable in the invoking user's HOME (~/.hermes); this module does not manage
  # secrets, auth.json, sessions, memory, or the gateway service.
  environment.systemPackages = with pkgs; [
    inputs.hermes-agent.packages.${pkgs.system}.default

    # Agent/media/video generation runtime tools
    ffmpeg
    imagemagick
    mediainfo
    exiftool
    sox

    # Audio/TTS/build/runtime libraries
    libopus
    portaudio
    espeak-ng

    # JS/browser-ish tooling commonly needed by Hermes skills/plugins
    nodejs_24

    # Python media stack usable from terminal/scripts without mutating Hermes'
    # sealed Nix store venv. Hermes-internal Python deps still belong in the
    # hermes-agent flake/package, not here.
    (python312.withPackages (
      ps: with ps; [
        moviepy
        pillow
        numpy
        scipy
        imageio
        imageio-ffmpeg
      ]
    ))
  ];
}
