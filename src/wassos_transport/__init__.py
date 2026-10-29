from pathlib import Path
import os
import re
import shutil
import subprocess
import sys
import tempfile


def edid_identity(data: bytes) -> tuple[str, str, str]:
    if len(data) < 128 or data[:8] != b"\x00\xff\xff\xff\xff\xff\xff\x00":
        raise ValueError("EDID is missing or invalid")
    manufacturer_code = int.from_bytes(data[8:10], "big")
    manufacturer = "".join(
        chr(((manufacturer_code >> shift) & 31) + 64) for shift in (10, 5, 0)
    )
    product = f"0x{int.from_bytes(data[10:12], 'little'):04x}"
    name = "not reported"
    for offset in range(54, 126, 18):
        descriptor = data[offset : offset + 18]
        if descriptor[:5] == b"\x00\x00\x00\xfc\x00":
            name = descriptor[5:18].split(b"\n", 1)[0].decode("ascii", "replace").strip()
            break
    return manufacturer, product, name


def inspect_connectors(drm_root: Path, dev_root: Path) -> bool:
    if not drm_root.is_dir():
        print(f"DRM connector information is unavailable: {drm_root}", file=sys.stderr)
        return False
    connectors = sorted(drm_root.glob("card*-DP-2"))
    if not connectors:
        print("No DRM connector named DP-2 was found. Connector names may differ from Hyprland.")
        return False

    identity_found = False
    for connector in connectors:
        print(f"\nConnector: {connector.name}")
        try:
            print(f"  Status: {(connector / 'status').read_text().strip()}")
        except OSError as error:
            print(f"  Could not read connector status: {error}", file=sys.stderr)
        try:
            manufacturer, product, name = edid_identity((connector / "edid").read_bytes())
            print(f"  EDID manufacturer: {manufacturer}")
            print(f"  EDID product: {product}")
            print(f"  EDID monitor name: {name}")
            identity_found = True
        except (OSError, ValueError) as error:
            print(f"  Could not read monitor identity: {error}", file=sys.stderr)
        try:
            adapter = (connector / "ddc").resolve(strict=True).name
        except OSError as error:
            print(f"  No readable DDC adapter link: {error}")
            continue
        device = dev_root / adapter
        print(f"  DDC adapter: {adapter}")
        print(f"  Device: {device}")
        print(f"  Current user can read/write device: {os.access(device, os.R_OK | os.W_OK)}")
    return identity_found


def inspect_i2c(dev_root: Path, module_root: Path) -> bool:
    print(f"\ni2c-dev module loaded: {module_root.is_dir()}")
    devices = sorted(
        path for path in dev_root.glob("i2c-*")
        if path.name[4:].isascii() and path.name[4:].isdecimal()
    )
    if not devices:
        print("No /dev/i2c-* devices found. A reboot may be needed after the rebuild.")
        return False
    print("I2C devices (current user's read/write access):")
    for device in devices:
        print(f"  {device}: {os.access(device, os.R_OK | os.W_OK)}")
    return True


