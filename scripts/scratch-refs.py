#!/usr/bin/env python3
"""scratch-refs.py — a spec never points at scratch: where a task's work lives
while it is in flight is not where the work is described.

Usage:
  scripts/scratch-refs.py [PATH ...]      (from anywhere in the meta checkout)

Reads every tracked text file under PATH (default: the current milestone's
spec tree, the newest `specs/<version>/`) and prints each line that names a
scratch location, as `file:line: kind: text`. Exit 1 when one is found, 0
when none.

A SCRATCH location is one that disappears when the task ends:
  · tasks-path  — a concrete path under `.tasks/` (a worktree, `patches/`,
                  `analysis/`); the generic `.tasks/<name>` of the worktree
                  workflow is not one;
  · tmp-path    — anything under `/tmp/`, a session scratchpad;
  · task-branch — a concrete task branch, `front/<name>` written as a name
                  (`front/bigint-139`); the generic `front/<NN-name>` is not one;
  · worktree    — a worktree named as where work sits (worktree `bigint-139`).

A spec states what remains to build and what blocks it; a parked patch or a
branch is the coordinator's, never the spec's.
"""
import re
import subprocess
import sys
from pathlib import Path

PATTERNS = [
    ("tasks-path", re.compile(r"\.tasks/(?!<)[A-Za-z0-9._-]+")),
    ("tmp-path", re.compile(r"(?<![A-Za-z0-9_.])/tmp/|scratchpad")),
    # `front/step` is status.md's legend (a front and its step), not a branch.
    ("task-branch", re.compile(r"(?<![A-Za-z0-9_/.-])front/(?!<|step\b)[a-z0-9][a-z0-9._-]*[a-z0-9](?=[`\s,;:)]|$)")),
    ("worktree", re.compile(r"\bworktree `(?!<)[^`]+`")),
]

TEXT_SUFFIXES = {".md", ".txt", ".bp", ".json", ".yml", ".yaml", ".sh", ".py"}


def meta_root() -> Path:
    out = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True)
    return Path(out.stdout.strip())


def default_tree(root: Path) -> Path:
    def key(p: Path):
        return [int(x) if x.isdigit() else x for x in re.split(r"[.-]", p.name)]

    versions = sorted((p for p in (root / "specs").iterdir() if p.is_dir() and p.name[:1].isdigit()), key=key)
    return versions[-1]


def tracked(root: Path, paths: list[Path]) -> list[Path]:
    rel = [str(p.resolve().relative_to(root)) for p in paths]
    out = subprocess.run(["git", "-C", str(root), "ls-files", "-z", "--", *rel], capture_output=True, text=True, check=True)
    return [root / f for f in out.stdout.split("\0") if f and Path(f).suffix in TEXT_SUFFIXES]


def main() -> int:
    root = meta_root()
    paths = [Path(a) for a in sys.argv[1:]] or [default_tree(root)]
    found = 0
    for f in tracked(root, paths):
        try:
            lines = f.read_text(encoding="utf-8").splitlines()
        except UnicodeDecodeError:
            continue
        for n, line in enumerate(lines, 1):
            for kind, rx in PATTERNS:
                m = rx.search(line)
                if not m:
                    continue
                found += 1
                lo = max(0, m.start() - 50)
                snippet = line[lo : m.end() + 50].strip()
                print(f"{f.relative_to(root)}:{n}: {kind}: …{snippet}…")
    if found:
        print(f"scratch-refs: {found} reference(s) to scratch locations", file=sys.stderr)
        return 1
    print("scratch-refs: none", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
