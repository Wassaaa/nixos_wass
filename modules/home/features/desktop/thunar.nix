{ pkgs, ... }:
let
  terminalHere = pkgs.writeShellApplication {
    name = "thunar-terminal-here";
    runtimeInputs = [ pkgs.libnotify pkgs.xdg-terminal-exec ];
    text = builtins.readFile ./thunar-terminal-here.sh;
  };
in {
  # Caelestia's GTK integration generates Thunar's CSS.
  # Thunar and Tumbler are installed through Home Manager packages because
  # programs.thunar/services.tumbler are NixOS module options, not HM options.
  home.packages = with pkgs; [
    thunar
    thunar-archive-plugin
    thunar-volman
    tumbler
    p7zip
  ];

  xdg.mimeApps.defaultApplications = {
    "inode/directory" = [ "thunar.desktop" ];
  };

  xdg.configFile."Thunar/uca.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
      <action>
        <icon>utilities-terminal</icon>
        <name>Open Terminal Here</name>
        <unique-id>wassos-terminal-here</unique-id>
        <command>${terminalHere}/bin/thunar-terminal-here %f</command>
        <description>Open the default terminal in this directory</description>
        <patterns>*</patterns>
        <directories/>
      </action>
    </actions>
  '';
}
