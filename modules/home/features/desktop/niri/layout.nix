{
  config,
  ...
}:
''
  layout {
      gaps 8
      center-focused-column "on-overflow"
      
      preset-column-widths {
          proportion 0.33333
          proportion 0.5
          proportion 0.66667
      }
      
      default-column-width { proportion 0.5; }
      
      focus-ring {
          width 2
          active-color "#${config.lib.stylix.colors.base08}"
          inactive-color "#${config.lib.stylix.colors.base02}"
      }
      
      border {
          width 2
          active-color "#${config.lib.stylix.colors.base08}"
          inactive-color "#${config.lib.stylix.colors.base02}"
      }
  }

  animations {
      slowdown 1.0
      
      window-open {
          duration-ms 150
          curve "ease-out-expo"
      }
      
      window-close {
          duration-ms 150
          curve "ease-out-expo"
      }
      
      window-movement {
          duration-ms 200
          curve "ease-out-cubic"
      }
      
      workspace-switch {
          duration-ms 200
          curve "ease-out-cubic"
      }
  }

  window-rule {
      geometry-corner-radius 10
      clip-to-geometry true
  }
''
