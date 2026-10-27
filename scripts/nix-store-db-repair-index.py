#!/usr/bin/env -S uv run --script
from contextlib import closing
import fcntl
import os
from pathlib import Path
import re
import signal
import sqlite3
import subprocess
import sys
import tempfile


DATABASE = Path("/nix/var/nix/db/db.sqlite")
LOCK = Path("/nix/var/nix/db/big-lock")
BACKUP_DIR = Path("/root/nix-store-db-backups")
UNITS = ("nix-daemon.socket", "nix-daemon.service")
EXPECTED_ERROR = re.compile(r"row [0-9]+ missing from index IndexDerivationOutputs")


def systemctl(*args: str) -> None:
    subprocess.run(["systemctl", *args], check=True)


def require_unit_state(expected: str) -> None:
    for unit in UNITS:
        state = subprocess.run(
            ["systemctl", "show", unit, "--property=ActiveState", "--value"],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
        ).stdout.strip()
        if state != expected:
            raise RuntimeError(f"{unit} is {state!r}, not {expected!r}; refusing to proceed.")


def backup(live: sqlite3.Connection) -> Path:
    BACKUP_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
    if BACKUP_DIR.is_symlink() or not BACKUP_DIR.is_dir():
        raise RuntimeError("Backup destination is not a private directory.")
    info = BACKUP_DIR.stat()
    if info.st_uid != 0 or info.st_mode & 0o077:
        raise RuntimeError("Backup directory must be owned by root and private.")
    fd, name = tempfile.mkstemp(prefix="nix-db-before-repair-", suffix=".sqlite", dir=BACKUP_DIR)
    os.close(fd)
    target = Path(name)
    print(f"Fresh pre-repair backup: {target}", flush=True)
    with closing(sqlite3.connect(f"{target.as_uri()}?mode=rw", uri=True, timeout=5)) as copy:
        live.backup(copy)
    return target


def repair(live: sqlite3.Connection, version_before_backup: int) -> bool:
    live.execute("BEGIN IMMEDIATE")
    try:
        if live.execute("PRAGMA data_version").fetchone()[0] != version_before_backup:
            raise RuntimeError("Database changed during backup; refusing to repair.")
        index = live.execute(
            "SELECT tbl_name FROM sqlite_master WHERE type = 'index' AND name = ?",
            ("IndexDerivationOutputs",),
        ).fetchone()
        columns = live.execute('PRAGMA index_info("IndexDerivationOutputs")').fetchall()
        indexes = live.execute('PRAGMA index_list("DerivationOutputs")').fetchall()
        matching = [row for row in indexes if row[1] == "IndexDerivationOutputs"]
        if (
            index != ("DerivationOutputs",)
            or [row[2] for row in columns] != ["path"]
            or len(matching) != 1
            or matching[0][2:] != (0, "c", 0)
        ):
            raise RuntimeError("The target index does not match the expected Nix schema.")

        errors = [row[0] for row in live.execute("PRAGMA integrity_check(101)")]
        if errors == ["ok"]:
            live.rollback()
            print("SQLite integrity check is already clean; no repair performed.")
            return False
        if len(errors) >= 101 or not errors or not all(EXPECTED_ERROR.fullmatch(error) for error in errors):
            raise RuntimeError("Unexpected integrity-check result; refusing to repair: " + repr(errors))
        print("Current integrity errors:", *errors, sep="\n", flush=True)
        if next(live.execute("PRAGMA foreign_key_check"), None) is not None:
            raise RuntimeError("Foreign-key violations found before repair; refusing to proceed.")

        live.execute('REINDEX main."IndexDerivationOutputs"')
        after = [row[0] for row in live.execute("PRAGMA integrity_check(101)")]
        if after != ["ok"]:
            raise RuntimeError("Integrity check failed after reindex; rolling back: " + repr(after))
        if next(live.execute("PRAGMA foreign_key_check"), None) is not None:
            raise RuntimeError("Foreign-key check failed after reindex; rolling back.")
        live.commit()
        print("Reindex committed; SQLite integrity and foreign-key checks passed.", flush=True)
        return True
    except (sqlite3.Error, RuntimeError):
        live.rollback()
        raise


def run() -> None:
    require_unit_state("active")
    try:
        print("Stopping Nix daemon socket and service.", flush=True)
        systemctl("stop", *UNITS)
        require_unit_state("inactive")
        with open(LOCK, "rb+") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            print("Acquired Nix store lock.", flush=True)
            with closing(sqlite3.connect(f"{DATABASE.as_uri()}?mode=rw", uri=True, timeout=5)) as live:
                version = live.execute("PRAGMA data_version").fetchone()[0]
                backup(live)
                repair(live, version)
    finally:
        print("Starting Nix daemon socket and service.", flush=True)
        systemctl("start", *UNITS)


def main() -> int:
    if os.geteuid() != 0:
        print("Run this script with sudo.", file=sys.stderr)
        return 1
    if sys.argv[1:] != ["--apply"]:
        print("Usage: sudo uv run --script scripts/nix-store-db-repair-index.py --apply", file=sys.stderr)
        return 1

    def interrupt(_signum: int, _frame: object) -> None:
        raise InterruptedError("Interrupted by SIGTERM")

    signal.signal(signal.SIGTERM, interrupt)
    try:
        run()
    except KeyboardInterrupt:
        print("Interrupted; the Nix daemon restart was attempted.", file=sys.stderr)
        return 130
    except (OSError, sqlite3.Error, RuntimeError, subprocess.CalledProcessError) as error:
        print(f"Repair did not complete successfully: {error}", file=sys.stderr)
        return 1
    print("Nix daemon restarted. SQLite checks do not verify Nix store contents.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
