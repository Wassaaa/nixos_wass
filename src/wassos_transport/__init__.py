import os
import subprocess
import sys
from pathlib import Path


def main() -> int:
    print("Task: reproduce the direnv failure and inspect nix-direnv's preflight.")
    print("This reruns the trusted repository .envrc. It may download/build packages")
    print("and update the Nix store and the repository's .direnv cache.")
    print("No exported environment values will be printed.")
    print("Review output for sensitive information before sharing it.")
    if input("Run the diagnostic? Type yes to continue: ").strip().lower() != "yes":
        print("Cancelled; no diagnostic was run.")
        return 1

    script = Path.home() / ".config" / "direnv" / "lib" / "hm-nix-direnv.sh"
    try:
        lines = script.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        print(f"Could not read {script}: {exc}", file=sys.stderr)
        return 1

    start = next(
        (i for i, line in enumerate(lines) if line.strip() == "_nix_direnv_preflight() {"),
        None,
    )
    if start is None:
        print("Could not find nix-direnv's preflight function.", file=sys.stderr)
        return 1
    print("\nInstalled nix-direnv preflight:")
    for i in range(start, len(lines)):
        print(f"{i + 1}: {lines[i]}")
        if lines[i].strip() == "}":
            break
    else:
        print("Could not find the end of the preflight function.", file=sys.stderr)
        return 1

    env = os.environ.copy()
    for name in ("DIRENV_DIR", "DIRENV_WATCHES", "DIRENV_DIFF"):
        env.pop(name, None)
    print("\nRerunning direnv; exported environment is discarded:")
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
    print(f"direnv exit code: {result.returncode}")
    if "--no-warn-dirty: command not found" in result.stderr:
        print("Reproduced the reported nix-direnv command failure.")
    elif result.returncode:
        print("Direnv failed, but not with the same reported command error.")
    else:
        print("Direnv completed without the reported failure.")
    return int(result.returncode != 0)
