import contextlib
import importlib.util
import io
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch


SOURCE = (
    Path(__file__).resolve().parents[1]
    / "modules"
    / "home"
    / "features"
    / "desktop"
    / "keybindings-viewer"
    / "records.py"
)
spec = importlib.util.spec_from_file_location("keybinding_records", SOURCE)
records = importlib.util.module_from_spec(spec)
spec.loader.exec_module(records)


class KeybindingRecordsTest(unittest.TestCase):
    def test_formats_runtime_binds_for_upstream_viewer(self):
        bindings = [
            {"modmask": 65, "key": "SUPER + SHIFT + F", "description": "Toggle floating", "dispatcher": "__lua", "arg": ""},
            {"modmask": 64, "key": "mouse:272", "description": "Drag window", "dispatcher": "__lua", "arg": ""},
            {"modmask": 0, "key": "XF86AudioMute", "description": "Toggle audio mute", "dispatcher": "__lua", "arg": ""},
            {"modmask": 64, "key": "", "keycode": 20, "description": "Physical key", "dispatcher": "__lua", "arg": ""},
        ]
        self.assertEqual(list(records.records(bindings)), [
            "SUPER SHIFT + F \u2192 Toggle floating\t__lua\t",
            "SUPER + LEFT MOUSE BUTTON \u2192 Drag window\t__lua\t",
            "XF86AudioMute \u2192 Toggle audio mute\t__lua\t",
            "SUPER + code:20 \u2192 Physical key\t__lua\t",
        ])

    def test_excludes_other_submaps_and_labels_missing_descriptions(self):
        bindings = [
            {"modmask": 64, "key": "K", "description": "", "submap": "viewer"},
            {"modmask": 0, "key": "Print", "submap": "", "dispatcher": "__lua"},
        ]
        self.assertEqual(list(records.records(bindings)), ["Print \u2192 Unlabelled shortcut\t__lua\t"])

    def test_formats_physical_key_bindings(self):
        bindings = [
            {"modmask": 64, "key": "", "keycode": 20, "description": "Physical key"},
            {"modmask": 0, "key": "Print", "keycode": 0},
            {"modmask": 64, "key": "", "keycode": 21, "description": "Other", "submap": "viewer"},
        ]
        self.assertEqual(list(records.physical_records(bindings)), ["bind\t64\t20\tPhysical key"])

    def test_rejects_bad_input(self):
        for bindings in (None, [{}], [{"modmask": 128, "key": "K"}], [{"modmask": True, "key": "K"}]):
            with self.subTest(bindings=bindings), self.assertRaises((ValueError, KeyError)):
                list(records.records(bindings))

    def test_propagates_hyprctl_error(self):
        failure = subprocess.CalledProcessError(1, ["hyprctl"], stderr="connection failed")
        with patch.object(records.sys, "argv", ["records.py", "--print"]), \
             patch.object(records.subprocess, "run", side_effect=failure):
            with self.assertRaises(subprocess.CalledProcessError):
                records.main()

    def test_writes_records_from_hyprctl(self):
        response = subprocess.CompletedProcess(
            [], 0, stdout='[{"modmask": 64, "key": "L", "description": "Lock screen"}]'
        )
        output = io.StringIO()
        with patch.object(records.sys, "argv", ["records.py", "--print"]), \
             patch.object(records.subprocess, "run", return_value=response) as run, \
             contextlib.redirect_stdout(output):
            records.main()
        run.assert_called_once_with(["hyprctl", "binds", "-j"], check=True, capture_output=True, text=True)
        self.assertEqual(output.getvalue(), "SUPER + L \u2192 Lock screen\t\t\n")


if __name__ == "__main__":
    unittest.main()
