# WassOS

Personal NixOS and NixOS-WSL configurations, originally based on ZaneyOS.
The flake uses per-host settings, hardware profiles and feature-gated NixOS
and Home Manager modules.

## Hosts

| Flake host | Profile | Purpose |
| --- | --- | --- |
| `wassaa` | NVIDIA | Main desktop, gaming, NordVPN and Tailscale |
| `tpad` | Intel | Laptop desktop |
| `wsl` | WSL | Development environment without the desktop feature |

Host settings live in [`hosts/<host>/variables.nix`](./hosts). Hosts can also
have hardware and host-specific package configuration. Hardware presets live in
[`profiles/`](./profiles); shared system and user configuration live in
[`modules/core/`](./modules/core) and [`modules/home/`](./modules/home).

Host variables control features independently: `enableDesktop`, `enableAudio`,
`enableBluetooth`, `enableSyncthing`, `enableGaming`, `enableDevelopment`,
`enableVirtualization` and `enableMultimedia`. Audio enables PipeWire, including
ALSA, PulseAudio and JACK compatibility. Multimedia provides graphics, codecs
and command-line media tools; desktop applications belong to the desktop feature.
Bluetooth is enabled on `tpad`; Syncthing is available but disabled on all hosts.

## Building and applying

Run these commands on the target NixOS host from the checkout:

```sh
nh os test             # Apply temporarily, without changing the boot default
nh os switch           # Build and switch
nh os boot             # Build for the next boot
```

`nh` and the live-editable Hyprland configuration use the `flakeDir` configured
for the host. Set it to the absolute path of the writable checkout.

To build a specific host without switching:

```sh
nix build .#nixosConfigurations.wassaa.config.system.build.toplevel --no-link
```

`fbd` evaluates the configured host and shows the planned build without
building or switching. Evaluation can fetch flake inputs and may stop at the
first error.

`ncg` runs `nh clean all` with the same retention policy as the weekly cleanup:
keep at least five generations and those from the last seven days, and leave
GC roots, including nix-direnv roots, alone. Cleanup still deletes older
generations and collects unreferenced store paths. Neither cleanup refreshes the
boot menu; the next system switch or boot rebuild does. Preview profile deletions
with `ncg --dry`. In particular,
review the preview after a rollback: the pinned `nh` version does not explicitly
protect a current generation that falls outside both retention criteria.

For a Git-backed flake, add new files to the Git index before building; Nix
otherwise omits untracked files. Review changes with `git status` first. Use a
previous NixOS generation to roll back if a switch causes problems.

## Repository development

The x86_64 Linux development shell supplies Lua, LuaLS, StyLua, Python, `uv`,
`nixd`, `nixfmt` and Git. From the repository root, run `direnv allow` once to
load it automatically, or use `nix develop` for a shell without direnv.
Direnv executes the repository's `.envrc`, so only allow a checkout you trust.
It creates an ignored `.direnv/hyprland-lua` link to LuaLS stubs generated from
the Hyprland revision in `flake.lock`; changing that input regenerates them.
The stubs describe Hyprland's API for the editor and are not runtime code.

For VS Code or Insiders, install the recommended direnv, Lua, StyLua and Nix IDE
extensions, trust the workspace and allow the `.envrc`. The workspace settings
load the generated stubs independently of the editor's launch environment.
After the first direnv load, reload the VS Code window if LuaLS started before
the link existed. The direnv extension provides the environment to integrated
terminals; it does not necessarily change the environment of every extension.
Without direnv, `nix develop` provides the tools but does not create the editor
link. LuaLS can use its bundled language server when the editor was not started
from the development shell.

Run the Hyprland unit tests from the development shell with:

```sh
lua tests/hyprland-monitor-profiles.lua
lua tests/hyprland-theme.lua
```

These tests use small mocks; they do not replace testing inside Hyprland.

For one-off commands supplied through this repository, pull the latest commit
and run `uv run x` from the repository root. The current task and any side
effects are shown before execution; the task changes between troubleshooting
sessions. Actions requiring changes ask for confirmation.

## Desktop

