# NixOS Configuration - AI Coding Agent Guide

## Architecture Overview

This is a **feature-based NixOS flake configuration** (derived from ZaneyOS) supporting multi-host, multi-user setups with granular feature control. The architecture uses conditional imports driven by per-host variables rather than monolithic configurations.

### Key Design Patterns

**1. Feature Toggle System** (`modules/core/features.nix`, `modules/home/features.nix`)

- Each host defines feature flags in `hosts/{HOST}/variables.nix` (e.g., `enableGaming`, `enableDesktop`, `enableVirtualization`)
- Feature modules are conditionally imported using `lib.optionals` based on these flags
- Prevents bloat: server hosts don't import desktop modules, laptops don't import gaming packages

**2. Host-Specific Configuration Pattern**

```nix
# Common pattern throughout codebase - importing per-host variables
inherit (import "${flakeRoot}/hosts/${host}/variables.nix")
  enableGaming enableDesktop gitUsername;
```

- Variables live in `hosts/{HOST}/variables.nix` (NOT in the modules themselves)
- Access via dynamic import with `${flakeRoot}` and `${host}` specialArgs
- Examples: keyboard layouts, monitor configs, git credentials, feature toggles

**3. Profile-Based Driver Selection** (`profiles/`)

- Profiles (`nvidia`, `intel`, `vm`, `wsl`) set hardware driver enables in one place
- Use module options pattern: `drivers.nvidia.enable = true;` in profile
- Individual driver modules live in `modules/drivers/` with option definitions

**4. Secrets Management with SOPS** (`modules/core/sops/`)

- Per-host encrypted secrets: `hosts/{HOST}/secrets.yaml`
- Age keys derived from SSH host keys (`.sops.yaml` maps host → age key)
- Automatic decryption via `config.sops.secrets.{NAME}.path`
- Example: `hashedPasswordFile = config.sops.secrets.password.path;`

### Directory Structure Logic

```
flake.nix               # Multi-host definitions (wassaa, tpad, wsl)
profiles/               # Hardware presets (nvidia, intel, vm, wsl)
hosts/{HOST}/           # Per-host config: default.nix, variables.nix, secrets.yaml, hardware.nix
  └─ host-packages.nix  # Host-specific packages beyond core/features
modules/
  ├─ core/              # System-level (NixOS) modules
  │  ├─ features/       # Optional feature groups (desktop, gaming, etc.)
  │  └─ sops/           # Secrets management
  ├─ home/              # User-level (Home Manager) modules
  │  └─ features/       # User feature groups (core always loaded, desktop/gaming conditional)
  └─ drivers/           # Hardware driver modules with enable options
```

## Critical Workflows

### Building & Deploying

```bash
# Using nh (NixOS helper - configured in modules/core/nh.nix)
nh os switch              # Apply changes (auto-detects flake location)
nh os test                # Test changes (doesn't set bootloader)
nh os boot                # Build and set bootloader (apply on next boot)
nh clean --keep 5         # Keep 5 generations, clean rest (already configured)

# Direct nixos-rebuild (if nh unavailable)
sudo nixos-rebuild switch --flake /home/wassaa/nixos_wass#wassaa
```

### Adding a New Host

1. Create `hosts/{NEW_HOST}/` directory
2. Copy and modify `variables.nix`, `default.nix`, `hardware.nix` from existing host
3. Generate SSH host key and convert to age:
   ```bash
   sudo cat /etc/ssh/ssh_host_ed25519_key.pub > hosts/{NEW_HOST}/ssh_host_ed25519_key.pub
   nix-shell -p ssh-to-age --run "ssh-to-age < hosts/{NEW_HOST}/ssh_host_ed25519_key.pub"
   ```
4. Add age key to `.sops.yaml` under `keys:` and `creation_rules:`
5. Create `hosts/{NEW_HOST}/secrets.yaml` with `sops hosts/{NEW_HOST}/secrets.yaml`
6. Add host to `flake.nix` `nixosConfigurations` using `mkSystem`

### Secrets Management (Quick Reference)

```bash
# Edit existing secrets
sops hosts/wassaa/secrets.yaml

# Add new user for editing (after generating age key)
# 1. Get public age key: ssh-to-age < ~/.ssh/id_ed25519.pub
# 2. Add to .sops.yaml under keys: and relevant creation_rules
# 3. Update existing secrets: sops updatekeys hosts/wassaa/secrets.yaml
```

### Updating Custom Flake Inputs

```bash
# VSCode Insiders (auto-updated via GitHub Actions every 3h)
code-update  # Updates vscode-insiders flake input and rebuilds

# NordVPN (custom update script)
update-nordvpn  # or nordvpn-update (fish alias)
# Script in modules/core/nordvpn/update-nordvpn.sh auto-updates version + sha256
```

