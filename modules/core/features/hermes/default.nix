{ pkgs, inputs, ... }:

let
  hermesPkg = inputs.hermes-agent.packages.${pkgs.system}.default.override {
    # Keep local feature choices outside the Hermes upstream checkout so the
    # base repo can update cleanly. These groups add Discord/Telegram gateway
    # deps and ElevenLabs TTS support to the sealed Hermes Python env.
    extraDependencyGroups = [
      "messaging"
      "tts-premium"
    ];
  };
in
{
  imports = [
    ./fleet.nix
  ];

  # Shared Hermes feature: install the Hermes CLI/package and host-side tools the
  # agent can call from terminal/tools/skills. Runtime state intentionally stays
  # mutable in each gateway user's HOME (~/.hermes); secrets, auth.json,
  # sessions, memory, and user-installed skills are not Nix-managed.
  environment.systemPackages = with pkgs; [
    hermesPkg

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
  ];
}
