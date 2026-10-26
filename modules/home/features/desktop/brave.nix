{ ... }: {
  # Brave is the default browser; Chrome remains installed as a secondary browser.
  programs.brave = {
    enable = true;
    commandLineArgs = [
      "--disable-features=WaylandWpColorManagerV1"
    ];
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = [ "brave-browser.desktop" ];
      "x-scheme-handler/https" = [ "brave-browser.desktop" ];
      "text/html" = [ "brave-browser.desktop" ];
      "application/xhtml+xml" = [ "brave-browser.desktop" ];
    };
  };
}
