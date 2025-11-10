# NordVPN Module

NordVPN package and service module for NixOS.

## Structure

```
nordvpn/
├── default.nix           # NixOS module + update script wrapper
├── package.nix           # NordVPN CLI package definition
├── package-gui.nix       # NordVPN GUI package definition
├── update-nordvpn.sh     # Update script (bash)
└── README.md             # This file
```

Simple and clean! Everything you need in 3 files.

## Usage

Import the module in your host configuration:

```nix
imports = [
  ../../modules/core/nordvpn
];
```

### Enable NordVPN Service

```nix
services.nordvpn = {
  enable = true;
  enableGui = true;  # Optional: Enable GUI application (default: false)
  users = [ "yourusername" ];
  includeUpdateScript = true;  # Default: true
};
```

### Update to Latest Version

Simply run:

```bash
update-nordvpn
# or
nordvpn-update  # if using the fish alias
```

The script will:

1. Fetch the latest version from NordVPN's repository
2. Show you the current vs latest version
3. Ask for confirmation before updating
4. Update both `version` and `sha256` in `package.nix`
5. Tell you how to test and apply the update

## Manual Update

If you prefer to update manually:

1. Check latest version:

   ```bash
   curl -sL https://repo.nordvpn.com/deb/nordvpn/debian/dists/stable/main/binary-amd64/Packages | grep -A 15 'Package: nordvpn$'
   ```

2. Edit `package.nix`:

   - Update `version = "x.y.z";`
   - Update `sha256 = "...";`

3. Rebuild:
   ```bash
   sudo nixos-rebuild test
   ```

## How It Works

- **package.nix**: Downloads the official `.deb` package, extracts it, fixes binaries with `autoPatchelfHook`, and wraps the daemon in an FHS environment
- **update-script.nix**: Uses `resholve` to create a robust shell script with all dependencies properly resolved
- **The update script**: Automatically substituted with the correct path to `package.nix` via `@moduleFile@` placeholder
