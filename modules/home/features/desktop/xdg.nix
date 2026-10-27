{ config, host, flakeRoot, lib, ... }:
let
  inherit (import "${flakeRoot}/hosts/${host}/variables.nix") browser terminal;
  browserDesktopFiles = {
    brave = "brave-browser.desktop";
    google-chrome-stable = "google-chrome.desktop";
  };
  terminalDesktopFiles = {
    foot = "foot.desktop";
    footclient = "footclient.desktop";
  };
  browserDesktopFile =
    browserDesktopFiles.${browser}
      or (throw "Unsupported desktop browser '${browser}'; add its desktop file to browserDesktopFiles.");
  terminalDesktopFile =
    terminalDesktopFiles.${terminal}
      or (throw "Unsupported desktop terminal '${terminal}'; add its desktop file to terminalDesktopFiles.");
  picturesDir =
    if config.xdg.userDirs.pictures == null
    then "${config.home.homeDirectory}/Pictures"
    else config.xdg.userDirs.pictures;
in
{
  home.sessionVariables = {
    BROWSER = browser;
    TERMINAL = terminal;
  };

  xdg = {
    userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = true;
      extraConfig.SCREENSHOTS = "${picturesDir}/Screenshots";
    };

    mimeApps = {
      enable = true;
      defaultApplications = lib.genAttrs [
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "text/html"
        "application/xhtml+xml"
      ] (_: [ browserDesktopFile ]);
    };

    terminal-exec = {
      enable = true;
      settings.default = [ terminalDesktopFile ];
    };
  };
}
