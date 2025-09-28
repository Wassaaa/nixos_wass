{ ... }:
{
  xdg.desktopEntries."steam-gamescope" = {
    name = "Steam (Gamescope)";
    comment = "Steam in Gamescope Big Picture";
    icon = "steam";
    type = "Application";
    exec = "steam-gamescope";   # your wrapper
    categories = [ "Game" ];
    # optional: hint to run on dGPU if you have hybrid graphics
    prefersNonDefaultGPU = true;
  };
}
