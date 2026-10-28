# Voicemeeter-style audio on NixOS

## Existing setup

The audio feature enables PipeWire with ALSA, PulseAudio and JACK compatibility. The desktop packages include EasyEffects and pavucontrol. The multimedia feature's `enableMediaRouting` opt-in installs OBS Studio and qpwgraph and defines the virtual devices below; it is enabled on `wassaa` only. Enabling it on another host also requires `enableMultimedia` and PipeWire audio. These changes have not yet been tested on the NixOS machine.

## First use on wassaa

After deploying the configuration and rebooting to apply the camera module options:

1. Open qpwgraph and connect the Scarlett microphone's desired input channel to **Microphone Proxy**. Select **Microphone Proxy** as the input in the call application and check its input meter. The proxy has no predefined microphone connection, so it is silent until connected.
2. To share application audio, connect its playback output to **Microphone Proxy** in qpwgraph. Keep a separate connection to your headphones if you also want to hear it. Disconnect the sharing link when finished, and keep call audio out of the microphone proxy to avoid echo.
3. Use **OBS Track 1** and **OBS Track 2** as separate application audio buses. Route the desired playback streams to them, and add their monitor sources as audio inputs in OBS. Connect the buses' monitor outputs to headphones if you need to hear them. Configure OBS tracks and avoid also capturing the same audio through desktop audio.
4. In OBS, add your camera as a video source and select **Start Virtual Camera**. Select **OBS Virtual Camera** in the receiving application. With exclusive capabilities enabled, the device may not appear in the application until OBS starts the virtual camera.

The devices are declarative, but the routing and OBS scene are manual. qpwgraph can save an activated patchbay for chosen links; do not pin a browser-to-microphone link unless it should be restored automatically. Test audio levels, channel mapping, monitoring and behavior after reconnecting the Scarlett before using the setup live. No independent per-destination mixer or automatic browser-sharing toggle is configured.

## Options

