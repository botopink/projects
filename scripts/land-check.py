#!/usr/bin/env python3
"""land-check.py — the coordinator's check of a branch before it lands (decision 484, front 163 s12).

Usage:
  scripts/land-check.py <repo> <branch> [--base <ref>]

  <repo>    a git checkout: a path, or a name under `repository/` of the meta checkout
  <branch>  the branch (or any commit) to land
  --base    what it lands on (default `origin/feat`)

Prints `land-check: green`, or one line per reason it is red, and exits 1 when red:

  not-fast-forward   the base is not an ancestor of the branch (rebase onto it);
  forbidden-file     a tracked `*.snap.new`, `*.snap.md.new` or `todo.md` at the branch;
  scratch-ref        an added line under `specs/` naming scratch (`scratch-refs.py`'s patterns);
  commit-hash        an added line under `specs/` holding a commit hash;
  pair-differs       an English/Portuguese pair (`decisions-pending.md` / `decisoes-pendentes.md`)
                     changed by the branch whose heading ids or code blocks differ;
  snapshot-targets   a file the branch adds under `snapshot/targets/` (named, for the coordinator
                     to read against decision 458 — a departure never records a defect).

The spec checks run only where the repository has a `specs/` tree (the meta repository).
"""
import argparse
import importlib.util
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
FORBIDDEN = re.compile(r"(^|/)(todo\.md|[^/]*\.snap\.new|[^/]*\.snap\.md\.new)$")
HASH = re.compile(r"\b(?=[0-9a-f]*[0-9])(?=[0-9a-f]*[a-f])[0-9a-f]{7,40}\b")
# English/Portuguese pairs: (English file, Portuguese file) — the pairs AGENTS.md § Conventions names.
PAIRS = [("decisions-pending.md", "decisoes-pendentes.md")]


def git(repo: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(["git", "-C", str(repo), *args], capture_output=True, text=True, check=check)


def scratch_patterns():
    spec = importlib.util.spec_from_file_location("scratch_refs", HERE / "scratch-refs.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.PATTERNS


def resolve_repo(arg: str) -> Path:
    p = Path(arg)
    if not p.exists():
        p = HERE.parent / "repository" / arg
    if not p.exists():
        sys.exit(f"land-check: no repository {arg!r}")
    return p.resolve()


def added_lines(repo: Path, base: str, branch: str, prefix: str):
    """(file, line number, text) of each line the branch adds under `prefix`."""
    out = git(repo, "diff", "--unified=0", "--no-color", f"{base}...{branch}", "--", prefix).stdout
    f, n = None, 0
    for line in out.splitlines():
        if line.startswith("+++ "):
            f = line[6:] if line.startswith("+++ b/") else None
        elif line.startswith("@@"):
            n = int(re.search(r"\+(\d+)", line).group(1)) - 1
        elif f and line.startswith("+"):
            n += 1
            yield f, n, line[1:]


def show(repo: Path, branch: str, path: str):
    r = git(repo, "show", f"{branch}:{path}", check=False)
    return r.stdout if r.returncode == 0 else None


def pair_shape(text: str):
    ids, blocks, cur, fenced = [], [], [], False
    for line in text.splitlines():
        if line.lstrip().startswith("```"):
            if fenced:
                blocks.append("\n".join(cur))
                cur = []
            fenced = not fenced
        elif fenced:
            cur.append(line)
        elif line.startswith("#"):
            m = re.match(r"#+\s+([A-Za-z0-9][A-Za-z0-9.-]*)\s+·", line)
            if m:
                ids.append(m.group(1))
    return ids, blocks


def main() -> int:
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument("repo")
    ap.add_argument("branch")
    ap.add_argument("--base", default="origin/feat")
    a = ap.parse_args()
    repo = resolve_repo(a.repo)
    base, branch = a.base, a.branch
    red: list[str] = []

    for ref in (base, branch):
        if git(repo, "rev-parse", "--verify", "--quiet", f"{ref}^{{commit}}", check=False).returncode:
            sys.exit(f"land-check: {ref!r} is not a commit of {repo}")

    if git(repo, "merge-base", "--is-ancestor", base, branch, check=False).returncode:
        red.append(f"not-fast-forward: {base} is not an ancestor of {branch} — rebase onto {base}")

    for f in git(repo, "ls-tree", "-r", "--name-only", branch).stdout.splitlines():
        if FORBIDDEN.search(f):
            red.append(f"forbidden-file: {f} is tracked")

    changed = git(repo, "diff", "--name-status", "--no-renames", f"{base}...{branch}").stdout.splitlines()
    for row in changed:
        st, _, f = row.partition("\t")
        if st == "A" and "snapshot/targets/" in f:
            red.append(f"snapshot-targets: {f} added — read against decision 458")

    if (repo / "specs").is_dir():
        pats = scratch_patterns()
        for f, n, text in added_lines(repo, base, branch, "specs"):
            if not f.endswith(".md"):
                continue
            for kind, rx in pats:
                if rx.search(text):
                    red.append(f"scratch-ref: {f}:{n}: {kind}")
            if HASH.search(text):
                red.append(f"commit-hash: {f}:{n}: {HASH.search(text).group(0)}")
        touched = {Path(r.partition('\t')[2]) for r in changed}
        dirs = {(p.parent, pair) for p in touched for pair in PAIRS if p.name in pair}
        for d, pair in sorted(dirs):
            en, pt = (show(repo, branch, str(d / n)) for n in pair)
            if en is None or pt is None:
                red.append(f"pair-differs: {d}: only one of {pair[0]} / {pair[1]} exists")
                continue
            (ei, eb), (pi, pb) = pair_shape(en), pair_shape(pt)
            if ei != pi:
                red.append(f"pair-differs: {d}: heading ids differ ({len(ei)} English, {len(pi)} Portuguese)")
            if eb != pb:
                bad = next((i for i, (x, y) in enumerate(zip(eb, pb)) if x != y), min(len(eb), len(pb)))
                red.append(f"pair-differs: {d}: code block {bad + 1} differs ({len(eb)} English, {len(pb)} Portuguese)")

    if red:
        print("\n".join(f"land-check: {r}" for r in red))
        print(f"land-check: red ({len(red)})", file=sys.stderr)
        return 1
    print("land-check: green")
    return 0


if __name__ == "__main__":
    sys.exit(main())
