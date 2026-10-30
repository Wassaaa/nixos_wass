import re
import shutil
import subprocess
import sys
from pathlib import Path


def main() -> int:
    print("Task: inspect the Nix and direnv setup behind the dev-shell failure.")
    print("Side effects: none intended; no secrets or environment variables are read.")
    print("Review the output for sensitive paths or other information before sharing it.")

    failed = False
    for program, args in (("nix", ["--version"]), ("direnv", ["version"])):
        executable = shutil.which(program)
        if executable is None:
            print(f"{program}: not found on PATH", file=sys.stderr)
            failed = True
            continue
        print(f"{program} executable: {executable}")
        result = subprocess.run(
            [executable, *args], text=True, capture_output=True, check=False
        )
        print(f"{program} version exit code: {result.returncode}")
        if result.stdout.strip():
            print(result.stdout.strip())
        if result.stderr.strip():
            print(result.stderr.strip(), file=sys.stderr)
        failed |= result.returncode != 0

    config = Path.home() / ".config" / "direnv"
    pattern = re.compile(
        r"^\s*(?:source\s|\. /|(?:function\s+)?(?:_nix|_nix_direnv_preflight|use_flake)"
        r"\s*\(|(?:local\s+)?_nix_direnv_nix=|if\s+.*(?:command -v nix|_nix_direnv_preflight))"
    )
    for path in (config / "direnvrc", config / "lib" / "hm-nix-direnv.sh"):
        print(f"\nRelevant lines from {path}:")
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except OSError as exc:
            print(f"Could not read {path}: {exc}", file=sys.stderr)
            failed = True
            continue
        for number, line in enumerate(lines, 1):
            if pattern.search(line) or "--no-warn-dirty" in line:
                print(f"{number}: {line}")

    return int(failed)