| Component | Role | Trade-off |
| --- | --- | --- |
| PipeWire virtual sinks and loopbacks | Create named buses, link sources to sinks, and expose a mix as an input. | Flexible building blocks rather than a complete mixer UI. A sink monitor may need a virtual source wrapper for applications that do not list monitors. [PipeWire loopback documentation](https://pipewire.pages.freedesktop.org/pipewire/page_module_loopback.html), [Pulse-compatible modules](https://pipewire.pages.freedesktop.org/pipewire/page_pulse_modules.html) |
| qpwgraph | Inspect and connect PipeWire nodes visually; save and activate pinned connections. | A patchbay, not a Voicemeeter-style bank of mix faders. Saved patchbays must be loaded and activated; exclusive mode removes other connections. [qpwgraph patchbay documentation](https://github.com/rncbc/qpwgraph/blob/main/docs/qpwgraph_patchbay-user_manual.md) |
| pavucontrol | Change application playback devices and stream levels. | Useful for everyday control, but not a full matrix mixer. |
| EasyEffects | Process the microphone with effects such as EQ and dynamics. | Complements routing rather than replacing it. Upstream advises against setting its virtual devices as system defaults. [EasyEffects](https://github.com/wwmm/easyeffects) |
| OBS Studio and PipeWire audio capture plugin | Give a stream separate audio sources and faders, including individual application capture. | The stream mix is tied to OBS; the plugin must be installed separately and requires WirePlumber. Avoid capturing the same signal twice. [OBS PipeWire capture plugin](https://github.com/dimtpap/obs-pipewire-audio-capture) |
| Carla | Host plugins and build a more sophisticated rack or patchbay. | More complex and closer to a music-production tool than a ready-made desktop mixer. [Carla](https://github.com/falkTX/Carla) |
| ALSA Scarlett Control Panel | Adjust supported Scarlett hardware controls and routing. | Capabilities depend on the exact interface and generation; it does not replace per-application PipeWire routing. [Supported hardware and installation](https://github.com/geoffreybennett/alsa-scarlett-gui/blob/master/docs/INSTALL.md) |

Package availability and plugin compatibility must be checked against this flake's locked nixpkgs revision before implementation.

## Suggested starting design

1. Create a named **Voice Bus** virtual sink and expose its monitor, or an explicit virtual source fed from it, as **Virtual Mic**.
2. Send the selected Scarlett microphone channel to Voice Bus, optionally through EasyEffects. Route a chosen browser playback stream into that bus only when sharing is wanted.
3. Keep the normal listening output separate. When the browser is routed to Voice Bus, also provide a separate path from that browser audio to headphones so it remains audible. Avoid monitoring the entire Voice Bus if hearing your own microphone is undesirable.
4. Select Virtual Mic in the calling application. Exclude that application's incoming audio from Voice Bus so callers do not hear themselves. Use headphones and test at low volume to avoid acoustic feedback.
5. In OBS, capture the desired mic and application streams separately, with independent levels and mute controls. Do not simultaneously capture their combined bus unless deliberately avoiding duplicates.

These are logical paths, not a tested configuration. In particular, fan-out and per-destination levels may need explicit loopbacks or a mixer, and some browsers may combine multiple tabs into one audio stream. Automatic routing, device reconnection, mono/stereo handling, monitoring latency and application visibility need testing on the target machine. Keep browser-to-mic sharing explicitly opt-in and verify the selected source before calls or streams.

Use PipeWire configuration for stable named devices and qpwgraph for exploration; a saved, activated patchbay or suitable WirePlumber policy can restore chosen links. WirePlumber's stream-linking policy also influences automatic connections. [PipeWire loopback](https://pipewire.pages.freedesktop.org/pipewire/page_module_loopback.html), [WirePlumber linking policy](https://pipewire.pages.freedesktop.org/wireplumber/policies/linking.html)

## Scarlett 2i2 generation

The 4th-generation 2i2 has a hardware routing matrix, mixer and loopback channels; its line and headphone outputs remain linked. The 3rd-generation 2i2 has more limited hardware controls. Identify the generation before assuming either capability or driver support. [4th-generation control panel guide](https://github.com/geoffreybennett/alsa-scarlett-gui/blob/master/docs/iface-4th-gen-small.md), [3rd-generation guide](https://github.com/geoffreybennett/alsa-scarlett-gui/blob/master/docs/iface-small.md)

## Real-world configurations

These are creators' own setups or experiments, not verified configurations for the Scarlett. None demonstrates independently adjustable per-source levels for both a live stream and a virtual-mic mix.

- **Beko Pharm, [OBS, virtual mic and selective game audio](https://beko.famkos.net/2022/04/18/virtual-sinks-and-mic-with-obs-and-pipewire-on-linux-pc/) (2022):** A null sink and remapped source expose OBS monitoring as a virtual mic for calls; OBS sends the real mic and selected game/music to both that bus and the stream, with separate recording tracks. A combined sink also sends game audio to headphones, while Discord playback stays out of the shared mix. Copy the routing concept, OBS monitor/track settings and the [Helvum graph](https://beko.famkos.net/wp-content/uploads/2022/04/the-whole-mess-in-helvum.png); adapt hardware names and avoid monitoring the virtual mic into itself. The author uses PipeWire's PulseAudio-compatible commands and says the steps also work with PulseAudio. The demonstrated call and stream mixes share sources; this is not an independent mix matrix.
- **de-monastery, [NixOS microphone proxy and OBS tracks](https://demonastery.org/2023/04/virtual-camera-and-audio-on-linux/) (2023):** A native PipeWire mono virtual source receives manually connected inputs in Helvum, while two sinks separate game/application audio and Discord into OBS recording tracks. Copy the named proxy and separate-bus design; adapt it to the Scarlett and test current NixOS/PipeWire versions. The author mentions application sounds as a possible mic input, not a demonstrated browser-plus-mic mix. Manual patching and separate recording tracks do not establish persistent links or independent live mixes.
- **frozen.frog23, [NixOS LibreWolf-to-virtual-mic experiment](https://discourse.nixos.org/t/pipewires-extraconfig-wireplumbers-extraconfig-virtual-microphone-source-confusion/68154/6) (2025):** A PipeWire loopback targets the LibreWolf playback node and exposes an `Audio/Source` to a chat application; a stream rule prevents automatic speaker connection. Copy the idea of targeting a particular application and guarding against fallback, not the entire experimental configuration. The author reports poor audio quality and an unresolved cause; this does not combine a physical microphone or demonstrate a stream mix, and needs a separate listening path.
- **Josh, [scripted application plus microphone](https://superuser.com/a/1755921) ([accessible answer via Stack Exchange API](https://api.stackexchange.com/2.3/answers/1755921?site=superuser&filter=withbody)) (2022):** The author uses PipeWire links to combine a named application's stereo output and a physical mic into a virtual source for Skype and OBS, without returning other callers' audio. Copy the explicit app-plus-mic routing idea and adapt channel and node names for the Scarlett. The script assumes uniquely named stereo ports and **unloads active null-sink modules**, so do not run it unchanged; it makes one combined virtual mic, not independent mixes. The ordinary answer page was inaccessible during verification; the linked API returned the answer.

For this setup, Beko's is the closest complete live-call/stream example; de-monastery's is the clearest NixOS building block. The other two are narrower first-person experiments, not complete tutorials. These sources were read, not run or audio-tested, and none establishes a Scarlett 2i2-specific configuration.