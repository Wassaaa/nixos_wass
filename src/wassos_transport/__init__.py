from pathlib import Path
import os
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


def run_query(command: list[str], description: str) -> bool:
    print(f"\n{description} (no monitor settings will be changed).", flush=True)
    try:
        result = subprocess.run(command, timeout=240, check=False)
    except (OSError, subprocess.TimeoutExpired) as error:
        print(f"DDC query failed: {error}", file=sys.stderr)
        return False
    if result.returncode:
        print(f"DDC query exited with status {result.returncode}.", file=sys.stderr)
        return False
    return True


def save_vendor_reads(command: list[str], root: Path) -> bool:
    try:
        root.mkdir(parents=True, exist_ok=True, mode=0o700)
        directory = Path(tempfile.mkdtemp(prefix="vendor-read-", dir=root))
    except OSError as error:
        print(f"Could not create the scan directory: {error}", file=sys.stderr)
        return False
    output = directory / "vendor-read.txt"
    codes = [f"{code:02x}" for code in range(0xE0, 0x100)]
    print(f"\nReading 32 manufacturer-specific codes; results will be saved to {output}")
    print("This may take several minutes. Values do not identify their purpose.", flush=True)
    try:
        result = subprocess.run(
            command + ["--verbose", "getvcp", *codes],
            timeout=600,
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
    except OSError as error:
        print(f"Vendor read could not start: {error}", file=sys.stderr)
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
        print(f"Could not save vendor read results: {error}", file=sys.stderr)
        return False
    if stdout:
        print(stdout, end="" if stdout.endswith("\n") else "\n")
    if stderr:
        print(stderr, file=sys.stderr, end="" if stderr.endswith("\n") else "\n")
    print(f"\nResults saved to {output}; review them for sensitive information before sharing.")
    if not successful:
        print(
            f"ddcutil status: {status}; some reads failed, were unsupported, or did not finish.",
            file=sys.stderr,
        )
        return False
    if not stdout.strip():
        print("ddcutil returned no scan output.", file=sys.stderr)
        return False
    return True


def main() -> int:
    print("Current task: read manufacturer-specific DDC codes E0 through FF on the Acer monitor.")
    print("No monitor settings or system configuration will be changed.")
    print("A private results directory will be created only after confirmation.")
    print("Unknown reads can cause glitches; physical monitor controls are the fallback.")
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
    detected = run_query(command + ["detect"], "Detecting DDC-capable displays")
    if not connectors_found or not detected:
        print("\nThe probe was incomplete. Share the reviewed output so the next step can be chosen.")
        return 1
    print("\nFind the Acer display in the detection output and identify its I2C bus number.")
    print("Only select a bus if you can positively identify the intended display.")
    if not sys.stdin.isatty():
        print("No interactive terminal available; skipping the vendor reads.", file=sys.stderr)
        return 1
    try:
        bus = input("Enter the Acer's bus number (digits only), or press Enter to skip: ").strip()
    except EOFError:
        bus = ""
    if not bus:
        print("Skipped the vendor reads.")
        return 0
    if not bus.isascii() or not bus.isdecimal():
        print("Invalid bus number; no vendor reads were run.", file=sys.stderr)
        return 1
    base = command + ["--bus", bus]
    print("\nThe scan only sends Get VCP requests for E0 through FF; it sends no Set VCP commands.")
    print("This is not a backup; unreadable codes may be unsupported or may have failed.")
    try:
        answer = input("Type scan to run the reads and save their output: ").strip()
    except EOFError:
        answer = ""
    if answer != "scan":
        print("Cancelled; no scan files were created.")
        return 1
    if not save_vendor_reads(base, Path.home() / ".local" / "state" / "wassos" / "monitor-scans"):
        print("\nThe vendor read was incomplete; inspect the reported output and errors.", file=sys.stderr)
        return 1
    return 0
