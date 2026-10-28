import json
import subprocess
import sys

MODIFIERS = ((64, "SUPER"), (1, "SHIFT"), (4, "CTRL"), (8, "ALT"))
MOUSE = {
    "mouse:272": "LEFT MOUSE BUTTON",
    "mouse:273": "RIGHT MOUSE BUTTON",
    "mouse:274": "MIDDLE MOUSE BUTTON",
}


def entries(bindings):
    if not isinstance(bindings, list):
        raise ValueError("Hyprland returned an invalid bind list")
    for binding in bindings:
        if not isinstance(binding, dict):
            raise ValueError("Hyprland returned an invalid bind")
        if binding.get("submap") not in ("", "default", None):
            continue
        mask = binding["modmask"]
        if not isinstance(mask, int) or isinstance(mask, bool) or mask & ~77:
            raise ValueError(f"Unsupported modifier mask: {mask!r}")
        key = binding["key"]
        if not isinstance(key, str):
            raise ValueError("Hyprland returned an invalid key")
        key = key.rsplit(" + ", 1)[-1]
        keycode = binding.get("keycode", 0)
        if not isinstance(keycode, int) or isinstance(keycode, bool) or keycode < 0:
            raise ValueError(f"Invalid keycode: {keycode!r}")
        if not key and keycode:
            key = f"code:{keycode}"
        if not key:
            continue
        key = MOUSE.get(key.lower(), key)
        mods = " ".join(name for bit, name in MODIFIERS if mask & bit)
        combo = f"{mods} + {key}" if mods else key
        description = binding.get("description") or "Unlabelled shortcut"
        dispatcher = binding.get("dispatcher") or ""
        argument = binding.get("arg") or ""
        fields = (description, dispatcher, argument)
        if not all(isinstance(field, str) and "\n" not in field and "\t" not in field for field in fields):
            raise ValueError(f"Invalid metadata for {combo}")
        yield mask, keycode, combo, description, dispatcher, argument


def records(bindings):
    for _, _, combo, description, dispatcher, argument in entries(bindings):
        yield f"{combo} \u2192 {description}\t{dispatcher}\t{argument}"


def physical_records(bindings):
    for mask, keycode, _, description, _, _ in entries(bindings):
        if keycode:
            yield f"bind\t{mask}\t{keycode}\t{description}"


def main():
    if sys.argv[1:] not in (["--print"], ["--physical"]):
        raise ValueError("Expected --print or --physical")
    result = subprocess.run(
        ["hyprctl", "binds", "-j"], check=True, capture_output=True, text=True
    )
    render = records if sys.argv[1] == "--print" else physical_records
    for record in render(json.loads(result.stdout)):
        print(record)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        detail = error.stderr.strip() if isinstance(error, subprocess.CalledProcessError) and error.stderr else str(error)
        print(f"Could not list Hyprland keybindings: {detail}", file=sys.stderr)
        sys.exit(1)
