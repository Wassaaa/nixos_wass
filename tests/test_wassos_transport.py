import contextlib
import io
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from wassos_transport import main


class TransportTests(unittest.TestCase):
    def test_reproduces_failure_without_printing_environment(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            script = home / ".config" / "direnv" / "lib" / "hm-nix-direnv.sh"
            script.parent.mkdir(parents=True)
            script.write_text('_nix_direnv_preflight() {\n  echo preflight\n}\n')
            result = subprocess.CompletedProcess(
                [], 1, stdout="SECRET=private", stderr="--no-warn-dirty: command not found\n"
            )
            with patch("wassos_transport.Path.home", return_value=home), \
                 patch("builtins.input", return_value="yes"), \
                 patch("wassos_transport.subprocess.run", return_value=result) as run, \
                 contextlib.redirect_stdout(io.StringIO()) as output:
                self.assertEqual(main(), 1)
            self.assertIn("Reproduced the reported", output.getvalue())
            self.assertNotIn("SECRET=private", output.getvalue())
            self.assertEqual(run.call_args.args[0], ["direnv", "export", "json"])
            self.assertNotIn("DIRENV_DIFF", run.call_args.kwargs["env"])
            self.assertIn("BASH_ENV", run.call_args.kwargs["env"])
            self.assertIn("trace did not run", output.getvalue())

    def test_declining_does_not_run_diagnostic(self):
        with patch("builtins.input", return_value="no"), \
             patch("wassos_transport.subprocess.run") as run, \
             contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(main(), 1)
        run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
