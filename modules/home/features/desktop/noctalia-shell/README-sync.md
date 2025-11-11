# Noctalia GUI to Nix Sync Script

## Overview

The `sync-from-gui.py` script allows you to configure Noctalia through the GUI and then sync those changes back to your Nix configuration. This makes it easy to:

1. Use the visual GUI to configure your bar
2. Have changes persist immediately
3. Optionally sync to Nix for reproducibility across hosts

## Quick Start

```bash
# 1. Configure Noctalia through the GUI (changes save automatically)

# 2. Sync to Nix (choose one method):
#    Method A: Use keybind (easiest)
#      Press: Ctrl+Shift+S
#      (Shows notification when complete)
#
#    Method B: Run script manually
cd /home/don/black-don-os/modules/home/noctalia-shell
./sync-from-gui.py

# 3. Test the build
dcli build leno-desktop

# 4. Apply changes
dcli rebuild

# 5. Commit to git
git add default.nix
git commit -m "Update Noctalia template from GUI"
```

## Keybind

**Ctrl+Shift+S** - Sync Noctalia GUI settings to Nix template

- Works from anywhere in your desktop
- Shows a notification when complete
- Automatically backs up old config
- No need to open a terminal!

## What It Does

The script:
- ✅ Reads your current `~/.config/noctalia/settings.json`
- ✅ Backs up the current `default.nix` to `backups/`
- ✅ Converts JSON to Nix attribute set format
- ✅ Updates `default.nix` with your settings
- ✅ Preserves the template-based approach (writable config)

## Usage

### Basic Usage

**Option 1: Keybind (Recommended)**
```
Press: Ctrl+Shift+S
```
A notification will appear when syncing is complete.

**Option 2: Manual Script**
```bash
./sync-from-gui.py
```

### Full Workflow Example
```bash
# Start: Configure through Noctalia GUI
# - Open Noctalia settings
# - Change colors to Catppuccin
# - Rearrange widgets
# - Adjust bar position/size
# - Changes save automatically

# Sync to Nix template
cd modules/home/noctalia-shell
./sync-from-gui.py

# Review what changed
git diff default.nix

# Test build
dcli build leno-desktop

# Apply if happy
dcli rebuild

# Commit
git add default.nix backups/
git commit -m "feat(noctalia): update bar layout"
```

## How It Works

### Before Sync
- GUI settings in: `~/.config/noctalia/settings.json` (writable file)
- Nix template in: `modules/home/noctalia-shell/default.nix`
- They may be **out of sync**

### After Sync
- GUI settings copied to Nix template
- Template used for fresh installs/resets
- Current working config unchanged

### File Structure
```
modules/home/noctalia-shell/
├── default.nix              # Nix config (updated by script)
├── sync-from-gui.py         # The sync script
├── backups/                 # Timestamped backups
│   └── default.nix.20251026_141221
└── README-sync.md           # This file
```

## When to Use This Script

### Use the script when:
- ✅ You've configured the bar perfectly in GUI
- ✅ You want to apply these settings to other hosts
- ✅ You want to save your config for future fresh installs
- ✅ You want version control over your bar config

### Don't need the script when:
- ❌ Just trying things out in the GUI
- ❌ Making temporary changes
- ❌ Your settings are already working (they persist automatically)

## Important Notes

### Your Current Settings Are Safe
Running this script does **NOT** change your current working configuration. It only updates the Nix template that's used for:
- Fresh installations
- When you delete `~/.config/noctalia/settings.json`
- Other hosts when they first build

### Backups
Every time you run the script, it creates a backup:
```bash
backups/default.nix.YYYYMMDD_HHMMSS
```

To restore a backup:
```bash
cp backups/default.nix.20251026_141221 default.nix
```

### Settings That Persist Automatically
These change immediately without needing the script:
- Widget arrangement
- Colors/themes
- Bar position and size
- Notification settings
- All GUI-configurable options

### Settings That Need Nix Rebuild
These require editing `default.nix` directly:
- Enabling/disabling Noctalia entirely
- Switching between Noctalia/Waybar
- System-level integrations

## Troubleshooting

### Error: Settings file is a symlink
```
Warning: Settings file is a symlink (read-only)
```
**Solution**: Run `dcli rebuild` first to get the writable config.

### Error: Settings file not found
```
Error: Settings file not found at ~/.config/noctalia/settings.json
```
**Solution**: Open Noctalia and configure it through the GUI first.

### Error: Invalid JSON
```
Error: Invalid JSON in settings file
```
**Solution**: Your settings file is corrupted. Delete it and rebuild:
```bash
rm ~/.config/noctalia/settings.json
dcli rebuild
```

## Technical Details

### JSON to Nix Conversion
The script converts JSON to Nix attribute set format:

**JSON:**
```json
{
  "bar": {
    "position": "top",
    "widgets": [
      {"id": "Clock"}
    ]
  }
}
```

**Nix:**
```nix
{
  bar = {
    position = "top";
    widgets = [
      {
        id = "Clock";
      }
    ];
  };
}
```

### Template Mechanism
The Nix config uses a template approach:

1. **Template created**: `settings.json.template` (managed by Nix)
2. **One-time copy**: Copied to `settings.json` only if it doesn't exist
3. **User edits**: All GUI changes save to writable `settings.json`
4. **Persistence**: Rebuilds don't overwrite existing `settings.json`

This gives you both:
- Nix reproducibility (for fresh installs)
- User freedom (for day-to-day tweaking)

## See Also

- Main docs: `/home/don/black-don-os/claude/noctalia-gui-editable-config.md`
- Noctalia config: `default.nix`
- User settings: `~/.config/noctalia/settings.json`
- Noctalia docs: https://docs.noctalia.dev

## Created
October 26, 2025
