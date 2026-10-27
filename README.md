<div align="center">

## Based on ZaneyOS 🟰 Best ❄️ NixOS Configs

ZaneyOS is a simple way of reproducing my configuration on any NixOS system.
This includes the wallpaper, scripts, applications, config files, and more.

<img align="center" width="80%" src="https://gitlab.com/Zaney/zaneyos/-/raw/main/demo.png" />

**Inspiration for the Waybar config
[here](https://github.com/justinlime/dotfiles).**

</div>

> **This project has a [Wiki (Modified so not everything applies)](https://zaney.org/wiki/zaneyos-2.3/). Find out how
> to use ZaneyOS here!** **I have put a lot of effort into the
> [documentation (Modified so not everything applies)](https://zaney.org/wiki/zaneyos-2.3/) so it should be accurate.
> However, please if you notice that something is wrong with it create an issue
> or reach out to me on Discord.**

### ⚠️ Modified Version

This is a modified version of ZaneyOS. To get it working, please look through the files and figure it out.

#### 🍖 Requirements

- You must be running on NixOS.
- The zaneyos folder (this repo) is expected to be in your home directory.
- Manually editing your host specific files. The host is the specific computer
  your installing on.

#### 🎹 Pipewire & Notification Menu Controls

- We are using the latest and greatest audio solution for Linux. Not to mention
  you will have media and volume controls in the notification center available
  in the top bar.

#### 🏇 Optimized Workflow & Simple Yet Elegant Neovim

- Using Hyprland for increased elegance, functionality, and effeciency.
- No massive Neovim project here. This is my simple, easy to understand, yet
  incredible Neovim setup.

#### 🖥️ Multi Host & User Configuration

- You can define separate settings for different host machines and users.
- Easily specify extra packages for your users in the modules/core/user.nix
  file.
- Easy to understand file structure and simple, but encompassing,
  configuratiion.

#### Gaming

The `enableGaming` host feature installs Steam and Gamescope. Steam's built-in
Proton versions handle Windows games; Gamescope is optional per game. To run a
game in fullscreen Gamescope, set its Steam launch options to:

```text
gamescope -f -- %command%
```

Steam Remote Play firewall ports are not opened by default.

#### NVIDIA on wassaa

The RTX 2080 uses NVIDIA's open kernel modules and the stable driver from the
locked Nixpkgs revision. After changing the driver or kernel module flavor,
build with `nh os boot` and reboot to load it. Keep a working boot generation
available in case the new configuration needs to be rolled back.

#### 🙋 Having Issues / Questions?

- look at [Original ZaneyOS](https://gitlab.com/Zaney/zaneyos/-/tree/main?ref_type=heads) maybe some hints.