def detect_acer_buses(command: list[str]) -> set[str] | None:
    print("\nDetecting displays with the Acer on DisplayPort.", flush=True)
    try:
        result = subprocess.run(
            command + ["detect", "--brief"], timeout=240, check=False,
            capture_output=True, text=True, encoding="utf-8", errors="replace",
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        print(f"DDC detection failed: {error}", file=sys.stderr)
        return None
    if result.stderr:
        print(result.stderr, file=sys.stderr, end="" if result.stderr.endswith("\n") else "\n")
    if result.returncode:
        print(f"DDC detection exited with status {result.returncode}.", file=sys.stderr)
        return None
    buses = set()
    for block in re.split(r"(?m)^(?=Display\s+\d+\s*$)", result.stdout):
        bus = re.search(r"(?m)^\s*I2C bus:\s*/dev/i2c-(\d+)\s*$", block)
        monitor = re.search(r"(?m)^\s*Monitor:\s*ACR:XB271HU:", block)
        if bus and monitor:
            buses.add(bus.group(1))
    if buses:
        print("Detected Acer XB271HU bus(es): " + ", ".join(sorted(buses, key=int)))
    else:
        print("No DDC-capable Acer XB271HU was identified in the detection output.")
    return buses


def connector_snapshot(drm_root: Path) -> tuple[str, bytes]:
    connectors = sorted(drm_root.glob("card*-DP-2"))
    if len(connectors) != 1:
        raise ValueError("Expected exactly one DP-2 connector")
    connector = connectors[0]
    if (connector / "status").read_text().strip() != "connected":
        raise ValueError("DP-2 is not connected")
    edid = (connector / "edid").read_bytes()
    if edid_identity(edid) != ("ACR", "0x0490", "XB271HU"):
        raise ValueError("DP-2 EDID does not identify the expected Acer XB271HU")
    return connector.name, edid


def bus_snapshot(bus: str, sys_root: Path, dev_root: Path) -> tuple[Path, int, int, int]:
    adapter = (sys_root / f"i2c-{bus}").resolve(strict=True)
    device = dev_root / f"i2c-{bus}"
    stat = device.stat()
    if not os.access(device, os.R_OK | os.W_OK):
        raise ValueError(f"No read/write access to {device}")
    return adapter, stat.st_dev, stat.st_ino, stat.st_rdev


def read_brightness(command: list[str], bus: str, output: Path) -> bool:
    print(f"\nReading brightness on /dev/i2c-{bus}; saving diagnostics to {output}", flush=True)
    try:
        result = subprocess.run(
            command + ["--bus", bus, "--ddcdata", "--stats=all", "getvcp", "10"],
            timeout=240, check=False, capture_output=True, text=True,
            encoding="utf-8", errors="replace",
        )
    except OSError as error:
        print(f"Brightness read could not start: {error}", file=sys.stderr)
        return False
    except subprocess.TimeoutExpired as error:
        stdout = (error.stdout or b"").decode("utf-8", "replace")
        stderr = (error.stderr or b"").decode("utf-8", "replace")
        status = "timed out"
        successful = False
    else:
        stdout, stderr = result.stdout, result.stderr
        status = str(result.returncode)
        successful = result.returncode == 0
    try:
        output.write_text(
            f"ddcutil status: {status}\n\nSTDOUT:\n{stdout}\nSTDERR:\n{stderr}",
            encoding="utf-8",
        )
    except OSError as error:
        print(f"Could not save diagnostics: {error}", file=sys.stderr)
        return False
    if stdout:
        print(stdout, end="" if stdout.endswith("\n") else "\n")
    if stderr:
        print(stderr, file=sys.stderr, end="" if stderr.endswith("\n") else "\n")
    print(f"\nddcutil status: {status}. Review output for sensitive information before sharing.")
    if successful and not re.search(r"(?im)^VCP code 0x10\s+.*current value\s*=", stdout):
        print("ddcutil reported success but did not return a brightness value.", file=sys.stderr)
        return False
    return successful


def ask_bus(available: set[str]) -> str | None:
    if not available:
        print("No Acer bus is available.")
        return None
    try:
        bus = input("Enter the Acer's bus number (digits only), or Enter to stop: ").strip()
    except EOFError:
        bus = ""
    if not bus:
        print("Stopped without selecting a bus.")
        return None
    if not bus.isascii() or not bus.isdecimal() or bus not in available:
        print("Bus was not identified as an Acer XB271HU; no read was run.", file=sys.stderr)
        return None
    return bus


def main() -> int:
    print("Current task: compare targeted Acer brightness reads on DisplayPort and HDMI.")
    print("No monitor settings or system configuration will be changed.")
    print("You will manually change the Acer's input; return to DisplayPort with its controls.")
    print("Keep Hyprland's layout unchanged and move this terminal to the second monitor.")
    print("A private results directory will be created only after confirmation.")
    print("DDC queries may cause display glitches and include serial numbers in their output.")
    print("Review all output for sensitive information before sharing it.")

    if len(sys.argv) != 1:
        print("Usage: uv run x", file=sys.stderr)
        return 1
    if sys.platform != "linux":
        print("This diagnostic requires Linux.", file=sys.stderr)
        return 1
    drm_root = Path("/sys/class/drm")
    dev_root = Path("/dev")
    sys_root = Path("/sys/class/i2c-dev")
    if not inspect_connectors(drm_root, dev_root) or not inspect_i2c(dev_root, Path("/sys/module/i2c_dev")):
        print("\nThe probe was incomplete. Share the reviewed output before proceeding.")
        return 1
    if not sys.stdin.isatty():
        print("An interactive terminal is required for the comparison.", file=sys.stderr)
        return 1
    ddcutil = shutil.which("ddcutil")
    if ddcutil:
        command = [ddcutil]
    else:
        print("\nddcutil is not installed. A temporary Nix shell can download it into the Nix store.")
        try:
            answer = input("Download/run ddcutil for detection? Type yes to continue: ").strip()
        except EOFError:
            answer = ""
        if answer != "yes":
            print("Skipped DDC detection.")
            return 1
        command = ["nix", "shell", "--inputs-from", ".", "nixpkgs#ddcutil", "--command", "ddcutil"]
    buses = detect_acer_buses(command)
    if buses is None:
        return 1
    bus = ask_bus(buses)
    if bus is None:
        return 1
    print("\nThe comparison requests Get VCP 0x10 (brightness); detection may query other information.")
    print("No Set VCP commands are sent.")
    print("Confirm that the Acer displays DisplayPort and this terminal is visible on the second monitor.")
    try:
        answer = input("Type start to read the DisplayPort baseline, or Enter to cancel: ").strip()
    except EOFError:
        answer = ""
    if answer != "start":
        print("Cancelled; no comparison files were created.")
        return 1
    try:
        connector = connector_snapshot(drm_root)
        adapter = bus_snapshot(bus, sys_root, dev_root)
        root = Path.home() / ".local" / "state" / "wassos" / "monitor-scans"
        root.mkdir(parents=True, exist_ok=True, mode=0o700)
        directory = Path(tempfile.mkdtemp(prefix="brightness-compare-", dir=root))
    except (OSError, ValueError) as error:
        print(f"Could not prepare the baseline: {error}", file=sys.stderr)
        return 1
    if not read_brightness(command, bus, directory / "displayport.txt"):
        print("The DisplayPort brightness read failed; not proceeding to HDMI.", file=sys.stderr)
        print(f"Diagnostics: {directory} (review for sensitive information before sharing).")
        return 1
    print("\nUse the Acer's physical controls to select the laptop's HDMI input.")
    print("Leave the Hyprland layout unchanged, then return to this terminal on the second monitor.")
    print("The next read targets the previously identified bus even if DDC detection fails.")
    print("Bus and connector checks reduce, but cannot eliminate, the risk of a changed mapping.")
    try:
        try:
            answer = input("Type ready after switching to HDMI, or Enter to stop: ").strip()
        except EOFError:
            answer = ""
        if answer != "ready":
            print("Stopped; the DisplayPort baseline remains saved.")
            return 1
        try:
            if connector_snapshot(drm_root) != connector or bus_snapshot(bus, sys_root, dev_root) != adapter:
                raise ValueError("DP-2 identity or the I2C device changed since the baseline")
        except (OSError, ValueError) as error:
            print(f"Cannot safely reuse the baseline bus: {error}. HDMI read skipped.", file=sys.stderr)
            return 1
        print("Connector and I2C device match the baseline; attempting the targeted read.")
        if not read_brightness(command, bus, directory / "hdmi.txt"):
            print("HDMI-stage read failed; this does not prove all DDC requests are impossible.", file=sys.stderr)
            return 1
        print("Both brightness reads succeeded; compare the saved diagnostics.")
        return 0
    finally:
        print("\nUse the Acer's physical controls to return to DisplayPort when finished.")
        print(f"Comparison files: {directory} (review for sensitive information before sharing).")
