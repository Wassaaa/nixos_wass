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


def detect_acer_buses(command: list[str], stage: str) -> set[str] | None:
    print(f"\nDetecting displays with the Acer on {stage}.", flush=True)
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


VENDOR_CODES = ("e0", "e1", "f9", "fa", "fb", "fc", "fd", "fe", "ff")
RAW_VALUE = re.compile(
    r"Raw value:\s*opcode=0x([0-9a-f]{2}),\s*"
    r"mh=0x([0-9a-f]{2}),\s*ml=0x([0-9a-f]{2}),\s*"
    r"sh=0x([0-9a-f]{2}),\s*sl=0x([0-9a-f]{2})",
    re.IGNORECASE,
)


def read_vendor_values(command: list[str], output: Path) -> tuple[dict[str, str], bool] | None:
    print(f"\nReading previously responsive vendor codes; saving output to {output}", flush=True)
    try:
        result = subprocess.run(
            command + ["--verbose", "getvcp", *VENDOR_CODES],
            timeout=300,
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
    except OSError as error:
        print(f"Vendor read could not start: {error}", file=sys.stderr)
        return None
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
        print(f"Could not save vendor read results: {error}", file=sys.stderr)
        return None
    if stdout:
        print(stdout, end="" if stdout.endswith("\n") else "\n")
    if stderr:
        print(stderr, file=sys.stderr, end="" if stderr.endswith("\n") else "\n")
    print(f"\nResults saved to {output}; review them for sensitive information before sharing.")
    if not successful:
        print(
            f"ddcutil status: {status}; results may be incomplete.",
            file=sys.stderr,
        )
    values = {
        match.group(1).lower(): " ".join(group.lower() for group in match.groups()[1:])
        for match in RAW_VALUE.finditer(stdout)
        if match.group(1).lower() in VENDOR_CODES
    }
    if not values:
        print("No comparable vendor values were returned.", file=sys.stderr)
        return None
    missing = set(VENDOR_CODES) - values.keys()
    if missing:
        print("No parsed value for: " + ", ".join("0x" + code for code in sorted(missing)), file=sys.stderr)
    return values, successful and not missing


def ask_bus(stage: str, available: set[str]) -> str | None:
    if not available:
        print(f"No Acer bus is available for the {stage} stage.")
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


def compare_values(before: dict[str, str], after: dict[str, str]) -> bool:
    common = set(before) & set(after)
    if not common:
        print("No vendor values could be compared between the two inputs.")
        return False
    for code in sorted(common):
        state = "unchanged" if before[code] == after[code] else "changed"
        print(f"  0x{code}: {before[code]} -> {after[code]} ({state})")
    missing = (set(before) | set(after)) - common
    if missing:
        print("Unavailable in one stage: " + ", ".join("0x" + code for code in sorted(missing)))
    print("A changed value does not establish a feature's meaning or that it can switch inputs.")
    return True


def main() -> int:
    print("Current task: compare Acer vendor-code reads on DisplayPort and HDMI.")
    print("You will manually change the Acer's input; this script does not change settings.")
    print("A private results directory will be created only after confirmation.")
    print("Keep Hyprland's current layout; move this terminal to the PC's second monitor.")
    print("Use the Acer's physical controls to return to DisplayPort when finished.")
    print("DDC queries may cause display glitches and include serial numbers in their output.")
    print("Review all output for sensitive information before sharing it.")

    if len(sys.argv) != 1:
        print("Usage: uv run x", file=sys.stderr)
        return 1
    if sys.platform != "linux":
        print("This diagnostic requires Linux.", file=sys.stderr)
        return 1

    connectors_found = inspect_connectors(Path("/sys/class/drm"), Path("/dev"))
    if not inspect_i2c(Path("/dev"), Path("/sys/module/i2c_dev")):
        print("\nThe probe was incomplete. Share the reviewed output before proceeding.")
        return 1
    ddcutil = shutil.which("ddcutil")
    if ddcutil:
        command = [ddcutil]
    else:
        print("\nddcutil is not installed. A temporary Nix shell can download it into the Nix store.")
        if not sys.stdin.isatty():
            print("No interactive terminal available; skipping the optional download.", file=sys.stderr)
            return 1
        try:
            answer = input("Download/run ddcutil for detection? Type yes to continue: ").strip()
        except EOFError:
            answer = ""
        if answer != "yes":
            print("Skipped DDC detection.")
            return 1
        command = ["nix", "shell", "--inputs-from", ".", "nixpkgs#ddcutil", "--command", "ddcutil"]
    if not sys.stdin.isatty():
        print("An interactive terminal is required for the comparison.", file=sys.stderr)
        return 1
    buses = detect_acer_buses(command, "DisplayPort")
    if not connectors_found or buses is None:
        print("\nThe probe was incomplete. Share the reviewed output so the next step can be chosen.")
        return 1
    bus = ask_bus("DisplayPort", buses)
    if bus is None:
        return 1
    print("\nThis probe reads E0, E1, and F9-FF only; no Set VCP commands are sent.")
    print("Confirm that the Acer is on DisplayPort and this terminal is visible on the second monitor.")
    try:
        answer = input("Type start to save the DisplayPort baseline, or Enter to cancel: ").strip()
    except EOFError:
        answer = ""
    if answer != "start":
        print("Cancelled; no comparison files were created.")
        return 1
    root = Path.home() / ".local" / "state" / "wassos" / "monitor-scans"
    try:
        root.mkdir(parents=True, exist_ok=True, mode=0o700)
        directory = Path(tempfile.mkdtemp(prefix="input-compare-", dir=root))
    except OSError as error:
        print(f"Could not create the comparison directory: {error}", file=sys.stderr)
        return 1
    baseline = read_vendor_values(command + ["--bus", bus], directory / "displayport.txt")
    if baseline is None:
        print("No usable baseline; not proceeding to HDMI.", file=sys.stderr)
        return 1
    before, baseline_complete = baseline
    print("\nUse the Acer's physical controls to select the laptop's HDMI input.")
    print("Leave the Hyprland layout unchanged, then return to this terminal on the second monitor.")
    try:
        answer = input("Type ready after switching to HDMI, or Enter to stop: ").strip()
    except EOFError:
        answer = ""
    try:
        if answer != "ready":
            print("Stopped; the DisplayPort baseline remains saved.")
            return 1
        hdmi_buses = detect_acer_buses(command, "HDMI")
        if hdmi_buses is None:
            print("DDC detection failed on the HDMI stage.", file=sys.stderr)
            return 1
        hdmi_bus = ask_bus("HDMI", hdmi_buses)
        if hdmi_bus is None:
            print("No Acer bus selected; HDMI-side comparison was not run.")
            return 1
        comparison = read_vendor_values(command + ["--bus", hdmi_bus], directory / "hdmi.txt")
        if comparison is None:
            return 1
        after, comparison_complete = comparison
        print("\nComparable values (MH ML SH SL):")
        comparable = compare_values(before, after)
        return 0 if comparable and baseline_complete and comparison_complete else 1
    finally:
        print("\nUse the Acer's physical controls to return to DisplayPort when finished.")
        print(f"Comparison files: {directory} (review for sensitive information before sharing).")
