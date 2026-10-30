import contextlib
import io
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from subprocess import CompletedProcess

from wassos_transport import main


class TransportTests(unittest.TestCase):
    def test_reports_relevant_setup_without_dumping_other_lines(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            config = home / ".config" / "direnv"
            (config / "lib").mkdir(parents=True)
            (config / "direnvrc").write_text("source /nix/store/devenv/direnvrc\nSECRET=private\n")
            (config / "lib" / "hm-nix-direnv.sh").write_text(
                '_nix_direnv_nix=""\n_nix() {\n  ${_nix_direnv_nix} --no-warn-dirty\n}\n'
            )
            result = CompletedProcess([], 0, stdout="version\n", stderr="")
            with patch("wassos_transport.Path.home", return_value=home), \
                 patch("wassos_transport.shutil.which", side_effect=lambda name: f"/bin/{name}"), \
                 patch("wassos_transport.subprocess.run", return_value=result), \
                 contextlib.redirect_stdout(io.StringIO()) as output:
                self.assertEqual(main(), 0)
            self.assertIn("_nix_direnv_nix", output.getvalue())
            self.assertIn("--no-warn-dirty", output.getvalue())
            self.assertNotIn("SECRET=private", output.getvalue())

    def test_missing_executable_and_config_are_errors(self):
        with tempfile.TemporaryDirectory() as directory, \
             patch("wassos_transport.Path.home", return_value=Path(directory)), \
             patch("wassos_transport.shutil.which", return_value=None), \
             contextlib.redirect_stdout(io.StringIO()), \
             contextlib.redirect_stderr(io.StringIO()) as errors:
            self.assertEqual(main(), 1)
        self.assertIn("not found on PATH", errors.getvalue())
        self.assertIn("Could not read", errors.getvalue())


if __name__ == "__main__":
    unittest.main()
