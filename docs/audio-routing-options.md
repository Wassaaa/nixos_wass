# Audio routing

## Existing setup

The audio feature enables PipeWire with ALSA, PulseAudio and JACK compatibility.
The desktop packages include EasyEffects and pavucontrol. The multimedia
feature's `enableMediaRouting` opt-in installs OBS Studio and qpwgraph and
defines the virtual devices below; it is enabled on `wassaa` only. Enabling it
on another host also requires `enableMultimedia` and PipeWire audio.

## Persistent patchbay

On desktop hosts with media routing enabled, qpwgraph starts minimized at login
with the host's patchbay activated in non-exclusive mode. Its graph is linked
from `~/.config/qpwgraph/audio-routing.qpwgraph` to
`hosts/<host>/audio-routing.qpwgraph` in the writable checkout specified by
`flakeDir`. If the graph does not exist, the first startup creates an empty one;
an existing graph is never replaced. The host directory must exist and be
writable. qpwgraph's own settings and node positions stay local to the user.

Pin the connections that should be restored, or enable Auto Pin for manual
connections, then use Patchbay Save to write them to the host graph. Review the
graph before adding it to Git and committing it. Unpinned connections are
temporary; avoid pinning sensitive sharing routes or unintended MIDI loops.
Changes to the graph are not committed automatically. Test restoration after
logging in and reconnecting devices; qpwgraph must remain running.

## First use on wassaa

After deploying the configuration and rebooting to apply the camera module
options:

1. Select the intended physical microphone and playback device as the system
   defaults. WirePlumber should insert **Microphone Proxy** and **Main Audio**
   as smart filters in those paths; the physical devices, not the filters,
   remain the visible defaults. In particular, change any previously saved
   Microphone Proxy default back to the intended physical microphone.
2. Before testing the microphone, remove the old Scarlett-to-Microphone Proxy
   pin if it still matches the new graph. It can otherwise duplicate or
   interfere with the automatic route. Keep the separate Scarlett-to-OBS pin
   only if that direct feed is wanted. Inspect qpwgraph and test with meters and
   headphones at a low volume.
3. Check that the selected Scarlett microphone uses the intended Input 1 only.
   The mono filter does not guarantee which channels a stereo physical source
   contributes. Also test switching physical defaults and unplugging and
   reconnecting devices; another microphone could become the default when the
   selected one disappears.
4. Use **OBS Track 1** and **OBS Track 2** as separate application audio buses.
   Route the desired playback streams to them, and add their monitor sources as
   audio inputs in OBS. Connect the buses' monitor outputs to headphones if you
   need to hear them. Configure OBS tracks and avoid also capturing the same
   audio through desktop audio.
5. In OBS, add your camera as a video source and select **Start Virtual
   Camera**. Select **OBS Virtual Camera** in the receiving application. With
   exclusive capabilities enabled, the device may not appear in the application
   until OBS starts the virtual camera.

## Caveats

WirePlumber restores user-selected defaults; a high virtual priority alone does
not override a remembered physical default. A smart filter is not a second
default. Verify the live route with `wpctl status` and `pw-dump` after login,
and keep the patchbay non-exclusive so manual links are visible.

The smart filters and OBS buses are declarative, but extra routes and OBS
scenes are manual. qpwgraph pins add persistent connections and do not
necessarily override WirePlumber's automatic links. Test whether injecting
other audio into the new microphone filter works as intended before relying on
it; avoid pinning sensitive sharing routes or feeding call audio back into the
microphone. Application-specific device choices may bypass the default filter
path.
