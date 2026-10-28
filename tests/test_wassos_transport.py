import contextlib
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest import mock

from wassos_transport import EXTENSION_ID, UPDATE_URL, main


class BraveDiagnosticTests(unittest.TestCase):
    def run_diagnostic(self, config_home: Path) -> str:
        output = io.StringIO()
        with (
            mock.patch.dict(os.environ, {"XDG_CONFIG_HOME": str(config_home)}),
            mock.patch("sys.argv", ["x"]),
            contextlib.redirect_stdout(output),
        ):
            self.assertEqual(main(), 0)
        return output.getvalue()

    def test_missing_registration_and_profiles(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = self.run_diagnostic(Path(directory))

        self.assertIn("Extension registration: missing", output)
        self.assertIn("Profiles inspected: 0", output)
        self.assertIn("Profiles recording 1Password: 0", output)
        self.assertIn("Profiles with installation metadata: 0", output)
        self.assertIn("Profiles remembering an external uninstall: 0", output)

    def test_valid_registration_and_profile_record(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            config_home = Path(directory)
            browser_dir = config_home / "BraveSoftware" / "Brave-Browser"
            registration_dir = browser_dir / "External Extensions"
            registration_dir.mkdir(parents=True)
            (registration_dir / f"{EXTENSION_ID}.json").write_text(
                json.dumps({"external_update_url": UPDATE_URL}), encoding="utf-8"
            )
            profile = browser_dir / "Default"
            profile.mkdir()
            (profile / "Extensions" / EXTENSION_ID).mkdir(parents=True)
            (profile / "Preferences").write_text(
                json.dumps({"extensions": {"settings": {EXTENSION_ID: {"location": 1, "path": "secret"}}}}),
                encoding="utf-8",
            )
            (profile / "Secure Preferences").write_text(
                json.dumps({"extensions": {
                    "settings": {EXTENSION_ID: {"disable_reasons": [8192]}},
                    "external_uninstalls": [EXTENSION_ID],
                }}),
                encoding="utf-8",
            )
            output = self.run_diagnostic(config_home)

        self.assertIn("Extension registration: valid", output)
        self.assertIn("Profiles inspected: 1", output)
        self.assertIn("Profiles recording 1Password: 1", output)
        self.assertIn("Profiles with installation metadata: 1", output)
        self.assertIn("Profiles with extension files: 1", output)
        self.assertIn("Profiles remembering an external uninstall: 1", output)
        self.assertIn("Profiles with recorded disable reasons: 1", output)
        self.assertIn("Disable reason codes: [8192]", output)
        self.assertNotIn("secret", output)


if __name__ == "__main__":
    unittest.main()