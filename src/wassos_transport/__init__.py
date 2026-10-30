import os
import subprocess
import sys
import tempfile
from pathlib import Path

TRACE = r"""
set -o functrace
_direnv_diagnostic_trace() {
  local caller="${FUNCNAME[1]:-main}"
  case "$caller" in
    _nix_direnv_preflight|use_flake|_nix) ;;
    *) return ;;
  esac
  local state=empty
  [[ -n "${_nix_direnv_nix:-}" ]] && state=set
  local marker="$caller:$state"
  if [[ "${_direnv_diagnostic_last:-}" != "$marker" ]]; then
    printf '[DEBUG-direnv] %s nix-command=%s\n' "$caller" "$state" >&2
    _direnv_diagnostic_last="$marker"
  fi
}
trap '_direnv_diagnostic_trace' DEBUG
"""


def main() -> int:
    print("Task: trace whether nix-direnv retains its selected Nix executable.")
    print("This reruns the trusted repository .envrc. It may download/build packages")
    print("and update the Nix store and the repository's .direnv cache.")
    print("A temporary Bash trace prints only function names and whether the path is set.")
    print("No exported environment values will be printed.")
    print("Review output for sensitive information before sharing it.")
    if input("Run the diagnostic? Type yes to continue: ").strip().lower() != "yes":
        print("Cancelled; no diagnostic was run.")
        return 1

    script = Path.home() / ".config" / "direnv" / "lib" / "hm-nix-direnv.sh"
    try:
        lines = script.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        print(f"Could not read {script}: {exc}", file=sys.stderr)
        return 1

    if not any(line.strip() == "_nix_direnv_preflight() {" for line in lines):
        print("Could not find nix-direnv's preflight function.", file=sys.stderr)
        return 1

    env = os.environ.copy()
    for name in ("DIRENV_DIR", "DIRENV_WATCHES", "DIRENV_DIFF"):
        env.pop(name, None)
    print("\nRerunning direnv with the trace; exported environment is discarded:")
    with tempfile.TemporaryDirectory(prefix="wassos-direnv-trace-") as directory:
        trace = Path(directory) / "bash-env"
        trace.write_text(TRACE, encoding="utf-8")
        env["BASH_ENV"] = str(trace)
        try:
            result = subprocess.run(
                ["direnv", "export", "json"],
                env=env,
                text=True,
                capture_output=True,
                check=False,
            )
        except OSError as exc:
            print(f"Could not run direnv: {exc}", file=sys.stderr)
            return 1
    if result.stderr:
        print(result.stderr, end="" if result.stderr.endswith("\n") else "\n")
    print(f"direnv exit code: {result.returncode}")
    if "[DEBUG-direnv]" not in result.stderr:
        print("The Bash trace did not run; its observations are unavailable.")
    if "--no-warn-dirty: command not found" in result.stderr:
        print("Reproduced the reported nix-direnv command failure.")
    elif result.returncode:
        print("Direnv failed, but not with the same reported command error.")
    else:
        print("Direnv completed without the reported failure.")
    return int(result.returncode != 0)
