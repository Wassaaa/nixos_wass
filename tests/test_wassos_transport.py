import contextlib
import io
import unittest
from unittest.mock import patch

from wassos_transport import main


class TransportTests(unittest.TestCase):
    def test_expected_session_values(self):
        environment = {
            "LIBVA_DRIVER_NAME": "nvidia",
            "NVD_BACKEND": "direct",
            "XDG_SESSION_TYPE": "wayland",
            "HYPRLAND_INSTANCE_SIGNATURE": "private-signature",
            "WAYLAND_DISPLAY": "wayland-1",
            "SECRET": "private-secret",
        }
        with patch.dict("os.environ", environment, clear=True), \
             contextlib.redirect_stdout(io.StringIO()) as output:
            self.assertEqual(main(), 0)
        self.assertIn("LIBVA_DRIVER_NAME: expected value present (nvidia)", output.getvalue())
        self.assertNotIn("private-signature", output.getvalue())
        self.assertNotIn("private-secret", output.getvalue())

    def test_missing_or_different_values(self):
        environment = {"LIBVA_DRIVER_NAME": "other-private-value"}
        with patch.dict("os.environ", environment, clear=True), \
             contextlib.redirect_stdout(io.StringIO()) as output:
            self.assertEqual(main(), 1)
        self.assertIn("LIBVA_DRIVER_NAME: expected nvidia; missing or different", output.getvalue())
        self.assertIn("HYPRLAND_INSTANCE_SIGNATURE: missing", output.getvalue())
        self.assertIn("fresh Hyprland login", output.getvalue())
        self.assertNotIn("other-private-value", output.getvalue())


if __name__ == "__main__":
    unittest.main()
