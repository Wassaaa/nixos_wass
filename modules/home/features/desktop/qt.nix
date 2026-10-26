# Explicit non-Stylix baseline. Upstream's patched hyprqt6engine ABI workaround
# is deliberately not copied into this differently pinned package set.
{ lib, ... }: {
  qt = {
    enable = true;
    style.name = lib.mkForce "adwaita-dark";
    platformTheme.name = lib.mkForce "gtk3";
  };
}
