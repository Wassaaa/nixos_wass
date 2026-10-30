# Brave on Wayland and Hyprland

Research checked 30 October 2026. Runtime behavior and installed versions on the NixOS hosts were not tested.

## Current configuration

- [Hyprland](../modules/home/features/desktop/hyprland/hyprland.nix) sets `NIXOS_OZONE_WL=1` and enables XWayland. The environment variable alone does not establish which backend a running window uses.
- [Brave](../modules/home/features/desktop/brave.nix) disables `WaylandWpColorManagerV1`, a workaround for a [multi-monitor crash](https://github.com/brave/brave-browser/issues/49921). Brave closed that issue after merging Chromium 142.0.7444.53; users confirmed the fix in Brave 1.84.130 without the workaround. Whether this configuration still needs it is unverified.
- The [portal configuration](../modules/core/features/desktop/portals.nix) selects Hyprland and GTK backends for Hyprland sessions. Portal availability does not prove that screen sharing works.

## Reported issues

- An [open report](https://github.com/brave/brave-browser/issues/57885) describes black AV1 video on NVIDIA and Wayland with graphics acceleration enabled; another report includes Hyprland. The original reporter found software decoding succeeded but frames were not presented. This is not evidence that all NVIDIA or Hyprland setups are affected.
- An [open report](https://github.com/brave/brave-browser/issues/60257) describes one Brave 1.98.60 process consuming a CPU core on Hyprland. The reporter had no reliable reproduction and had not compared a clean profile or XWayland.
- An [open report](https://github.com/brave/brave-browser/issues/59781) describes software video decoding on an AMD/Sway setup despite the GPU page reporting acceleration. It is not a Hyprland-specific finding.
- An [open report](https://github.com/brave/brave-browser/issues/51651) describes a screen-capture portal failure on one Hyprland/OpenRC setup; it does not establish a general Brave defect.

## Checks

1. In `brave://version`, record the Brave and Chromium versions and command line. Quit Brave completely before comparing launch arguments because a new invocation can reuse the existing browser process.
2. Inspect Brave's window in `hyprctl clients`: `xwayland: 0` means native Wayland and `xwayland: 1` means XWayland. `brave://gpu` may also show `Ozone platform: wayland`. The session type and browser user-agent string do not prove the window backend. [Chromium Ozone](https://chromium.googlesource.com/chromium/src/+/main/docs/ozone_overview.md)
3. Check `brave://gpu` for hardware-accelerated compositing and WebGL, the renderer, and problems or logs. SwiftShader or llvmpipe indicates software rendering for the relevant path; disabled Vulkan alone does not mean GPU acceleration is broken. [Chromium GPU debugging](https://chromium.googlesource.com/chromium/src/+/main/docs/gpu/debugging_gpu_related_code.md)
4. While a video plays, inspect its player in `brave://media-internals` for codec, decoder and platform-decoder status. `VaapiVideoDecoder` indicates VA-API selection; decoder names can vary. GPU capabilities or `vainfo` alone do not prove hardware decoding of the current video. Test relevant codecs independently. [Chromium VA-API](https://chromium.googlesource.com/chromium/src/+/main/docs/gpu/vaapi.md)
5. Test actual window and screen capture with the [WebRTC display-capture sample](https://webrtc.github.io/samples/src/content/getusermedia/getdisplaymedia/), then test the meeting application and verify received video. Check application audio and microphone separately. [ScreenCast portal API](https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.ScreenCast.html)

Avoid adding large flag bundles or disabling GPU acceleration or sandboxing without a specific problem and a controlled comparison. Review diagnostic output for sensitive URLs and paths before sharing it.