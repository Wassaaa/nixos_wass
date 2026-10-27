#!/usr/bin/env -S uv run --script
from contextlib import closing
from itertools import islice
import os
from pathlib import Path
import sqlite3
import sys
import tempfile


def test_reindex(source: Path, backup_dir: Path) -> bool:
    info = backup_dir.stat()
    if not backup_dir.is_dir() or info.st_uid != os.geteuid() or info.st_mode & 0o077:
        raise RuntimeError(f"Backup directory must be owned by the current user and private: {backup_dir}")

    fd, name = tempfile.mkstemp(prefix="nix-db-reindex-test-", suffix=".sqlite", dir=backup_dir)
    os.close(fd)
    candidate = Path(name)
    print(f"Test copy: {candidate}", flush=True)
    print("The original snapshot and the live Nix database will not be repaired.", flush=True)

    with closing(sqlite3.connect(f"{source.as_uri()}?mode=ro", uri=True, timeout=5)) as original:
        with closing(sqlite3.connect(f"{candidate.as_uri()}?mode=rw", uri=True, timeout=5)) as copy:
            original.backup(copy)
            index = copy.execute(
                "SELECT tbl_name FROM sqlite_master WHERE type = 'index' AND name = ?",
                ("IndexDerivationOutputs",),
            ).fetchone()
            columns = copy.execute('PRAGMA index_info("IndexDerivationOutputs")').fetchall()
            if index != ("DerivationOutputs",) or [row[2] for row in columns] != ["path"]:
                raise RuntimeError("The target index does not match the expected Nix schema.")

            print("Rebuilding IndexDerivationOutputs on the test copy.", flush=True)
            copy.execute("BEGIN IMMEDIATE")
            copy.execute('REINDEX main."IndexDerivationOutputs"')
            copy.commit()

            integrity = [row[0] for row in copy.execute("PRAGMA integrity_check(20)")]
            foreign_keys = list(islice(copy.execute("PRAGMA foreign_key_check"), 21))

    print("Integrity check:")
    for result in integrity:
        print(result)
    print("Foreign-key check:")
    if foreign_keys:
        for result in foreign_keys[:20]:
            print(result)
        if len(foreign_keys) > 20:
            print("More than 20 violations; remaining results omitted.")
    else:
        print("No violations reported.")

    return integrity == ["ok"] and not foreign_keys


def main() -> int:
    if os.geteuid() != 0:
        print("Run this script with sudo to access the private snapshot.", file=sys.stderr)
        return 1
    if len(sys.argv) != 2:
        print("Usage: sudo uv run --script scripts/nix-store-db-test-reindex.py /root/nix-store-db-backups/nix-db-....sqlite", file=sys.stderr)
        return 1
    try:
        backup_dir = Path("/root/nix-store-db-backups").resolve(strict=True)
        source = Path(sys.argv[1]).resolve(strict=True)
        if source.parent != backup_dir or not source.name.startswith("nix-db-") or source.name.startswith("nix-db-reindex-test-") or source.suffix != ".sqlite":
            raise RuntimeError("Select an original snapshot directly inside /root/nix-store-db-backups.")
        ok = test_reindex(source, backup_dir)
    except (OSError, sqlite3.Error, RuntimeError) as error:
        print(f"Test failed: {error}", file=sys.stderr)
        return 1
    if not ok:
        print("The test copy did not pass all checks.", file=sys.stderr)
        return 1
    print("The test copy passed these SQLite checks; Nix store consistency is not established.")
    print("Do not install this copy as the live database.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
