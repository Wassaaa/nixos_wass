# webapp-install - Web App Installer for Black Don OS

A NixOS-integrated script for creating desktop entries for web applications using Helium browser, inspired by Omarchy's webapp installer.

## Features

- **Interactive Mode**: Guided prompts using `gum` for easy webapp creation
- **Direct Mode**: Command-line arguments for scripting and automation
- **Icon Management**: Downloads icons from URLs or uses local files
- **NixOS Integration**: Properly paths all dependencies through Nix
- **Helium Browser**: Uses Helium browser's app mode for native-like experience

## Installation

The script is already included in your Black Don OS configuration. After rebuilding your system, the `webapp-install` command will be available:

```bash
dcli rebuild
```

## Usage

### Interactive Mode (Recommended)

Simply run without arguments for guided prompts:

```bash
webapp-install
```

You'll be prompted to enter:
1. **App Name** - The display name for your webapp
2. **URL** - The website URL to open
3. **Icon URL** - A PNG icon URL (or local filename)

### Direct Mode

For scripting or quick creation:

```bash
webapp-install "App Name" "https://example.com" "https://example.com/icon.png"
```

With optional parameters:

```bash
webapp-install "App Name" "URL" "icon.png" "custom-exec-command" "application/pdf"
```

## Arguments

| Position | Name | Required | Description |
|----------|------|----------|-------------|
| 1 | APP_NAME | Yes | Display name of the web application |
| 2 | URL | Yes | Website URL to open |
| 3 | ICON_REF | Yes | Icon URL (PNG) or local filename |
| 4 | CUSTOM_EXEC | No | Custom execution command (defaults to Helium) |
| 5 | MIME_TYPES | No | MIME types for file associations |

## Examples

### Create YouTube Music webapp

```bash
webapp-install "YouTube Music" "https://music.youtube.com" "https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/youtube-music.png"
```

### Create GitHub webapp

```bash
webapp-install "GitHub" "https://github.com" "https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/github.png"
```

### Create Gmail webapp

```bash
webapp-install "Gmail" "https://mail.google.com" "https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/gmail.png"
```

### Using a local icon

First, place your icon in `~/.local/share/applications/icons/`, then:

```bash
webapp-install "My App" "https://example.com" "myicon.png"
```

## Icon Resources

Find high-quality icons for your webapps:

- **Dashboard Icons**: https://dashboardicons.com
- **Simple Icons**: https://simpleicons.org
- **Icon URLs must be PNG format**

## How It Works

1. **Icon Handling**: 
   - If an HTTP(S) URL is provided, downloads the icon to `~/.local/share/applications/icons/`
   - If a filename is provided, assumes icon exists locally

2. **Desktop Entry Creation**:
   - Creates a `.desktop` file in `~/.local/share/applications/`
   - Sets Helium browser as the launcher with `--app` flag
   - Makes the entry executable

3. **App Launcher Integration**:
   - The webapp appears in your system app launcher immediately
   - Can be found via search (SUPER + SPACE on Hyprland)

## Generated Files

Desktop entries are created at:
```
~/.local/share/applications/AppName.desktop
```

Icons are stored at:
```
~/.local/share/applications/icons/AppName.png
```

## Customization

### Using a Different Browser

Override the execution command:

```bash
webapp-install "App" "https://example.com" "icon.png" "firefox --new-window https://example.com"
```

### Adding MIME Type Associations

Associate file types with your webapp:

```bash
webapp-install "PDF Viewer" "https://pdfviewer.com" "icon.png" "" "application/pdf;application/x-pdf"
```

## Troubleshooting

### Icon not downloading

- Ensure the URL is a direct link to a PNG file
- Check your internet connection
- Try downloading the icon manually and using the local path

### Webapp not appearing in launcher

- Wait a few seconds for the desktop environment to refresh
- Try logging out and back in
- Check that the desktop file was created: `ls ~/.local/share/applications/`

### Helium not launching

- Verify Helium is installed: `which helium`
- If not installed, rebuild your system: `dcli rebuild`
- Check the desktop file: `cat ~/.local/share/applications/AppName.desktop`

## Comparison with Omarchy

This implementation is inspired by Omarchy's webapp installer but adapted for Black Don OS:

| Feature | Omarchy | Black Don OS |
|---------|---------|--------------|
| Browser | Custom launcher | Helium browser |
| Package Manager | System packages | Nix packages |
| Dependencies | System-wide | Nix store paths |
| Interactive Mode | ✅ gum | ✅ gum |
| Icon Download | ✅ curl | ✅ curl (nix) |
| Desktop Entry | ✅ | ✅ |

## Integration with Black Don OS

The script is integrated into your dotfiles at:
```
modules/home/scripts/webapp-install.nix
```

It's automatically included in your user environment through:
```
modules/home/scripts/default.nix
```

## Contributing

To modify the script:

1. Edit `modules/home/scripts/webapp-install.nix`
2. Test your changes: `dcli build <your-host>`
3. Deploy: `dcli rebuild`

## License

Part of Black Don OS - see repository license.
