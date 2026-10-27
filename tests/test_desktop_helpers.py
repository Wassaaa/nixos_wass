import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
GIT = shutil.which("git")
GIT_BASH = Path(GIT).resolve().parent.parent / "bin" / "bash.exe" if GIT and os.name == "nt" else None
BASH = os.environ.get("BASH_FOR_TESTS") or (
    str(GIT_BASH) if GIT_BASH and GIT_BASH.exists() else shutil.which("bash")
)


def shell_path(path):
    if os.name != "nt":
        return str(path)
    return subprocess.check_output(
        [BASH, "-c", 'cygpath -u "$1"', "bash", str(path)], text=True
    ).strip()


@unittest.skipUnless(BASH, "Bash is required for desktop helper tests")
class DesktopHelperTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="desktop-helper-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.env = os.environ.copy()
        self.env["TEST_ROOT"] = shell_path(self.root)

    def run_script(self, path, mocks, *args):
        script = "set -euo pipefail\n" + mocks + '\nsource "$1" "${@:2}"'
        return subprocess.run(
            [BASH, "-c", script, "bash", shell_path(ROOT / path), *args],
            env=self.env,
            text=True,
            capture_output=True,
            timeout=10,
        )

    def test_terminal_uses_selected_directory(self):
        directory = self.root / "folder with spaces"
        directory.mkdir()
        mocks = """
xdg-terminal-exec() { pwd > "$TEST_ROOT/working-directory"; }
notify-send() { printf '%s\\n' "$*" >> "$TEST_ROOT/notifications"; }
"""
        result = self.run_script(
            "modules/home/features/desktop/thunar-terminal-here.sh",
            mocks,
            shell_path(directory),
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            (self.root / "working-directory").read_text().strip(),
            shell_path(directory),
        )

    def test_terminal_reports_invalid_directory(self):
        mocks = """
xdg-terminal-exec() { exit 99; }
notify-send() { printf '%s\\n' "$*" >> "$TEST_ROOT/notifications"; }
"""
        result = self.run_script(
            "modules/home/features/desktop/thunar-terminal-here.sh",
            mocks,
            shell_path(self.root / "missing"),
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Cannot access", (self.root / "notifications").read_text())

    def test_terminal_reports_launch_failure(self):
        mocks = """
xdg-terminal-exec() { return 1; }
notify-send() { printf '%s\\n' "$*" >> "$TEST_ROOT/notifications"; }
"""
        result = self.run_script(
            "modules/home/features/desktop/thunar-terminal-here.sh",
            mocks,
            shell_path(self.root),
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("could not be started", (self.root / "notifications").read_text())

    def test_shell_start_guard(self):
        mocks = """
caelestia-shell() {
  case "$TEST_SCENARIO" in
    none) printf 'No running instances' ;;
    empty) printf '[]' ;;
    existing) printf '[{"pid": 42}]' ;;
    invalid) printf '{}' ;;
    error) return 1 ;;
  esac
}
jq() {
  case "$(cat)" in
    '[]') printf '0' ;;
    '[{"pid": 42}]') printf '1' ;;
    *) return 1 ;;
  esac
}
notify-send() { printf '%s\\n' "$*" >> "$TEST_ROOT/notifications"; }
"""
        for scenario, expected in (
            ("none", 0),
            ("empty", 0),
            ("existing", 1),
            ("invalid", 255),
            ("error", 255),
        ):
            with self.subTest(scenario=scenario):
                self.env["TEST_SCENARIO"] = scenario
                result = self.run_script(
                    "modules/home/features/desktop/caelestia-start-check.sh", mocks
                )
                self.assertEqual(result.returncode, expected, result.stderr)

    def screenshot(self, scenario):
        self.env["TEST_SCENARIO"] = scenario
        self.env["XDG_SCREENSHOTS_DIR"] = shell_path(self.root / "screenshots")
        mocks = """
hyprpicker() {
  if [ "$TEST_SCENARIO" = freeze-failure ]; then return 1; fi
  while :; do :; done
}
slurp() {
  if [ "$TEST_SCENARIO" = cancel ]; then return 1; fi
  printf '10,20 100x200'
}
grim() {
  if [ "$TEST_SCENARIO" = capture-failure ]; then return 1; fi
  [ "$1" = -g ] && [ "$2" = '10,20 100x200' ]
  printf 'image-data' > "$3"
}
wl-copy() {
  if [ "$TEST_SCENARIO" = copy-failure ]; then return 1; fi
  cat > "$TEST_ROOT/clipboard"
}
notify-send() { printf '%s\\n' "$*" >> "$TEST_ROOT/notifications"; }
"""
        return self.run_script(
            "modules/home/features/desktop/frozen-screenshot.sh", mocks
        )

    def test_screenshot_saves_and_copies_selected_area(self):
        result = self.screenshot("success")
        self.assertEqual(result.returncode, 0, result.stderr)
        files = list((self.root / "screenshots").glob("*.png"))
        self.assertEqual(len(files), 1)
        self.assertEqual(files[0].read_bytes(), b"image-data")
        self.assertEqual((self.root / "clipboard").read_bytes(), b"image-data")
        self.assertIn("saved and copied", (self.root / "notifications").read_text())

    def test_screenshot_cancellation_does_not_save(self):
        result = self.screenshot("cancel")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.root / "screenshots").exists())

    def test_screenshot_capture_failure_removes_partial_file(self):
        result = self.screenshot("capture-failure")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(list((self.root / "screenshots").glob("*.png")), [])
        self.assertIn("Could not capture", (self.root / "notifications").read_text())

    def test_screenshot_copy_failure_keeps_saved_image(self):
        result = self.screenshot("copy-failure")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(list((self.root / "screenshots").glob("*.png"))), 1)
        self.assertIn("not copied", (self.root / "notifications").read_text())

    def test_screenshot_freeze_failure_does_not_save(self):
        result = self.screenshot("freeze-failure")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.root / "screenshots").exists())
        self.assertIn("Could not freeze", (self.root / "notifications").read_text())


if __name__ == "__main__":
    unittest.main()
