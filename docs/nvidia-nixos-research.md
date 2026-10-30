# NVIDIA on NixOS

Research checked 30 October 2026 for `wassaa` with an RTX 2080, Hyprland, and Brave. Actual NixOS evaluation and playback have not been tested.

## Existing configuration

- The [NVIDIA module](../modules/drivers/nvidia-drivers.nix) already enables modesetting and uses the kernel-matched stable driver. [wassaa](../hosts/wassaa/default.nix) selects NVIDIA's open kernel modules; NVIDIA supports Turing GPUs including the RTX 2080. The userspace driver remains proprietary. [NVIDIA documentation](https://download.nvidia.com/XFree86/Linux-x86_64/595.112.07/README/kernel_open.html)
- The [locked NixOS NVIDIA module](https://github.com/NixOS/nixpkgs/blob/31ecbaca1bdefa45dffc409f0250bd8039ea0010/nixos/modules/hardware/video/nvidia.nix) enables `hardware.nvidia.videoAcceleration` by default and adds `nvidia-vaapi-driver` to `hardware.graphics.extraPackages`. It also configures DRM modesetting and, on this driver generation, fbdev.
- The [locked VA-API package](https://github.com/NixOS/nixpkgs/blob/31ecbaca1bdefa45dffc409f0250bd8039ea0010/pkgs/development/libraries/nvidia-vaapi-driver/default.nix) is version 0.0.18. Its [release notes](https://github.com/elFarto/nvidia-vaapi-driver/releases/tag/v0.0.18) describe a Chromium-compatible decode path.

## Published configurations

- [nixos-hardware's Turing profile](https://github.com/NixOS/nixos-hardware/blob/master/common/gpu/nvidia/turing/default.nix) selects open modules where supported.
- [ZaneyOS's NVIDIA module](https://gitlab.com/Zaney/zaneyos/-/blob/main/modules/drivers/nvidia-drivers.nix) uses a similar stable-driver and modesetting baseline.
- [LinuxBeginnings NixOS-Hyprland](https://github.com/LinuxBeginnings/NixOS-Hyprland/blob/main/modules/nvidia-drivers.nix) enables graphics and modesetting and explicitly adds the VA-API bridge. Explicitly adding it is redundant with this checkout's locked NixOS module.
- [ryan4yin's NVIDIA desktop configuration](https://github.com/ryan4yin/nix-config/blob/main/hosts/idols-ai/hardware-nvidia.nix) also uses open modules, modesetting, and a production driver. It targets different hardware, so its additional settings are not automatically relevant to `wassaa`.

## Brave experiment

[The wassaa configuration](../hosts/wassaa/default.nix) selects the NVIDIA VA-API driver and its direct backend system-wide. Applications must still support and enable VA-API themselves. [Brave's configuration](../modules/home/features/desktop/brave.nix) does not explicitly enable Chromium's experimental `VaapiOnNvidiaGPUs` feature, allowing the system-wide selection to be tested on its own. Chromium disables this feature by default, so Brave may still reject NVIDIA decoding even if the driver is available.

The [driver's versioned instructions](https://github.com/elFarto/nvidia-vaapi-driver/blob/v0.0.18/README.md#chrome) describe a Chromium-compatible path, but [Chromium](https://chromium.googlesource.com/chromium/src/+/156.0.8078.48/docs/gpu/vaapi.md) still treats NVIDIA VA-API as experimental. The direct backend uses an unstable NVIDIA interface and can regress after driver updates. The bridge only decodes video; it does not provide encoding.

After deploying, quit Brave completely, reopen it, and play a known H.264 video. In `brave://media-internals`, check the selected video's decoder and platform-decoder status. `brave://gpu` can show supported capabilities but does not prove a particular stream is hardware decoded. The RTX 2080 does not support AV1 hardware decoding, so AV1 fallback alone is not evidence that H.264 decoding failed. [NVIDIA codec capabilities](https://docs.nvidia.com/video-technologies/video-codec-sdk/13.0/nvdec-video-decoder-api-prog-guide/index.html#video-decoder-capabilities)