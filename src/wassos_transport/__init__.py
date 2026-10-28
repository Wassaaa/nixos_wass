import json
import os
from pathlib import Path
import sys


EXTENSION_ID = "aeblfdkhhhdcdjpifhhbdiojplfjncoa"
UPDATE_URL = "https://clients2.google.com/service/update2/crx"


def main() -> int:
    if len(sys.argv) != 1:
        print("Usage: uv run x", file=sys.stderr)
        return 1

    print("Current task: inspect the Brave 1Password extension registration.")
    print("This reads local browser configuration; it makes no changes.")

    config_home = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
    browser_dir = config_home / "BraveSoftware" / "Brave-Browser"
    registration = browser_dir / "External Extensions" / f"{EXTENSION_ID}.json"

    try:
        if registration.is_file():
            data = json.loads(registration.read_text(encoding="utf-8"))
            valid = isinstance(data, dict) and data.get("external_update_url") == UPDATE_URL
            print(f"Extension registration: {'valid' if valid else 'unexpected content'}")
        else:
            print("Extension registration: missing")

        profile_count = 0
        installed_count = 0
        if browser_dir.is_dir():
            for profile in browser_dir.iterdir():
                if not profile.is_dir():
                    continue
                preference_files = [profile / "Preferences", profile / "Secure Preferences"]
                if not any(path.is_file() for path in preference_files):
                    continue
                profile_count += 1
                for path in preference_files:
                    if not path.is_file():
                        continue
                    data = json.loads(path.read_text(encoding="utf-8"))
                    settings = data.get("extensions", {}).get("settings", {})
                    if EXTENSION_ID in settings:
                        installed_count += 1
                        break
        print(f"Profiles inspected: {profile_count}")
        print(f"Profiles recording 1Password: {installed_count}")
    except (OSError, ValueError, AttributeError, TypeError) as error:
        print(f"Could not inspect Brave configuration: {type(error).__name__}", file=sys.stderr)
        return 1
    return 0
