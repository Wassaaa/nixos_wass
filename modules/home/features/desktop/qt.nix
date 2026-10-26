{ pkgs, config, lib, inputs, ... }:
let
  # Match the compiler runtime of this nixpkgs' Qt applications. These argument
  # names were checked against the repository's locked nixpkgs revision.
  hyprutils = pkgs.hyprutils.override { gcc15Stdenv = pkgs.stdenv; };
  hyprlang = pkgs.hyprlang.override {
    gcc15Stdenv = pkgs.stdenv;
    inherit hyprutils;
  };
  engine = pkgs.stdenv.mkDerivation {
    pname = "wass-hyprqt6engine";
    version = "0-unstable-2026-08-11";
    src = pkgs.fetchFromGitHub {
      owner = "hyprwm";
      repo = "hyprqt6engine";
      rev = "d0ce29ca5471f406c71558cd9453573686b8c976";
      hash = "sha256-UQQue60zRgkz4KqqAyVZlVqGvdGZcj5BuWV9SlbURis=";
    };
    patches = [
      "${inputs.fufexan-dotfiles}/.tack/patches/hyprqt6engine/hyprqt6engine-portal-follow.patch"
    ];
    nativeBuildInputs = with pkgs; [ cmake pkg-config kdePackages.extra-cmake-modules ];
    buildInputs = [
      hyprutils hyprlang pkgs.qt6Packages.qtbase
      pkgs.kdePackages.kconfig pkgs.kdePackages.kcolorscheme
      pkgs.kdePackages.kiconthemes pkgs.kdePackages.qtdeclarative
    ];
    dontWrapQtApps = true;
    cmakeFlags = [ "-DPLUGINDIR=${placeholder "out"}/lib/qt-6" ];
    meta.license = lib.licenses.bsd3;
  };
  environment = {
    QT_QPA_PLATFORMTHEME = "hyprqt6engine";
    QT_PLUGIN_PATH = "${engine}/lib/qt-6";
  };
  colorSchemes = "${pkgs.kdePackages.breeze}/share/color-schemes";
in {
  # Do not install a second Qt platform-theme provider through HM's qt module.
  qt.enable = lib.mkForce false;
  home.packages = [ engine pkgs.kdePackages.breeze ];
  home.sessionVariables = environment;
  systemd.user.sessionVariables = environment;
  # This session uses HM's Hyprland integration, not upstream's UWSM launcher.
  wayland.windowManager.hyprland.extraConfig = lib.mkBefore ''
    hl.env("QT_QPA_PLATFORMTHEME", "hyprqt6engine")
    hl.env("QT_PLUGIN_PATH", "${engine}/lib/qt-6")
  '';
  xdg.configFile."hypr/hyprqt6engine.conf".text = ''
    theme {
        style = Fusion
        icon_theme = ${config.gtk.iconTheme.name}
        font = ${config.gtk.font.name}
        font_size = ${toString config.gtk.font.size}
        font_fixed = JetBrains Mono Nerd Font
        font_fixed_size = 10
        color_scheme =
        color_scheme_light = ${colorSchemes}/BreezeLight.colors
        color_scheme_dark = ${colorSchemes}/BreezeDark.colors
    }
  '';
}
