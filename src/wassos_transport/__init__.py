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
        recorded_count = 0
        install_metadata_count = 0
        extension_files_count = 0
        external_uninstall_count = 0
        disabled_count = 0
        disable_reasons = set()
        if browser_dir.is_dir():
            for profile in browser_dir.iterdir():
                if not profile.is_dir():
                    continue
                preference_files = [profile / "Preferences", profile / "Secure Preferences"]
                if not any(path.is_file() for path in preference_files):
                    continue
                profile_count += 1
                recorded = False
                install_metadata = False
                external_uninstall = False
                profile_disable_reasons = set()
                for path in preference_files:
                    if not path.is_file():
                        continue
                    data = json.loads(path.read_text(encoding="utf-8"))
                    extensions = data.get("extensions", {})
                    settings = extensions.get("settings", {})
                    external_uninstall |= EXTENSION_ID in extensions.get("external_uninstalls", [])
                    entry = settings.get(EXTENSION_ID)
                    if isinstance(entry, dict):
                        recorded = True
                        install_metadata |= isinstance(entry.get("location"), int) and isinstance(
                            entry.get("path"), str
                        )
                        reasons = entry.get("disable_reasons", [])
                        if isinstance(reasons, int):
                            reasons = [reasons]
                        if isinstance(reasons, list):
                            profile_disable_reasons.update(
                                reason for reason in reasons if type(reason) is int and 0 < reason < 2**31
                            )
                recorded_count += recorded
                install_metadata_count += install_metadata
                external_uninstall_count += external_uninstall
                extension_files_count += (profile / "Extensions" / EXTENSION_ID).is_dir()
                disabled_count += bool(profile_disable_reasons)
                disable_reasons.update(profile_disable_reasons)
        print(f"Profiles inspected: {profile_count}")
        print(f"Profiles recording 1Password: {recorded_count}")
        print(f"Profiles with installation metadata: {install_metadata_count}")
        print(f"Profiles with extension files: {extension_files_count}")
        print(f"Profiles remembering an external uninstall: {external_uninstall_count}")
        print(f"Profiles with recorded disable reasons: {disabled_count}")
        print(f"Disable reason codes: {sorted(disable_reasons)}")
    except (OSError, ValueError, AttributeError, TypeError) as error:
        print(f"Could not inspect Brave configuration: {type(error).__name__}", file=sys.stderr)
        return 1
    return 0
