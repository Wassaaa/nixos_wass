import contextlib
import io
from pathlib import Path
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest import mock

from wassos_transport import (
    ask_bus, bus_snapshot, connector_snapshot, detect_acer_buses, edid_identity,
    inspect_connectors, inspect_i2c, main, read_brightness,
)


def sample_edid():
    data = bytearray(128)
    data[:8] = b"\x00\xff\xff\xff\xff\xff\xff\x00"
    data[8:10] = ((1 << 10) | (3 << 5) | 18).to_bytes(2, "big")
    data[10:12] = (0x0490).to_bytes(2, "little")
    data[54:72] = b"\x00\x00\x00\xfc\x00XB271HU\n     "
    return bytes(data)


class MonitorDiagnosticTests(unittest.TestCase):
    def test_reads_monitor_identity_without_serial(self):
        data = bytearray(sample_edid())
        data[12:16] = b"SECR"
        self.assertEqual(edid_identity(data), ("ACR", "0x0490", "XB271HU"))
        with self.assertRaises(ValueError):
            edid_identity(b"invalid")

    def test_connector_snapshot_requires_connected_expected_monitor(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            connector = root / "card1-DP-2"
            connector.mkdir()
            (connector / "status").write_text("connected\n")
            (connector / "edid").write_bytes(sample_edid())
            self.assertEqual(connector_snapshot(root), ("card1-DP-2", sample_edid()))
            (connector / "status").write_text("disconnected\n")
            with self.assertRaises(ValueError):
                connector_snapshot(root)
            (connector / "status").write_text("connected\n")
            (connector / "edid").write_bytes(b"invalid")
            with self.assertRaises(ValueError):
                connector_snapshot(root)
            (root / "card2-DP-2").mkdir()
            with self.assertRaises(ValueError):
                connector_snapshot(root)

    def test_bus_snapshot_requires_existing_device_and_access(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "i2c-8").touch()
            stat = SimpleNamespace(st_dev=1, st_ino=2, st_rdev=3)
            with (
                mock.patch("wassos_transport.os.access", return_value=True),
                mock.patch.object(Path, "stat", return_value=stat),
            ):
                self.assertEqual(bus_snapshot("8", root, root)[0], (root / "i2c-8").resolve())
                with self.assertRaises(OSError):
                    bus_snapshot("9", root, root)
            with (
                mock.patch("wassos_transport.os.access", return_value=False),
                mock.patch.object(Path, "stat", return_value=stat),
            ):
                with self.assertRaises(ValueError):
                    bus_snapshot("8", root, root)

    def test_inspects_connector_and_i2c(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            connector = root / "drm" / "card1-DP-2"
            connector.mkdir(parents=True)
            (connector / "status").write_text("connected\n")
            (connector / "edid").write_bytes(sample_edid())
            (root / "i2c-8").touch()
            with contextlib.redirect_stdout(io.StringIO()) as output:
                self.assertTrue(inspect_connectors(root / "drm", root))
                self.assertTrue(inspect_i2c(root, root / "i2c_dev"))
            self.assertIn("XB271HU", output.getvalue())
            self.assertIn("i2c-8", output.getvalue())

    def test_detect_only_identifies_acer_bus_without_printing_serials(self):
        response = (
            "Display 1\n   I2C bus: /dev/i2c-7\n   Monitor: SAM:S27C31x:secret1\n\n"
            "Display 2\n   I2C bus: /dev/i2c-8\n   Monitor: ACR:XB271HU:secret2\n"
        )
        with (
            mock.patch("wassos_transport.subprocess.run", return_value=subprocess.CompletedProcess([], 0, response, "")),
            contextlib.redirect_stdout(io.StringIO()) as output,
        ):
            self.assertEqual(detect_acer_buses(["ddcutil"]), {"8"})
            self.assertNotIn("secret", output.getvalue())

    def test_detect_failure_is_reported(self):
        with (
            mock.patch("wassos_transport.subprocess.run", side_effect=subprocess.TimeoutExpired("ddcutil", 240)),
            contextlib.redirect_stdout(io.StringIO()),
            contextlib.redirect_stderr(io.StringIO()) as errors,
        ):
            self.assertIsNone(detect_acer_buses(["ddcutil"]))
        self.assertIn("failed", errors.getvalue())

    def test_wrong_bus_is_rejected(self):
        with (
            mock.patch("builtins.input", return_value="7"),
            contextlib.redirect_stderr(io.StringIO()),
        ):
            self.assertIsNone(ask_bus({"8"}))

    def test_brightness_command_is_targeted_and_read_only(self):
        with (
            tempfile.TemporaryDirectory() as directory,
            mock.patch("wassos_transport.subprocess.run",
                       return_value=subprocess.CompletedProcess([], 0, "VCP code 0x10 (Brightness): current value = 50\n", "warning")) as run,
            contextlib.redirect_stdout(io.StringIO()),
            contextlib.redirect_stderr(io.StringIO()),
        ):
            output = Path(directory) / "baseline.txt"
            self.assertTrue(read_brightness(["ddcutil"], "8", output))
            self.assertEqual(run.call_args.args[0],
                             ["ddcutil", "--bus", "8", "--ddcdata", "--stats=all", "getvcp", "10"])
            self.assertIn("current value = 50", output.read_text())
            self.assertIn("warning", output.read_text())

    def test_success_without_brightness_value_is_not_a_usable_read(self):
        with (
            tempfile.TemporaryDirectory() as directory,
            mock.patch("wassos_transport.subprocess.run",
                       return_value=subprocess.CompletedProcess([], 0, "statistics only", "")),
            contextlib.redirect_stdout(io.StringIO()),
            contextlib.redirect_stderr(io.StringIO()) as errors,
        ):
            self.assertFalse(read_brightness(["ddcutil"], "8", Path(directory) / "result.txt"))
            self.assertIn("did not return a brightness value", errors.getvalue())

    def test_failed_or_timed_out_read_preserves_output(self):
        outcomes = [
            subprocess.CompletedProcess([], 1, "failed", "EIO"),
            subprocess.TimeoutExpired("ddcutil", 240, output=b"failed", stderr=b"EIO"),
        ]
        for outcome in outcomes:
            with self.subTest(outcome=outcome), tempfile.TemporaryDirectory() as directory:
                runner = mock.Mock(side_effect=outcome) if isinstance(outcome, Exception) else mock.Mock(return_value=outcome)
                with (
                    mock.patch("wassos_transport.subprocess.run", runner),
                    contextlib.redirect_stdout(io.StringIO()),
                    contextlib.redirect_stderr(io.StringIO()),
                ):
                    output = Path(directory) / "result.txt"
                    self.assertFalse(read_brightness(["ddcutil"], "8", output))
                    self.assertIn("failed", output.read_text())
                    self.assertIn("EIO", output.read_text())

    def run_main(self, answers, connector_values=None, adapter_values=None, read_values=None):
        with (
            tempfile.TemporaryDirectory() as directory,
            mock.patch("sys.argv", ["x"]),
            mock.patch("wassos_transport.sys.platform", "linux"),
            mock.patch("wassos_transport.inspect_connectors", return_value=True),
            mock.patch("wassos_transport.inspect_i2c", return_value=True),
            mock.patch("wassos_transport.shutil.which", return_value="ddcutil"),
            mock.patch("wassos_transport.sys.stdin.isatty", return_value=True),
            mock.patch("builtins.input", side_effect=answers),
            mock.patch("wassos_transport.detect_acer_buses", return_value={"8"}) as detect,
            mock.patch("wassos_transport.connector_snapshot", side_effect=connector_values or [("card1-DP-2", b"edid")] * 2),
            mock.patch("wassos_transport.bus_snapshot", side_effect=adapter_values or [("adapter", 1, 2, 3)] * 2),
            mock.patch("wassos_transport.read_brightness", side_effect=read_values or [True, True]) as read,
            mock.patch("pathlib.Path.home", return_value=Path(directory)),
            contextlib.redirect_stdout(io.StringIO()) as output,
            contextlib.redirect_stderr(io.StringIO()) as errors,
        ):
            result = main()
            return result, detect.call_count, read.call_args_list, output.getvalue(), errors.getvalue()

    def test_hdmi_reads_same_identified_bus_without_redetecting(self):
        result, detects, reads, output, _ = self.run_main(["8", "start", "ready"])
        self.assertEqual(result, 0)
        self.assertEqual(detects, 1)
        self.assertEqual([call.args[1] for call in reads], ["8", "8"])
        self.assertIn("return to DisplayPort", output)

    def test_changed_connector_or_bus_skips_hdmi_read(self):
        for keyword, values in [
            ("connector_values", [("card1-DP-2", b"edid"), ("card1-DP-2", b"changed")]),
            ("adapter_values", [("adapter", 1, 2, 3), ("adapter", 1, 4, 3)]),
        ]:
            with self.subTest(keyword=keyword):
                result, _, reads, output, errors = self.run_main(["8", "start", "ready"], **{keyword: values})
                self.assertEqual(result, 1)
                self.assertEqual(len(reads), 1)
                self.assertIn("HDMI read skipped", errors)
                self.assertIn("return to DisplayPort", output)

    def test_baseline_failure_or_cancellation_skips_hdmi(self):
        for answers, reads in [(["8", "start"], [False]), (["8", "start", ""], [True])]:
            with self.subTest(answers=answers):
                result, _, calls, _, _ = self.run_main(answers, read_values=reads)
                self.assertEqual(result, 1)
                self.assertEqual(len(calls), 1)

    def test_baseline_requires_confirmation(self):
        result, _, reads, output, _ = self.run_main(["8", ""])
        self.assertEqual(result, 1)
        self.assertFalse(reads)
        self.assertIn("no comparison files were created", output)

    def test_disappearing_bus_skips_hdmi_read(self):
        result, _, reads, output, errors = self.run_main(
            ["8", "start", "ready"], adapter_values=[("adapter", 1, 2, 3), OSError("device missing")]
        )
        self.assertEqual(result, 1)
        self.assertEqual(len(reads), 1)
        self.assertIn("HDMI read skipped", errors)
        self.assertIn("return to DisplayPort", output)

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

    def test_failed_hdmi_read_is_reported_and_return_reminder_shown(self):
        result, _, reads, output, errors = self.run_main(["8", "start", "ready"], read_values=[True, False])
        self.assertEqual(result, 1)
        self.assertEqual(len(reads), 2)
        self.assertIn("does not prove all DDC requests are impossible", errors)
        self.assertIn("return to DisplayPort", output)

    def test_rejects_non_linux(self):
        with (
            mock.patch("sys.argv", ["x"]),
            mock.patch("wassos_transport.sys.platform", "win32"),
            contextlib.redirect_stdout(io.StringIO()),
            contextlib.redirect_stderr(io.StringIO()) as errors,
        ):
            self.assertEqual(main(), 1)
        self.assertIn("requires Linux", errors.getvalue())


if __name__ == "__main__":
    unittest.main()
