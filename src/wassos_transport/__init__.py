from pathlib import Path
import subprocess
import sys


def main() -> int:
    if len(sys.argv) != 1:
        print("Usage: uv run x", file=sys.stderr)
        return 1
    script = Path("scripts/nordvpn-reset-legacy-settings.sh")
    if not script.is_file():
        print("Run uv run x from the repository root.", file=sys.stderr)
        return 1

    print("Current task: recover NordVPN's legacy settings.")
    print("This stops NordVPN, backs up its settings and key,")
    print("moves the old settings aside, and restarts the daemon using sudo.")
    print("You may need to sign in again and reconfigure VPN preferences.")
    try:
        answer = input("Type RESET-NORDVPN to continue: ")
    except EOFError:
        print("Confirmation not provided; no changes made.", file=sys.stderr)
        return 1
    if answer != "RESET-NORDVPN":
        print("Cancelled; no changes made.")
        return 1

    try:
        return subprocess.run(["sudo", "bash", str(script)], check=False).returncode
    except OSError as error:
        print(f"Could not start the recovery script: {error}", file=sys.stderr)
        return 1