Desktop hosts use Hyprland with Caelestia, Foot and Vicinae. GDM and GNOME
remain available as an alternative session. Caelestia handles locking and
idle in Hyprland. See the [desktop notes](./modules/home/features/desktop/NEW-DESKTOP.md)
for shortcuts, integration and runtime checks.

Set `browser` and `terminal` in each desktop host's variables, for example
[wassaa's](./hosts/wassaa/variables.nix). The browser choice controls
`BROWSER` and browser MIME associations; the terminal choice controls
`TERMINAL`, Hyprland, Caelestia and XDG terminal selection. Current defaults
are `brave` and `footclient`; Chrome remains installed as an alternative.
The command-to-desktop-file mappings live in
[xdg.nix](./modules/home/features/desktop/xdg.nix). Add a mapping and install
the application before selecting another command. Applications that ignore
these defaults may require their own configuration.

Desktop hosts also install the unofficial Windows App web client from pinned
upstream source, using Nixpkgs Electron. Launch **Windows App** from the
application menu or run `windows-app-for-linux`. It can also be built separately:

```bash
nix build .#windows-app-for-linux-wassaa
```

The standalone `windows-app-for-linux` package retains upstream defaults.
On `wassaa`, `windowsAppNativeWaylandOnNvidia` makes the app use native
Wayland instead of XWayland on NVIDIA; X11 sessions retain upstream behavior.
Other hosts keep the upstream NVIDIA workaround unless they opt in through
their host variables. Chromium may still log a Wayland/Vulkan compatibility
warning even when the window opens; verify remote sessions and acceleration
before relying on the app.

The source input is pinned in `flake.nix` and must be recorded in `flake.lock`
with `nix flake lock` when first introduced. Nixpkgs Electron may differ from
upstream's version; verify login and remote sessions before relying on it.
Upstream stores its settings in the user's configuration directory; check
whether existing session data is retained when changing Electron versions.

## Gaming and NVIDIA

`enableGaming` installs Steam and Gamescope. Steam's built-in Proton versions
handle Windows games; Gamescope is optional per game. For fullscreen Gamescope,
set the game's Steam launch options to:

```text
gamescope -f -- %command%
```

Steam Remote Play firewall ports are not opened by default.

The RTX 2080 on `wassaa` uses NVIDIA's open kernel modules and the stable
driver from the locked Nixpkgs revision. After changing the driver or kernel
module flavor, build with `nh os boot` and reboot. Keep a working boot
generation available for rollback.

## Secrets and networking

Host secrets are encrypted with SOPS and age. See
[the SOPS setup guide](./modules/core/sops/sops.nix) and [recipients](./.sops.yaml).
Edit an existing host's secrets with:

```sh
sops hosts/wassaa/secrets.yaml
```

The firewall is enabled without general project-port exceptions. OpenSSH opens
its configured port; other services may manage their own firewall rules.
NordVPN client connections do not need a general inbound OpenVPN port.
On `wassaa`, the NixOS NordVPN service provides the CLI and GUI and enables
systemd-resolved. Its Nixpkgs package does not support Meshnet or NordWhisper.
The host uses loose reverse-path filtering as recommended by Nixpkgs. After a
first switch from the old custom service, check login, DNS, VPN connectivity
and any kill-switch settings; a new login session may be needed for group
membership. The host sets the existing NordVPN data directory's permissions for
the unprivileged daemon. An incompatible legacy configuration may still require
a separately backed-up reset and login; the system configuration does not reset
it automatically. Keep local access and a working generation available during
the migration.
CPU vulnerability mitigations use the kernel defaults; changes to boot
parameters require a reboot.

## Updating inputs

At Hyprland startup, a background check notifies you if the VS Code Insiders
flake has a newer revision. It does not update or rebuild anything. Run
`code-update` to update the flake input and switch the system; restart VS Code
afterward. The check compares Git revisions, so a flake change can trigger a
notification even without a new editor build. Check its log with
`journalctl --user -u vscode-insiders-update-check` if it fails.

The Insiders fork snapshots Microsoft's build every 12 hours when it changes.
NordVPN is updated with Nixpkgs through the flake lockfile. Review lockfile
changes before applying them.
