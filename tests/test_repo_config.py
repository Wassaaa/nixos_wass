import contextlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

import repo_config


class PublishTests(unittest.TestCase):
    def test_commit_body_is_sent_to_github(self):
        for body in (None, "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"):
            with self.subTest(body=body), tempfile.TemporaryDirectory() as directory:
                index = Path(directory) / "index"
                index.write_bytes(b"index")
                head = "old-commit"
                new_commit = "new-commit"
                current = [head]
                payloads = []

                def git(*args):
                    if args == ("rev-parse", "--show-toplevel"):
                        return str(Path.cwd().resolve())
                    if args == ("symbolic-ref", "--quiet", "--short", "HEAD"):
                        return "main"
                    if args == ("config", "--get", "branch.main.remote"):
                        return "origin"
                    if args == ("config", "--get", "branch.main.merge"):
                        return "refs/heads/main"
                    if args == ("remote", "get-url", "origin"):
                        return "https://github.com/example/repo"
                    if args == ("rev-parse", "HEAD"):
                        return current[0]
                    if args == ("write-tree",) or args == ("rev-parse", f"{new_commit}^{{tree}}"):
                        return "tree"
                    if args == ("rev-parse", "--path-format=absolute", "--git-path", "index"):
                        return str(index)
                    if args == ("status", "--short"):
                        return ""
                    if args == ("rev-parse", f"{new_commit}^"):
                        return head
                    if args == ("reset", "--mixed", new_commit):
                        current[0] = new_commit
                        return ""
                    raise AssertionError(f"Unexpected git command: {args}")

                def run(*args, data=None):
                    if args == ("gh", "auth", "status", "--hostname", "github.com"):
                        return b""
                    if args == ("gh", "api", "--hostname", "github.com", "user", "--jq", ".login"):
                        return b"user"
                    if args == ("git", "ls-files", "-v", "-z"):
                        return b"H file\0"
                    if args == ("git", "diff", "--diff-filter=A", "--name-only", "-z"):
                        return b""
                    if args == ("gh", "api", "--hostname", "github.com", "graphql", "--input", "-"):
                        payloads.append(json.loads(data))
                        return json.dumps({"data": {"createCommitOnBranch": {"commit": {"oid": new_commit}}}}).encode()
                    raise AssertionError(f"Unexpected command: {args}")

                with (
                    mock.patch.object(repo_config, "git", side_effect=git),
                    mock.patch.object(repo_config, "run", side_effect=run),
                    mock.patch.object(repo_config, "fetch_head", side_effect=[head, new_commit]),
                    mock.patch.object(repo_config, "staged_changes", return_value=([{"path": "file", "contents": ""}], [])),
                    contextlib.redirect_stdout(io.StringIO()),
                ):
                    repo_config.publish("Use Vesktop", True, body)

                message = payloads[0]["variables"]["input"]["message"]
                self.assertEqual(message, {"headline": "Use Vesktop", **({"body": body} if body is not None else {})})

    def test_cli_passes_body_to_publisher(self):
        with (
            mock.patch("sys.argv", ["publish", "-m", "Use Vesktop", "--body", "Trailer", "--yes"]),
            mock.patch.object(repo_config, "publish") as publish,
        ):
            self.assertEqual(repo_config.main(), 0)
        publish.assert_called_once_with("Use Vesktop", True, "Trailer")


if __name__ == "__main__":
    unittest.main()
