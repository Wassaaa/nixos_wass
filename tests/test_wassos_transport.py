import contextlib
import io
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from wassos_transport import main


class TransportTests(unittest.TestCase):
    def test_declining_does_not_run_commands(self):
        with patch("builtins.input", return_value="no"), \
             patch("wassos_transport.subprocess.run") as run, \
             contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(main(), 1)
        run.assert_not_called()

    def test_verifies_stubs_without_printing_environment(self):
        with tempfile.TemporaryDirectory() as directory:
            (Path(directory) / "hl.meta.lua").write_text(
                "---@meta\n---@class HL.BindOptions\n---@field description string\n"
            )
            result = subprocess.CompletedProcess(
                [], 0,
                stdout=json.dumps({"WASSOS_HYPRLAND_LUA_STUBS": directory, "SECRET": "private"}),
                stderr="loaded\n",
            )
            with patch("builtins.input", return_value="yes"), \
                 patch("wassos_transport.subprocess.run", return_value=result) as run, \
                 contextlib.redirect_stdout(io.StringIO()) as output:
                self.assertEqual(main(), 0)
            self.assertEqual(run.call_args.args[0], ["direnv", "export", "json"])
            self.assertNotIn("DIRENV_DIFF", run.call_args.kwargs["env"])
            self.assertNotIn("private", output.getvalue())

    def test_reports_missing_stub_path(self):
        result = subprocess.CompletedProcess([], 0, stdout="{}", stderr="")
        with patch("builtins.input", return_value="yes"), \
             patch("wassos_transport.subprocess.run", return_value=result), \
             contextlib.redirect_stdout(io.StringIO()), \
             contextlib.redirect_stderr(io.StringIO()) as errors:
            self.assertEqual(main(), 1)
        self.assertIn("did not export", errors.getvalue())

    def test_reports_direnv_failure(self):
        result = subprocess.CompletedProcess([], 1, stdout="", stderr="failure\n")
        with patch("builtins.input", return_value="yes"), \
             patch("wassos_transport.subprocess.run", return_value=result), \
             contextlib.redirect_stdout(io.StringIO()), \
             contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(main(), 1)


if __name__ == "__main__":
    unittest.main()
