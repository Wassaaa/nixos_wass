from pathlib import Path
import socket
import subprocess
import sys


def main() -> int:
    if len(sys.argv) != 1:
        print("Usage: uv run x", file=sys.stderr)
        return 1

    print("Current task: deploy the media routing configuration on wassaa.")
    print("This builds and switches the NixOS configuration with sudo; services may restart.")
    print("It does not reboot. Reboot afterward to apply the virtual camera module options.")

    if sys.platform != "linux" or socket.gethostname() != "wassaa":
        print("This task must run on the wassaa NixOS host.", file=sys.stderr)
        return 1
    if not (Path.cwd() / "flake.nix").is_file():
        print("Run this task from the repository root.", file=sys.stderr)
        return 1
    if not sys.stdin.isatty():
        print("Interactive confirmation is required.", file=sys.stderr)
        return 1

    try:
        if input("Type 'apply' to build and switch, or press Enter to cancel: ") != "apply":
            print("Cancelled; no changes made.")
            return 0
        return subprocess.run(
            ["sudo", "nixos-rebuild", "switch", "--flake", ".#wassaa"],
            check=False,
        ).returncode
    except (EOFError, KeyboardInterrupt):
        print("\nCancelled.", file=sys.stderr)
        return 1
    except OSError as error:
        print(f"Could not start the rebuild: {error}", file=sys.stderr)
        return 1
