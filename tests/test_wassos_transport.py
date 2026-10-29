import contextlib
import io
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest import mock

from wassos_transport import edid_identity, inspect_connectors, main, run_query


def sample_edid():
    data = bytearray(128)
    data[:8] = b"\x00\xff\xff\xff\xff\xff\xff\x00"
    data[8:10] = ((1 << 10) | (3 << 5) | 18).to_bytes(2, "big")
    data[10:12] = (0x1234).to_bytes(2, "little")
    data[54:72] = b"\x00\x00\x00\xfc\x00Predator X\n  "
    return bytes(data)


class MonitorDiagnosticTests(unittest.TestCase):
    def test_reads_monitor_identity_without_serial(self):
        data = bytearray(sample_edid())
        data[12:16] = b"SECR"
        self.assertEqual(edid_identity(data), ("ACR", "0x1234", "Predator X"))

    def test_rejects_invalid_edid(self):
        with self.assertRaises(ValueError):
            edid_identity(b"invalid")

    def test_inspects_dp2_connector_and_device(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            connector = root / "drm" / "card1-DP-2"
            connector.mkdir(parents=True)
            (connector / "status").write_text("connected\n")
            (connector / "edid").write_bytes(sample_edid())
            adapter = root / "i2c-7"
            adapter.mkdir()
            device_root = root / "dev"
            device_root.mkdir()
            (device_root / "i2c-7").touch()
            with (
                mock.patch("pathlib.Path.resolve", return_value=adapter),
                contextlib.redirect_stdout(io.StringIO()) as output,
            ):
                self.assertTrue(inspect_connectors(root / "drm", device_root))
            self.assertIn("Predator X", output.getvalue())
            self.assertIn("i2c-7", output.getvalue())

    def test_reports_missing_connector(self):
        with tempfile.TemporaryDirectory() as directory:
            with contextlib.redirect_stdout(io.StringIO()) as output:
                self.assertFalse(inspect_connectors(Path(directory), Path(directory)))
            self.assertIn("No DRM connector", output.getvalue())

    def test_detection_failure_is_reported(self):
        with (
            mock.patch("wassos_transport.subprocess.run", side_effect=subprocess.TimeoutExpired("ddcutil", 90)),
            contextlib.redirect_stdout(io.StringIO()),
            contextlib.redirect_stderr(io.StringIO()) as errors,
        ):
            self.assertFalse(run_query(["ddcutil", "detect"], "Detecting"))
        self.assertIn("failed", errors.getvalue())

    def test_rejects_non_linux(self):
        with (
            mock.patch("sys.argv", ["x"]),
            mock.patch("wassos_transport.sys.platform", "win32"),
            contextlib.redirect_stdout(io.StringIO()),
            contextlib.redirect_stderr(io.StringIO()) as errors,
        ):
            self.assertEqual(main(), 1)
        self.assertIn("requires Linux", errors.getvalue())

    def test_declined_download_never_runs_nix(self):
        with (
            mock.patch("sys.argv", ["x"]),
            mock.patch("wassos_transport.sys.platform", "linux"),
            mock.patch("wassos_transport.inspect_connectors", return_value=True),
            mock.patch("wassos_transport.shutil.which", return_value=None),
            mock.patch("wassos_transport.sys.stdin.isatty", return_value=True),
            mock.patch("builtins.input", return_value="no"),
            mock.patch("wassos_transport.subprocess.run") as run,
            contextlib.redirect_stdout(io.StringIO()),
        ):
            self.assertEqual(main(), 1)
            run.assert_not_called()

    def test_confirmed_download_runs_read_only_detection(self):
        with (
            mock.patch("sys.argv", ["x"]),
            mock.patch("wassos_transport.sys.platform", "linux"),
            mock.patch("wassos_transport.inspect_connectors", return_value=True),
            mock.patch("wassos_transport.shutil.which", return_value=None),
            mock.patch("wassos_transport.sys.stdin.isatty", return_value=True),
            mock.patch("builtins.input", side_effect=["yes", ""]),
            mock.patch("wassos_transport.run_query", return_value=True) as detect,
            contextlib.redirect_stdout(io.StringIO()),
        ):
            self.assertEqual(main(), 0)
            detect.assert_called_once_with(
                ["nix", "shell", "--inputs-from", ".", "nixpkgs#ddcutil", "--command", "ddcutil", "detect"],
                "Detecting DDC-capable displays",
            )

    def test_selected_bus_runs_only_read_queries(self):
        with (
            mock.patch("sys.argv", ["x"]),
            mock.patch("wassos_transport.sys.platform", "linux"),
            mock.patch("wassos_transport.inspect_connectors", return_value=True),
            mock.patch("wassos_transport.shutil.which", return_value="ddcutil"),
            mock.patch("wassos_transport.sys.stdin.isatty", return_value=True),
            mock.patch("builtins.input", return_value="7"),
            mock.patch("wassos_transport.run_query", return_value=True) as query,
            contextlib.redirect_stdout(io.StringIO()),
        ):
            self.assertEqual(main(), 0)
            self.assertEqual([call.args[0] for call in query.call_args_list], [
                ["ddcutil", "detect"],
                ["ddcutil", "--bus", "7", "getvcp", "60"],
                ["ddcutil", "--bus", "7", "capabilities"],
            ])

    def test_invalid_bus_is_not_queried(self):
        with (
            mock.patch("sys.argv", ["x"]),
            mock.patch("wassos_transport.sys.platform", "linux"),
            mock.patch("wassos_transport.inspect_connectors", return_value=True),
            mock.patch("wassos_transport.shutil.which", return_value="ddcutil"),
            mock.patch("wassos_transport.sys.stdin.isatty", return_value=True),
            mock.patch("builtins.input", return_value="7;setvcp"),
            mock.patch("wassos_transport.run_query", return_value=True) as query,
            contextlib.redirect_stdout(io.StringIO()),
            contextlib.redirect_stderr(io.StringIO()),
        ):
            self.assertEqual(main(), 1)
            self.assertEqual(query.call_count, 1)


if __name__ == "__main__":
    unittest.main()
