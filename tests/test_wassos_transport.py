import contextlib
import io
import subprocess
import unittest
from unittest.mock import patch

from wassos_transport import main


class TransportTests(unittest.TestCase):
    def test_declining_does_not_run_commands(self):
        with patch("builtins.input", return_value="no"), \
             patch("wassos_transport.subprocess.run") as run, \
             contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(main(), 1)
        run.assert_not_called()

    def test_checks_direnv_after_successful_switch_without_printing_environment(self):
        switch = subprocess.CompletedProcess([], 0)
        check = subprocess.CompletedProcess([], 0, stdout="SECRET=private", stderr="loaded\n")
        with patch("builtins.input", return_value="yes"), \
             patch("wassos_transport.subprocess.run", side_effect=[switch, check]) as run, \
             contextlib.redirect_stdout(io.StringIO()) as output:
            self.assertEqual(main(), 0)
        self.assertEqual(run.call_args_list[0].args[0], ["nh", "os", "switch"])
        self.assertEqual(run.call_args_list[1].args[0], ["direnv", "export", "json"])
        self.assertNotIn("DIRENV_DIFF", run.call_args_list[1].kwargs["env"])
        self.assertNotIn("SECRET=private", output.getvalue())

    def test_failed_switch_does_not_run_direnv(self):
        with patch("builtins.input", return_value="yes"), \
             patch("wassos_transport.subprocess.run", return_value=subprocess.CompletedProcess([], 1)) as run, \
             contextlib.redirect_stdout(io.StringIO()), \
             contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(main(), 1)
        self.assertEqual(run.call_count, 1)


if __name__ == "__main__":
    unittest.main()
