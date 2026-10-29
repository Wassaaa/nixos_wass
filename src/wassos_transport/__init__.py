from pathlib import Path
import os
import sys


THEME_VARIABLES = (
    "QT_QPA_PLATFORM",
    "QT_QPA_PLATFORMTHEME",
    "QT_PLUGIN_PATH",
    "QT_STYLE_OVERRIDE",
    "XDG_CURRENT_DESKTOP",
    "XDG_SESSION_TYPE",
    "WAYLAND_DISPLAY",
)


def qpwgraph_environments(proc_root: Path, user_id: int):
    for process in sorted(proc_root.iterdir(), key=lambda path: path.name):
        if not process.name.isdecimal():
            continue
        try:
            if process.stat().st_uid != user_id:
                continue
            if (process / "comm").read_text().strip() != "qpwgraph":
                executable = (process / "cmdline").read_bytes().split(b"\0", 1)[0]
                if Path(os.fsdecode(executable)).name not in {
                    "qpwgraph",
                    "qpwgraph-wrapped",
                    ".qpwgraph-wrapped",
                }:
                    continue
            entries = (process / "environ").read_bytes().split(b"\0")
        except (OSError, UnicodeError):
            continue

        values = {}
        for entry in entries:
            name, separator, value = entry.partition(b"=")
            if separator:
                name = os.fsdecode(name)
                if name in THEME_VARIABLES:
                    values[name] = os.fsdecode(value)
        yield process.name, values


def print_environment(label, values):
    print(f"\n{label}:")
    for name in THEME_VARIABLES:
        print(f"  {name}={values.get(name, '<unset>')}")


def main() -> int:
    print("Current task: compare qpwgraph startup and session theme environments.")
    print("Read-only: no processes, settings, or files will be changed.")
    print("Review the output for sensitive paths before sharing it.")

    if len(sys.argv) != 1:
        print("Usage: uv run x", file=sys.stderr)
        return 1
    proc_root = Path("/proc")
    if sys.platform != "linux" or not proc_root.is_dir():
        print("This diagnostic requires Linux with /proc.", file=sys.stderr)
        return 1

    print_environment("Current terminal", os.environ)
    found = False
    for process_id, values in qpwgraph_environments(proc_root, os.getuid()):
        found = True
        print_environment(f"qpwgraph PID {process_id}", values)
    if not found:
        print("\nNo readable qpwgraph process found for the current user.")
        return 1

    print("\nProcess values reflect startup, not the current visual theme.")
    return 0