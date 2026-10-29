# Monitor input switching research

## Scope

DDC/CI input switching may work for an Acer Predator connected over DisplayPort, but the model is not yet known. Its support, input values, and ability to switch back from an inactive input must be tested; no model-specific values are assumed here.

## How it works

DisplayPort carries logical I²C/DDC communication over its AUX channel. Support can differ between a monitor's DisplayPort and other inputs. MCCS VCP feature `0x60` selects the input source, but some monitors use nonstandard values.

Sources: [ddcutil: DDC over DisplayPort](https://github.com/rockowitz/rockowitz.github.io/blob/193f6d62ecf799d764fbeac0ba099eef204e8f22/displayport/index.html#L323-L335), [ddcutil: feature x60](https://github.com/rockowitz/rockowitz.github.io/blob/193f6d62ecf799d764fbeac0ba099eef204e8f22/feature_x60#L1-L11).

## Read-only discovery

With the monitor on the DisplayPort input and DDC/CI enabled in its on-screen display:

```sh
ddcutil detect
# Substitute the intended display's I²C bus number from detect:
ddcutil --bus N capabilities
ddcutil --bus N getvcp 60
ddcutil vcpinfo --verbose 60
```

`detect` identifies displays and buses; explicitly select the intended display when more than one is present. `capabilities` may list supported values, but the monitor's capabilities string can be incomplete or incorrect. `vcpinfo` describes ddcutil's MCCS definitions, not values verified for this particular monitor. These probes query the monitor; they do not request an input change.

Sources: [detect](https://github.com/rockowitz/rockowitz.github.io/blob/193f6d62ecf799d764fbeac0ba099eef204e8f22/command_detect/index.html#L331-L335), [display selection](https://github.com/rockowitz/rockowitz.github.io/blob/193f6d62ecf799d764fbeac0ba099eef204e8f22/display_selection/index.html#L324-L345), [capabilities](https://github.com/rockowitz/rockowitz.github.io/blob/193f6d62ecf799d764fbeac0ba099eef204e8f22/command_capabilities/index.html#L329-L343), [vcpinfo](https://github.com/rockowitz/rockowitz.github.io/blob/193f6d62ecf799d764fbeac0ba099eef204e8f22/command_vcpinfo/index.html#L330-L351).

## Switching and recovery

Once the model and destination value have been verified, the command shape is `ddcutil --bus N setvcp 60 <verified-value>`. This **changes** the monitor setting and is not a discovery probe.

Plan recovery before trying it: some monitors answer DDC requests on inactive inputs, while others answer only on the active input. The original DisplayPort host may therefore be unable to switch the monitor back. Keep the physical OSD controls available, or use another host on the active input if that path has been tested.

An I²C acknowledgement means the request was received, not that the monitor executed it. Current ddcutil deliberately skips post-write verification for `0x60`, because the original path may stop responding.

Sources: [feature x60](https://github.com/rockowitz/rockowitz.github.io/blob/193f6d62ecf799d764fbeac0ba099eef204e8f22/feature_x60#L1-L11), [setvcp](https://github.com/rockowitz/rockowitz.github.io/blob/193f6d62ecf799d764fbeac0ba099eef204e8f22/command_setvcp/index.html#L353-L360), [ddcutil verification implementation](https://github.com/rockowitz/ddcutil/blob/a7ae81954533803e557d6de6bbf9bbd9a99cff28/src/ddc/ddc_vcp.c#L542-L568).

## NixOS and NVIDIA

ddcutil needs read/write access to the relevant `/dev/i2c-*` device even for queries. In this repository's pinned Nixpkgs revision, `hardware.i2c.enable` loads `i2c-dev` and installs udev access rules for the default `i2c` group and local-seat users. Check the actual session's permissions rather than assuming access.

If detection fails, check DDC/CI in the monitor OSD, the `i2c-dev` module, and device permissions first. Upstream documents undocumented NVIDIA proprietary-driver settings as a possible workaround on some cards, **not** a universal fix or a recommended default. It also documents an NVIDIA proprietary-driver MST/dock case where a connector has EDID but no usable I²C adapter.

Sources: [pinned NixOS I²C module](https://github.com/NixOS/nixpkgs/blob/3ec636362e1816bc2f0888fa0fa2c69f1bc9e504/nixos/modules/hardware/i2c.nix#L12-L42), [ddcutil permissions](https://github.com/rockowitz/rockowitz.github.io/blob/193f6d62ecf799d764fbeac0ba099eef204e8f22/i2c_permissions/index.html#L323-L327), [ddcutil FAQ](https://github.com/rockowitz/rockowitz.github.io/blob/193f6d62ecf799d764fbeac0ba099eef204e8f22/faq/index.html#L324-L329), [NVIDIA settings](https://github.com/rockowitz/rockowitz.github.io/blob/193f6d62ecf799d764fbeac0ba099eef204e8f22/nvidia/index.html#L323-L334), [NVIDIA MST limitation](https://github.com/rockowitz/rockowitz.github.io/blob/193f6d62ecf799d764fbeac0ba099eef204e8f22/faq/index.html#L400-L408).
