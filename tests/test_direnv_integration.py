import os
import re
import shutil
import subprocess
import unittest
from pathlib import Path


MODULE = Path(__file__).resolve().parents[1] / "modules/home/features/core/direnv.nix"
BASH = os.environ.get("BASH") or shutil.which("bash")


@unittest.skipUnless(BASH, "Bash is required for direnv integration tests")
class DirenvIntegrationTests(unittest.TestCase):
    def test_flake_and_devenv_load_their_own_helpers(self):
        module = MODULE.read_text(encoding="utf-8")
        match = re.search(r"stdlib = ''\n(.*?)\n\s*'';", module, re.DOTALL)
        self.assertIsNotNone(match)
        stdlib = match.group(1).replace("${pkgs.devenv}/bin/devenv", "_fake_devenv")
        script = r"""
set -e
_nix_direnv_preflight() { selected_preflight=nix; }
_nix_import_env() { selected_import=nix; }
use_flake() {
  _nix_direnv_preflight
  _nix_import_env
  [[ $selected_preflight == nix && $selected_import == nix ]]
}
_fake_devenv() {
  [[ $1 == direnvrc ]]
  printf '%s\n' \
    '_nix_direnv_preflight() { selected_preflight=devenv; }' \
    '_nix_import_env() { selected_import=devenv; }' \
    'use_devenv() { _nix_direnv_preflight; _nix_import_env; [[ $1 == test && $selected_preflight == devenv && $selected_import == devenv ]]; }'
}
""" + stdlib + r"""
use_flake
use_devenv test
"""
        result = subprocess.run([BASH, "-c", script], text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