## Project Conventions

### Desktop Environment

- **Primary DE**: Hyprland (`modules/home/features/desktop/hyprland/`)
- **Keep alternatives working**: GNOME/other DEs should remain functional even if not actively used
- Hyprland is split into modular files: `binds.nix`, `monitors.nix`, `config.nix`, `hypridle.nix`, `hyprlock.nix`, `pyprland.nix`

### When Adding Packages/Features

- **Core utilities** → `modules/core/packages.nix` (minimal CLI tools, work everywhere)
- **Feature-specific** → `modules/core/features/{FEATURE}/packages.nix` (e.g., `desktop/packages.nix`)
- **Host-specific** → `hosts/{HOST}/host-packages.nix` (unique to one machine)
- **User packages** → `modules/home/features/{FEATURE}/` (dotfiles, user configs)
- **New additions should be featurized** - Use feature flags (`enableDesktop`, `enableGaming`, etc.) rather than adding to core unless universally needed

### Module Pattern

```nix
# All driver/service modules follow this option-based pattern
{ lib, config, ... }:
with lib;
let
  cfg = config.drivers.nvidia;  # or services.myservice
in {
  options.drivers.nvidia = {
    enable = mkEnableOption "Enable Nvidia Drivers";
  };
  config = mkIf cfg.enable {
    # Actual configuration here
  };
}
```

### Home Manager Integration

- Home Manager configured in `modules/core/user.nix` via `home-manager.users.${username}`
- User modules import tree: `modules/home/default.nix` → `features.nix` → conditional feature imports
- User configs reference host variables same way: `inherit (import "${flakeRoot}/hosts/${host}/variables.nix") ...`

### specialArgs Pattern

These are always available in modules (set in `flake.nix`):

- `inputs` - flake inputs (nixpkgs, home-manager, stylix, etc.)
- `username`, `host`, `profile` - current host info
- `flakeRoot` - path to repo root (`./.`)
- `stable` - stable nixpkgs instance for fallback packages

### Shell Configuration & Aliases

- **Default shell**: Fish (set per-host in `variables.nix` via `myshell`)
- **Alias duplication**: Shell aliases are currently duplicated across `fish.nix`, `zsh.nix`, and `bash.nix`
- **TODO**: Consider extracting common aliases to single source of truth (e.g., `modules/home/features/core/shell-aliases.nix`)
- Current useful aliases: `fr` (rebuild switch), `fb` (rebuild boot), `fu` (rebuild + update), `code-update`, `nordvpn-update`

## Common Pitfalls

1. **Don't hardcode paths** - Use `${flakeRoot}` or `./relative/path`
2. **Feature flags** - Check `hosts/{HOST}/variables.nix` to enable new features, not just adding imports
3. **Secrets** - Always use `config.sops.secrets.{NAME}.path`, never plaintext in `.nix` files
4. **Profile vs Host** - Profile sets drivers (`profiles/nvidia/`), host sets everything else (`hosts/wassaa/`)
5. **Module imports** - System modules go in `modules/core/`, user configs in `modules/home/`
6. **Stylix theming** - Global theme controlled by Stylix (imported in `modules/core/default.nix`)

## Custom Flake Patterns

### VSCode Insiders Auto-Update Pattern

- **Custom flake**: `inputs.vscode-insiders` (from `github:Wassaaa/code-insiders-flake`)
- **GitHub Actions**: Auto-updates `meta.json` (version, sha256, url) every 3 hours
- **Usage**: `code-update` alias runs `nix flake update vscode-insiders` and rebuilds
- **Pattern structure**:
  ```nix
  # Flake reads meta.json with version/sha256/url
  meta = builtins.fromJSON (builtins.readFile ./meta.json);
  package = (pkgs.vscode.override { isInsiders = true; })
    .overrideAttrs (oldAttrs: {
      src = builtins.fetchurl { url = meta.url; sha256 = meta.sha256; };
      version = meta.version;
    });
  ```
- **Reusable for**: Programs without nixpkgs packages or needing frequent updates

## Key Files to Reference

- `flake.nix` - Host definitions and specialArgs setup
- `modules/core/features.nix` - System feature loading logic
- `modules/home/features.nix` - User feature loading logic
- `modules/core/user.nix` - Home Manager integration and user creation
- `modules/core/sops/sops.nix` - Full SOPS setup guide in comments
- `hosts/wassaa/variables.nix` - Example of all available host variables
- `modules/core/nordvpn/` - Example of custom package + service module
- `modules/home/features/desktop/vscode.nix` - Custom flake input usage + settings merging pattern
- `modules/home/features/desktop/hyprland/` - Modular Hyprland configuration (primary DE)
