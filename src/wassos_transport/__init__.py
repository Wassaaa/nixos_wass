import json
import os
import subprocess
import sys
from pathlib import Path


def main() -> int:
    print("Task: verify direnv and Hyprland Lua stubs after your manual switch.")
    print("This reloads direnv; it may download/build packages and update its cache.")
    print("It does not switch the system or print exported environment values.")
    print("Review output for sensitive information before sharing it.")
    if input("Run the check? Type yes to continue: ").strip().lower() != "yes":
        print("Cancelled; no check was run.")
        return 1

    env = os.environ.copy()
    for name in ("DIRENV_DIR", "DIRENV_WATCHES", "DIRENV_DIFF", "WASSOS_HYPRLAND_LUA_STUBS"):
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
    try:
        exported = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        print(f"Direnv returned invalid JSON: {exc}", file=sys.stderr)
        return 1
    stub_directory = exported.get("WASSOS_HYPRLAND_LUA_STUBS") if isinstance(exported, dict) else None
    if not isinstance(stub_directory, str) or not stub_directory:
        print("Direnv did not export the Hyprland Lua stubs path.", file=sys.stderr)
        return 1
    try:
        stub = (Path(stub_directory) / "hl.meta.lua").read_text(encoding="utf-8")
    except OSError as exc:
        print(f"Could not read the generated Hyprland Lua stubs: {exc}", file=sys.stderr)
        return 1
    if not all(marker in stub for marker in ("---@meta", "HL.BindOptions", "description")):
        print("The generated Hyprland Lua stubs are missing expected definitions.", file=sys.stderr)
        return 1
    print("Direnv loaded and the Hyprland Lua stubs contain bind option descriptions.")
    print("Reload VS Code and check completion; editor integration is not tested here.")
    return 0
