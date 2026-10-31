"""Publish staged files: uv run publish -m "message" [--body "body"].

Do not run other Git commands in this checkout while publication is in progress.
"""

import argparse
import base64
import json
from pathlib import Path
import re
import subprocess
import sys


MUTATION = """mutation($input: CreateCommitOnBranchInput!) {
  createCommitOnBranch(input: $input) { commit { oid } }
}"""


def run(*command: str, data: bytes | None = None) -> bytes:
    result = subprocess.run(command, input=data, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode:
        raise RuntimeError(f"{' '.join(command)} failed: {result.stderr.decode('utf-8', 'replace').strip()}")
    return result.stdout


def git(*args: str) -> str:
    return run("git", *args).decode("utf-8").strip()


def repository(url: str) -> str:
    match = re.fullmatch(r"(?:https://github\.com/|git@github\.com:|ssh://git@github\.com/)([^/]+)/([^/]+?)(?:\.git)?/?", url)
    if not match:
        raise RuntimeError("The upstream remote must be a github.com repository URL.")
    return f"{match.group(1)}/{match.group(2)}"


def staged_changes() -> tuple[list[dict[str, str]], list[dict[str, str]]]:
    records = run("git", "diff", "--cached", "--raw", "--find-renames", "-z", "HEAD").split(b"\0")
    additions = []
    deletions = []
    position = 0
    while position < len(records) - 1:
        fields = records[position].decode("ascii").split()
        position += 1
        if len(fields) != 5:
            raise RuntimeError("Unexpected staged change format.")
        old_mode, new_mode, _, _, status = fields
        old_mode = old_mode.removeprefix(":")
        if status not in ("A", "M", "D") or any(
            mode not in ("000000", "100644") for mode in (old_mode, new_mode)
        ):
            raise RuntimeError(f"Unsupported staged change ({status}, {old_mode} -> {new_mode}); no commit created.")
        path = records[position].decode("utf-8")
        position += 1
        if status == "D":
            deletions.append({"path": path})
        else:
            content = run("git", "cat-file", "blob", f":0:{path}")
            additions.append({"path": path, "contents": base64.b64encode(content).decode("ascii")})
    if not additions and not deletions:
        raise RuntimeError("There are no staged changes to publish.")
    return additions, deletions


def fetch_head(remote: str, branch: str) -> str:
    git("fetch", "--no-tags", remote, f"refs/heads/{branch}")
    return git("rev-parse", "FETCH_HEAD")


def publish(message: str, assume_yes: bool, body: str | None = None) -> None:
    root = Path(git("rev-parse", "--show-toplevel"))
    if Path.cwd().resolve() != root.resolve():
        raise RuntimeError("Run this script from the repository root; no commit created.")
    branch = git("symbolic-ref", "--quiet", "--short", "HEAD")
    remote = git("config", "--get", f"branch.{branch}.remote")
    merge = git("config", "--get", f"branch.{branch}.merge")
    if remote == "." or not merge.startswith("refs/heads/"):
        raise RuntimeError("The current branch must track a remote branch.")
    remote_branch = merge.removeprefix("refs/heads/")
    repo = repository(git("remote", "get-url", remote))
    run("gh", "auth", "status", "--hostname", "github.com")
    account = run("gh", "api", "--hostname", "github.com", "user", "--jq", ".login").decode("utf-8").strip()
    head = git("rev-parse", "HEAD")
    if fetch_head(remote, remote_branch) != head:
        raise RuntimeError("The remote branch does not match local HEAD; no commit created.")
    tree = git("write-tree")
    additions, deletions = staged_changes()
    if git("write-tree") != tree or git("rev-parse", "HEAD") != head:
        raise RuntimeError("The branch or index changed while preparing the commit.")
    index_path = Path(git("rev-parse", "--path-format=absolute", "--git-path", "index"))

    print(f"Repository: {repo}; branch: {remote_branch}; account: {account}")
    print(f"Message: {message}")
    if body is not None:
        print(f"Body:\n{body}")
    print("Staged changes:")
    for item in additions:
        print(f"  add/update {item['path']!r}")
    for item in deletions:
        print(f"  delete     {item['path']!r}")
    print("Current worktree status:")
    print(git("status", "--short") or "  clean")
    index_before = index_path.read_bytes()
    entries = run("git", "ls-files", "-v", "-z").split(b"\0")
    if any(entry and not entry.startswith(b"H ") for entry in entries):
        raise RuntimeError("Special index flags are not supported; no commit created.")
    if run("git", "diff", "--diff-filter=A", "--name-only", "-z"):
        raise RuntimeError("Intent-to-add entries are not supported; no commit created.")
    if (git("write-tree") != tree or git("rev-parse", "HEAD") != head
            or index_path.read_bytes() != index_before):
        raise RuntimeError("The branch or index changed while preparing the commit.")
    if not assume_yes and input("Publish this commit to GitHub? Type yes: ").strip() != "yes":
        raise RuntimeError("Cancelled; no commit created.")
    if (git("symbolic-ref", "--quiet", "--short", "HEAD") != branch
            or git("rev-parse", "HEAD") != head or index_path.read_bytes() != index_before):
        raise RuntimeError("The branch or index changed before publication; no commit created.")

    payload = {
        "query": MUTATION,
        "variables": {"input": {
            "branch": {"repositoryNameWithOwner": repo, "branchName": remote_branch},
            "expectedHeadOid": head,
            "message": {"headline": message, **({"body": body} if body is not None else {})},
            "fileChanges": {"additions": additions, "deletions": deletions},
        }},
    }
    try:
        result = json.loads(run("gh", "api", "--hostname", "github.com", "graphql", "--input", "-", data=json.dumps(payload).encode("utf-8")))
        commit = result["data"]["createCommitOnBranch"]["commit"]["oid"]
    except (RuntimeError, ValueError, KeyError, TypeError) as error:
        raise RuntimeError("Publication result is uncertain. Inspect the remote branch before retrying.") from error

    print(f"GitHub created commit {commit}; verifying before updating the local branch.")
    if (fetch_head(remote, remote_branch) != commit
            or git("rev-parse", f"{commit}^") != head
            or git("rev-parse", f"{commit}^{{tree}}") != tree):
        raise RuntimeError(f"Remote verification failed for {commit}; local branch and index were not updated.")
    if (git("symbolic-ref", "--quiet", "--short", "HEAD") != branch
            or git("rev-parse", "HEAD") != head or index_path.read_bytes() != index_before):
        raise RuntimeError(f"Branch or index changed after publishing {commit}; local state was not updated.")
    git("reset", "--mixed", commit)
    if git("rev-parse", "HEAD") != commit or git("write-tree") != tree:
        raise RuntimeError(f"Local verification failed after publishing {commit}; inspect the repository.")
    print(f"Published {commit}. Remaining worktree changes:")
    print(git("status", "--short") or "  none")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("-m", "--message", required=True, help="Single-line commit message")
    parser.add_argument("--body", help="Optional commit message body")
    parser.add_argument("--yes", action="store_true", help="Skip the confirmation prompt")
    args = parser.parse_args()
    if not args.message.strip() or "\n" in args.message or "\r" in args.message:
        parser.error("the commit message must be a non-empty single line")
    try:
        publish(args.message, args.yes, args.body)
    except (RuntimeError, OSError, UnicodeError, EOFError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())