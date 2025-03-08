{ ... }: {
  programs.google-chrome = {
    enable = true;
    commandLineArgs = [
      "--disable-gpu-compositing"
      "--wayland-per-window-scaling=1"
      "--ozone-platform-hint=wayland"
      "--wayland-ui-scaling=1"
      "--wayland-text-input-v3=1"
    ];
  };
}
