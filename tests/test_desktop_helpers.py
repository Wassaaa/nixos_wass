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

    def test_swappy_copies_edited_output(self):
        mocks = """
swappy() {
  printf '%s\\n' "$@" > "$TEST_ROOT/args"
  printf 'edited-image'
}
wl-copy() { cat > "$TEST_ROOT/clipboard"; }
notify-send() { printf '%s\\n' "$*" >> "$TEST_ROOT/notifications"; }
"""
        result = self.run_script(
            "modules/home/features/desktop/swappy-clipboard.sh", mocks, "-f", "image file.png"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.root / "clipboard").read_bytes(), b"edited-image")
        self.assertEqual(
            (self.root / "args").read_text().splitlines(),
            ["-o", "-", "-f", "image file.png"],
        )

    def test_swappy_does_not_copy_on_editor_failure_or_empty_output(self):
        mocks = """
swappy() { if [ "$TEST_SCENARIO" = failure ]; then return 1; fi; }
wl-copy() { touch "$TEST_ROOT/copied"; }
notify-send() { printf '%s\\n' "$*" >> "$TEST_ROOT/notifications"; }
"""
        for scenario in ("failure", "empty"):
            with self.subTest(scenario=scenario):
                self.env["TEST_SCENARIO"] = scenario
                result = self.run_script(
                    "modules/home/features/desktop/swappy-clipboard.sh", mocks, "-f", "image.png"
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse((self.root / "copied").exists())
                self.assertIn("Screenshot", (self.root / "notifications").read_text())

    def test_swappy_reports_clipboard_failure(self):
        mocks = """
swappy() { printf 'edited-image'; }
wl-copy() { return 1; }
notify-send() { printf '%s\\n' "$*" >> "$TEST_ROOT/notifications"; }
"""
        result = self.run_script(
            "modules/home/features/desktop/swappy-clipboard.sh", mocks, "-f", "image.png"
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Could not copy", (self.root / "notifications").read_text())

class ScreenshotBindingTests(unittest.TestCase):
    def test_frozen_picker_uses_primary_screenshot_shortcut(self):
        binds = (
            ROOT / "modules/home/features/desktop/hyprland/config/binds/applications.lua"
        ).read_text()
        self.assertIn(
            'hl.bind("SUPER + SHIFT + S", hl.dsp.global("caelestia:screenshotFreeze")',
            binds,
        )
        self.assertEqual(binds.count("caelestia:screenshotFreeze"), 1)
        self.assertNotIn("frozen-screenshot", binds)

    def test_ocr_uses_text_shortcut(self):
        binds = (
            ROOT / "modules/home/features/desktop/hyprland/config/binds/applications.lua"
        ).read_text()
        self.assertIn('hl.bind("SUPER + SHIFT + T", exec("wl-ocr")', binds)
        self.assertEqual(binds.count('exec("wl-ocr")'), 1)


if __name__ == "__main__":
    unittest.main()
