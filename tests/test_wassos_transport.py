import contextlib
import io
import unittest
from unittest import mock

from wassos_transport import main


class DeploymentTests(unittest.TestCase):
    def run_task(self, *, confirmation="apply", host="wassaa", interactive=True, root=True, exit_code=0):
        with (
            mock.patch("sys.argv", ["x"]),
            mock.patch("wassos_transport.sys.platform", "linux"),
            mock.patch("wassos_transport.socket.gethostname", return_value=host),
            mock.patch("wassos_transport.Path.is_file", return_value=root),
            mock.patch("sys.stdin.isatty", return_value=interactive),
            mock.patch("builtins.input", return_value=confirmation),
            mock.patch("wassos_transport.subprocess.run") as rebuild,
            contextlib.redirect_stdout(io.StringIO()),
            contextlib.redirect_stderr(io.StringIO()),
        ):
            rebuild.return_value.returncode = exit_code
            result = main()
        return result, rebuild

    def test_confirmed_deployment(self):
        result, rebuild = self.run_task()
        self.assertEqual(result, 0)
        rebuild.assert_called_once_with(
            ["sudo", "nixos-rebuild", "switch", "--flake", ".#wassaa"],
            check=False,
        )

    def test_cancel_does_not_deploy(self):
        result, rebuild = self.run_task(confirmation="")
        self.assertEqual(result, 0)
        rebuild.assert_not_called()

    def test_rejects_wrong_host_noninteractive_or_wrong_directory(self):
        cases = (
            self.run_task(host="tpad"),
            self.run_task(interactive=False),
            self.run_task(root=False),
        )
        for result, rebuild in cases:
            self.assertEqual(result, 1)
            rebuild.assert_not_called()

    def test_rebuild_failure_is_returned(self):
        result, _ = self.run_task(exit_code=3)
        self.assertEqual(result, 3)


if __name__ == "__main__":
    unittest.main()