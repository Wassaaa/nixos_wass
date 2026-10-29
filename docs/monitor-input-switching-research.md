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

The [wassaa host configuration](../hosts/wassaa/default.nix) enables this option. It grants access to I²C devices generally, not just the monitor, so the change should be understood before activation. A reboot or a fresh local session may be needed before the module and access rules take effect.

If detection fails, check DDC/CI in the monitor OSD, the `i2c-dev` module, and device permissions first. Upstream documents undocumented NVIDIA proprietary-driver settings as a possible workaround on some cards, **not** a universal fix or a recommended default. It also documents an NVIDIA proprietary-driver MST/dock case where a connector has EDID but no usable I²C adapter.

Sources: [pinned NixOS I²C module](https://github.com/NixOS/nixpkgs/blob/3ec636362e1816bc2f0888fa0fa2c69f1bc9e504/nixos/modules/hardware/i2c.nix#L12-L42), [ddcutil permissions](https://github.com/rockowitz/rockowitz.github.io/blob/193f6d62ecf799d764fbeac0ba099eef204e8f22/i2c_permissions/index.html#L323-L327), [ddcutil FAQ](https://github.com/rockowitz/rockowitz.github.io/blob/193f6d62ecf799d764fbeac0ba099eef204e8f22/faq/index.html#L324-L329), [NVIDIA settings](https://github.com/rockowitz/rockowitz.github.io/blob/193f6d62ecf799d764fbeac0ba099eef204e8f22/nvidia/index.html#L323-L334), [NVIDIA MST limitation](https://github.com/rockowitz/rockowitz.github.io/blob/193f6d62ecf799d764fbeac0ba099eef204e8f22/faq/index.html#L400-L408).

## XB271HU investigation

The wassaa display identifies itself as `XB271HU`, EDID manufacturer `ACR`, product `0x0490`. A read of VCP `0x10` returned brightness; `getvcp 0x60` returned EIO and the monitor's capabilities did not list `0x60`. These observations confirm a working DDC read but do not establish why input selection failed or prove no alternate command exists. A separately submitted [ACR0490 EDID](https://github.com/bsdhw/EDID/blob/master/Digital/Acer/ACR0490/187C579420DE#L23-L56) also identifies an XB271HU with DisplayPort and an NVIDIA vendor block. An [ACR048F XB271HU EDID](https://github.com/linuxhw/EDID/blob/master/Digital/Acer/ACR048F/8EB858DD1961#L41-L97) differs; neither record establishes the exact retail suffix or firmware on wassaa.

No verified XB271HU-specific DDC input-switch command, USB control protocol, or firmware method was found. A [third-party-hosted Acer manual](https://www.manua.ls/acer/predator-xb271hu/manual?p=20) describes a physical input button, and its [OSD section](https://www.manua.ls/acer/predator-xb271hu/manual?p=22) lists HDMI and DP input selection. The manual's [USB installation instructions](https://www.manua.ls/acer/predator-xb271hu/manual?p=19) describe USB 3.0 and charging, not a remote input-switching interface. USB monitor-control devices are supported by [ddcutil](https://github.com/rockowitz/rockowitz.github.io/blob/193f6d62ecf799d764fbeac0ba099eef204e8f22/usb/index.html), but a monitor's USB hub alone does not establish such an interface.

An [owner report](https://github.com/xanderfrangos/twinkle-tray/issues/461#issuecomment-1304915399) describes XB271HU brightness writes failing while contrast worked. A [follow-up report](https://github.com/xanderfrangos/twinkle-tray/issues/461#issuecomment-1304919755) describes enabling brightness through factory mode but also flashing color patterns on signal loss. These reports do not establish input-switch support; factory mode is not recommended as a probe.

For further investigation, ask Acer support about the exact label suffix and part number, VCP `0x60`, vendor-defined commands, USB HID control, and supported firmware or service procedures. A read-only USB inventory with the monitor's upstream cable connected could establish whether a monitor-control HID device is visible; absence of one would not rule out undocumented protocols. Do not brute-force VCP writes, enter factory mode, or flash unverified firmware. The Acer support page was unavailable during the search, and the manual above is a hosted copy. This is a bounded search, not proof that no method exists.

The vendor scan found readable responses at `0xe0`, `0xe1`, and `0xf9`–`0xff`; the others returned EIO. The temporary `uv run x` probe compares those previously responsive codes on DisplayPort and, after the user manually switches the monitor, HDMI. These are Get VCP requests only, not setting writes; the probe saves command output privately and reports failures or timeouts. A returned or changed value alone does not identify a feature's purpose or prove that it controls input selection. Unsupported or failed reads cannot necessarily be distinguished, and a read-only scan is not a backup. The DisplayPort DDC path may be unavailable while HDMI is active.
