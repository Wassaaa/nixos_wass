{ host, ... }: {
  programs.brave = {
    enable = true;
    commandLineArgs = if host == "wassaa" then [
      "--enable-features=AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder,VaapiOnNvidiaGPUs,WaylandWindowDecorations"
      "--disable-features=OutdatedBuildDetector,UseChromeOSDirectVideoDecoder,WaylandWpColorManagerV1"
    ] else [
      "--disable-features=WaylandWpColorManagerV1"
    ];
  };
}
