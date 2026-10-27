{ ... }: {
  programs.brave = {
    enable = true;
    commandLineArgs = [
      "--disable-features=WaylandWpColorManagerV1"
    ];
  };
}
