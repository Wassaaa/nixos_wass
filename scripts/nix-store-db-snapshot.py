#!/usr/bin/env python3
from contextlib import closing
import os
from pathlib import Path
import sqlite3
import sys
import tempfile


def snapshot(source: Path, backup_dir: Path) -> bool:
    backup_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
    if not backup_dir.is_dir() or backup_dir.is_symlink():
        raise RuntimeError(f"Backup destination is not a directory: {backup_dir}")
    info = backup_dir.stat()
    if info.st_uid != os.geteuid() or info.st_mode & 0o077:
        raise RuntimeError(f"Backup directory must be owned by the current user and private: {backup_dir}")

    fd, name = tempfile.mkstemp(prefix="nix-db-", suffix=".sqlite", dir=backup_dir)
    os.close(fd)
    backup = Path(name)
    print(f"Backup file: {backup}", flush=True)
    print("If the backup fails, this file may be incomplete; retain it for inspection.", flush=True)

    with closing(sqlite3.connect(f"{source.as_uri()}?mode=ro", uri=True, timeout=5)) as live:
        with closing(sqlite3.connect(f"{backup.as_uri()}?mode=rw", uri=True, timeout=5)) as copy:
            live.backup(copy)
            print("Online backup completed; checking the backup, not the live database.", flush=True)
            results = [row[0] for row in copy.execute("PRAGMA integrity_check(20)")]

    for result in results:
        print(result)
    return results == ["ok"]


def main() -> int:
    if os.geteuid() != 0:
        print("Run this script with sudo to create a private root-owned backup.", file=sys.stderr)
        return 1
    try:
        ok = snapshot(Path("/nix/var/nix/db/db.sqlite"), Path("/root/nix-store-db-backups"))
    except (OSError, sqlite3.Error, RuntimeError) as error:
        print(f"Backup or integrity check failed: {error}", file=sys.stderr)
        return 1
    if not ok:
        print("The backup failed SQLite's integrity check; the live database was not repaired.", file=sys.stderr)
        return 1
    print("The backup passed SQLite's integrity check; this does not verify Nix store consistency.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
