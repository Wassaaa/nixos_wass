# Noctalia Shell

Noctalia Shell is a modern, customizable shell/bar for Wayland compositors built with Quickshell.

## Features

- Material Design 3 inspired interface
- Deep Stylix integration for automatic theming
- Customizable widgets and layout
- Support for multiple window managers (Niri, Hyprland, etc.)

## Configuration

Noctalia is configured through the `programs.noctalia-shell.settings` option in your host's configuration.

### Enabling Noctalia

In your host's `variables.nix`:

```nix
barChoice = "noctalia";
```

### Customization

The default configuration uses Stylix colors automatically. You can override settings by modifying the `settings` attribute in `modules/home/noctalia-shell/default.nix`.

Available configuration sections:
- **bar**: Position, density, widget layout
- **general**: Avatar, animations, lock behavior
- **location**: Time zone, weather, date formatting
- **colors**: Color scheme (auto-synced with Stylix by default)
- **audio**: Volume/brightness increments
- **notifications**: Urgency levels, timeouts, locations

## Documentation

Full documentation: https://docs.noctalia.dev

## Switching Back to Waybar or DMS

Simply change `barChoice` in your `variables.nix`:
- `barChoice = "waybar"` - Use Waybar
- `barChoice = "dms"` - Use Dank Material Shell
- `barChoice = "noctalia"` - Use Noctalia Shell

Then rebuild: `dcli rebuild`
