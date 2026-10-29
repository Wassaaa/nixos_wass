import contextlib
import io
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest import mock

from wassos_transport import (
    VENDOR_CODES, compare_values, detect_acer_buses, edid_identity, inspect_connectors,
    inspect_i2c, main, read_vendor_values,
)


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
            self.assertIsNone(detect_acer_buses(["ddcutil"], "DisplayPort"))
        self.assertIn("failed", errors.getvalue())

    def test_detect_only_identifies_acer_bus_without_printing_serials(self):
        response = (
            "Display 1\n   I2C bus: /dev/i2c-7\n   Monitor: SAM:S27C31x:secret1\n\n"
            "Display 2\n   I2C bus: /dev/i2c-8\n   Monitor: ACR:XB271HU:secret2\n"
        )
        with (
            mock.patch(
                "wassos_transport.subprocess.run",
                return_value=subprocess.CompletedProcess([], 0, response, ""),
            ) as run,
            contextlib.redirect_stdout(io.StringIO()) as output,
        ):
            self.assertEqual(detect_acer_buses(["ddcutil"], "HDMI"), {"8"})
            self.assertNotIn("secret", output.getvalue())
            run.assert_called_once_with(
                ["ddcutil", "detect", "--brief"], timeout=240, check=False,
                capture_output=True, text=True, encoding="utf-8", errors="replace",
            )

    def test_lists_i2c_device_access(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "i2c-7").touch()
            (root / "i2c-other").touch()
            with contextlib.redirect_stdout(io.StringIO()) as output:
                self.assertTrue(inspect_i2c(root, root / "i2c_dev"))
            self.assertIn("i2c-7", output.getvalue())
            self.assertNotIn("i2c-other", output.getvalue())

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
            mock.patch("wassos_transport.inspect_i2c", return_value=True),
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
            mock.patch("wassos_transport.inspect_i2c", return_value=True),
            mock.patch("wassos_transport.shutil.which", return_value=None),
            mock.patch("wassos_transport.sys.stdin.isatty", return_value=True),
            mock.patch("builtins.input", return_value="yes"),
            mock.patch("wassos_transport.detect_acer_buses", return_value=set()) as detect,
            contextlib.redirect_stdout(io.StringIO()),
        ):
            self.assertEqual(main(), 1)
            detect.assert_called_once_with(
                ["nix", "shell", "--inputs-from", ".", "nixpkgs#ddcutil", "--command", "ddcutil"],
                "DisplayPort",
            )

    def test_comparison_requires_two_confirmations_and_reselects_bus(self):
        with (
            mock.patch("sys.argv", ["x"]),
            mock.patch("wassos_transport.sys.platform", "linux"),
            mock.patch("wassos_transport.inspect_connectors", return_value=True),
            mock.patch("wassos_transport.inspect_i2c", return_value=True),
            mock.patch("wassos_transport.shutil.which", return_value="ddcutil"),
            mock.patch("wassos_transport.sys.stdin.isatty", return_value=True),
            mock.patch("builtins.input", side_effect=["8", "start", "ready", "9"]),
            mock.patch("wassos_transport.detect_acer_buses", side_effect=[{"8"}, {"9"}]) as query,
            mock.patch("wassos_transport.read_vendor_values", side_effect=[
                ({"e0": "00 00 00 00"}, True),
                ({"e0": "00 00 00 01"}, True),
            ]) as read,
            tempfile.TemporaryDirectory() as directory,
            mock.patch("pathlib.Path.home", return_value=Path(directory)),
            contextlib.redirect_stdout(io.StringIO()),
        ):
            self.assertEqual(main(), 0)
            self.assertEqual(query.call_count, 2)
            self.assertEqual(read.call_args_list[0].args[0], ["ddcutil", "--bus", "8"])
            self.assertEqual(read.call_args_list[1].args[0], ["ddcutil", "--bus", "9"])

    def test_baseline_confirmation_is_required(self):
        with (
            mock.patch("sys.argv", ["x"]),
            mock.patch("wassos_transport.sys.platform", "linux"),
            mock.patch("wassos_transport.inspect_connectors", return_value=True),
            mock.patch("wassos_transport.inspect_i2c", return_value=True),
            mock.patch("wassos_transport.shutil.which", return_value="ddcutil"),
            mock.patch("wassos_transport.sys.stdin.isatty", return_value=True),
            mock.patch("builtins.input", side_effect=["7", ""]),
            mock.patch("wassos_transport.detect_acer_buses", return_value={"7"}),
            mock.patch("wassos_transport.read_vendor_values") as read,
            contextlib.redirect_stdout(io.StringIO()),
        ):
            self.assertEqual(main(), 1)
            read.assert_not_called()

    def test_comparison_cancel_after_baseline_does_not_query_again(self):
        with (
            mock.patch("sys.argv", ["x"]),
            mock.patch("wassos_transport.sys.platform", "linux"),
            mock.patch("wassos_transport.inspect_connectors", return_value=True),
            mock.patch("wassos_transport.inspect_i2c", return_value=True),
            mock.patch("wassos_transport.shutil.which", return_value="ddcutil"),
            mock.patch("wassos_transport.sys.stdin.isatty", return_value=True),
            mock.patch("builtins.input", side_effect=["8", "start", ""]),
            mock.patch("wassos_transport.detect_acer_buses", return_value={"8"}) as query,
            mock.patch("wassos_transport.read_vendor_values", return_value=({"e0": "00 00 00 00"}, True)) as read,
            tempfile.TemporaryDirectory() as directory,
            mock.patch("pathlib.Path.home", return_value=Path(directory)),
            contextlib.redirect_stdout(io.StringIO()) as output,
        ):
            self.assertEqual(main(), 1)
            self.assertEqual(query.call_count, 1)
            self.assertEqual(read.call_count, 1)
            self.assertIn("return to DisplayPort", output.getvalue())

    def test_missing_acer_on_hdmi_does_not_query_other_display(self):
        with (
            mock.patch("sys.argv", ["x"]),
            mock.patch("wassos_transport.sys.platform", "linux"),
            mock.patch("wassos_transport.inspect_connectors", return_value=True),
            mock.patch("wassos_transport.inspect_i2c", return_value=True),
            mock.patch("wassos_transport.shutil.which", return_value="ddcutil"),
            mock.patch("wassos_transport.sys.stdin.isatty", return_value=True),
            mock.patch("builtins.input", side_effect=["8", "start", "ready"]),
            mock.patch("wassos_transport.detect_acer_buses", side_effect=[{"8"}, set()]),
            mock.patch("wassos_transport.read_vendor_values", return_value=({"e0": "00 00 00 00"}, True)) as read,
            tempfile.TemporaryDirectory() as directory,
            mock.patch("pathlib.Path.home", return_value=Path(directory)),
            contextlib.redirect_stdout(io.StringIO()) as output,
        ):
            self.assertEqual(main(), 1)
            self.assertEqual(read.call_count, 1)
            self.assertIn("No Acer bus selected", output.getvalue())
            self.assertIn("return to DisplayPort", output.getvalue())

    def test_reads_only_previously_responsive_vendor_codes(self):
        raw = "".join(
            f"Raw value: opcode=0x{code}, mh=0x00, ml=0x00, sh=0x00, sl=0x01\n"
            for code in VENDOR_CODES
        )
        with (
            tempfile.TemporaryDirectory() as directory,
            mock.patch(
                "wassos_transport.subprocess.run",
                return_value=subprocess.CompletedProcess([], 0, raw, ""),
            ) as run,
            contextlib.redirect_stdout(io.StringIO()),
        ):
            output = Path(directory) / "baseline.txt"
            values, complete = read_vendor_values(["ddcutil", "--bus", "8"], output)
            self.assertTrue(complete)
            self.assertEqual(values["e0"], "00 00 00 01")
            self.assertIn("0xe0", output.read_text())
            self.assertEqual(
                run.call_args.args[0],
                ["ddcutil", "--bus", "8", "--verbose", "getvcp"]
                + list(VENDOR_CODES),
            )

    def test_failed_reads_preserve_output_and_report_incomplete(self):
        with (
            tempfile.TemporaryDirectory() as directory,
            mock.patch(
                "wassos_transport.subprocess.run",
                return_value=subprocess.CompletedProcess([], 1, "VCP code 0xe0: EIO\n", "read failed"),
            ),
            contextlib.redirect_stdout(io.StringIO()),
            contextlib.redirect_stderr(io.StringIO()) as errors,
        ):
            output = Path(directory) / "baseline.txt"
            self.assertIsNone(read_vendor_values(["ddcutil", "--bus", "8"], output))
            self.assertIn("EIO", output.read_text())
            self.assertIn("status: 1", errors.getvalue())

    def test_timeout_preserves_partial_output(self):
        timeout = subprocess.TimeoutExpired("ddcutil", 300, output=b"partial", stderr=b"warning")
        with (
            tempfile.TemporaryDirectory() as directory,
            mock.patch("wassos_transport.subprocess.run", side_effect=timeout),
            contextlib.redirect_stdout(io.StringIO()),
            contextlib.redirect_stderr(io.StringIO()) as errors,
        ):
            output = Path(directory) / "baseline.txt"
            self.assertIsNone(read_vendor_values(["ddcutil", "--bus", "8"], output))
            self.assertIn("partial", output.read_text())
            self.assertIn("timed out", errors.getvalue())

    def test_partial_values_are_retained_without_claiming_completeness(self):
        raw = "Raw value: opcode=0xe0, mh=0x00, ml=0x00, sh=0x00, sl=0x01\n"
        with (
            tempfile.TemporaryDirectory() as directory,
            mock.patch(
                "wassos_transport.subprocess.run",
                return_value=subprocess.CompletedProcess([], 1, raw, "EIO"),
            ),
            contextlib.redirect_stdout(io.StringIO()),
            contextlib.redirect_stderr(io.StringIO()) as errors,
        ):
            values, complete = read_vendor_values(["ddcutil", "--bus", "8"], Path(directory) / "baseline.txt")
            self.assertFalse(complete)
            self.assertEqual(values["e0"], "00 00 00 01")
            self.assertIn("results may be incomplete", errors.getvalue())

    def test_compare_does_not_confuse_missing_values_with_changes(self):
        with contextlib.redirect_stdout(io.StringIO()) as output:
            self.assertTrue(compare_values({"e0": "00", "e1": "01"}, {"e0": "00", "f9": "01"}))
        self.assertIn("0xe0: 00 -> 00 (unchanged)", output.getvalue())
        self.assertIn("Unavailable in one stage: 0xe1, 0xf9", output.getvalue())
        self.assertNotIn("0xe1: ", output.getvalue())

    def test_invalid_bus_is_not_queried(self):
        with (
            mock.patch("sys.argv", ["x"]),
            mock.patch("wassos_transport.sys.platform", "linux"),
            mock.patch("wassos_transport.inspect_connectors", return_value=True),
            mock.patch("wassos_transport.inspect_i2c", return_value=True),
            mock.patch("wassos_transport.shutil.which", return_value="ddcutil"),
            mock.patch("wassos_transport.sys.stdin.isatty", return_value=True),
            mock.patch("builtins.input", return_value="7;setvcp"),
            mock.patch("wassos_transport.detect_acer_buses", return_value={"8"}) as query,
            contextlib.redirect_stdout(io.StringIO()),
            contextlib.redirect_stderr(io.StringIO()),
        ):
            self.assertEqual(main(), 1)
            self.assertEqual(query.call_count, 1)


if __name__ == "__main__":
    unittest.main()
