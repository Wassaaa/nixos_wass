{ ... }: {
  # Minimal mpv setup. Caelestia's shell uses mpv as its playback default;
  # visual tweaks can be adopted selectively from Caelestia's dots later.
  programs.mpv = {
    enable = true;
    config = {
      profile = "gpu-hq";
      gpu-api = "vulkan";
      hwdec = "auto-safe";
      osc = "yes";
      keep-open = "yes";
      save-position-on-quit = "yes";
      slang = "en";
    };
  };
}
