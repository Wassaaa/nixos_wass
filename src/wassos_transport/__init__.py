import os
import subprocess
import sys


def main() -> int:
    print("Task: apply the direnv integration fix and verify this dev shell.")
    print("This runs nh os switch, which builds and activates a new NixOS generation")
    print("and may download packages and request sudo authentication.")
    print("It then reloads direnv, which may build packages and update its cache.")
    print("Review output for sensitive information before sharing it.")
    if input("Apply the configuration and run the check? Type yes to continue: ").strip().lower() != "yes":
        print("Cancelled; no configuration was applied.")
        return 1

    try:
        switch = subprocess.run(["nh", "os", "switch"], check=False)
    except OSError as exc:
        print(f"Could not run nh os switch: {exc}", file=sys.stderr)
        return 1
    if switch.returncode:
        print(f"nh os switch failed with exit code {switch.returncode}.", file=sys.stderr)
        return switch.returncode

    env = os.environ.copy()
    for name in ("DIRENV_DIR", "DIRENV_WATCHES", "DIRENV_DIFF"):
        env.pop(name, None)
    print("\nChecking direnv; exported environment is not displayed:", flush=True)
    try:
        result = subprocess.run(
            ["direnv", "export", "json"],
            env=env,
            text=True,
            capture_output=True,
            check=False,
        )
    except OSError as exc:
        print(f"Could not run direnv: {exc}", file=sys.stderr)
        return 1
    if result.stderr:
        print(result.stderr, end="" if result.stderr.endswith("\n") else "\n")
    if result.returncode:
        print(f"direnv failed with exit code {result.returncode}.", file=sys.stderr)
        return result.returncode
    print("Direnv loaded successfully. Restart or reload the editor to pick up the stubs.")
    return 0
