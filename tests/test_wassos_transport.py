import contextlib
import io
from pathlib import Path
import tempfile
import unittest
from unittest import mock

from wassos_transport import main, print_environment, qpwgraph_environments


class ThemeDiagnosticTests(unittest.TestCase):
    def test_reads_only_qpwgraph_and_allowed_environment_values(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            process = root / "123"
            process.mkdir()
            (process / "comm").write_text("qpwgraph\n")
            (process / "environ").write_bytes(
                b"QT_QPA_PLATFORMTHEME=qtengine\0SECRET=do-not-print\0"
            )
            other = root / "456"
            other.mkdir()
            (other / "comm").write_text("other\n")
            (other / "environ").write_bytes(b"QT_STYLE_OVERRIDE=unrelated\0")

            result = list(qpwgraph_environments(root, process.stat().st_uid))

        self.assertEqual(result, [("123", {"QT_QPA_PLATFORMTHEME": "qtengine"})])
        with contextlib.redirect_stdout(io.StringIO()) as output:
            print_environment("qpwgraph PID 123", result[0][1])
        self.assertIn("QT_QPA_PLATFORMTHEME=qtengine", output.getvalue())
        self.assertNotIn("do-not-print", output.getvalue())

    def test_skips_vanished_or_inaccessible_processes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "123").mkdir()
            self.assertEqual(list(qpwgraph_environments(root, (root / "123").stat().st_uid)), [])

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