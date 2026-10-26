#!/usr/bin/env python3
"""language-gap-markers.py — every `// LANGUAGE GAP` marker names a row of the milestone's
`language-gaps.md`, and the marker index there is exact. (Ported from language-gap-markers.sh.)

Usage:
  scripts/language-gap-markers.py        (from anywhere in the meta checkout)

A MARKER is the literal `// LANGUAGE GAP` in a tracked `.bp` file: the line a library front (or a front's
`examples/`) writes where the language has no spelling and the nearest valid form stands in. Prose that talks
about markers (`*.md`) is not one. The script reads every repository under `repository/` (the paths of
`.gitmodules`) and the meta repository itself.

The specs live in specs-data, behind specs-bot, since the cutover: the milestone's `language-gaps.md` comes
from `$SPECS_ROOT` (a directory laid out as `specs/`, as CI checks it out) or from `specs-bot export
language-gaps`. Index rows whose file is under `specs/` (the spec examples) are specs-bot's to check
(`specs-bot check`, code `gaps-*`); here only their gap names are read. A checkout that still has `specs/`
is read as before: its newest milestone's tree is one more place markers are found.

The file's `## Marker index` table is what a marker is checked against, one row per file that holds a marker:

  | `<path from the meta root>` | <markers in the file> | **<gap row>** · … |

Exit 1, naming each offender, when
  · a file holds a marker and has no index row      (write the gap row, then the index row)
  · an index row's count is not the file's count    (a marker was added or removed: re-read the file)
  · an index row names a gap row the tables no longer hold (the gap closed: delete the marker, then the row)
  · an index row's file holds no marker             (stale: delete the row)
  · a repository under `repository/` is not checked out (nothing was read: `git submodule update --init`)
Exit 0 otherwise, after printing every marker. No flag, variable or list exempts a marker or a file (decision 67).
"""
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

MARK = "// LANGUAGE GAP"


def git(*args: str, cwd: Path) -> subprocess.CompletedProcess:
    return subprocess.run(["git", "-C", str(cwd), *args], capture_output=True, text=True)


def version_key(p: Path):
    return [int(x) if x.isdigit() else x for x in re.split(r"[.-]", p.name)]


def newest_with_gaps(specs: Path) -> Path | None:
    # The flat tree: the milestone's own documents are in specs/milestone/.
    if (specs / "milestone" / "language-gaps.md").is_file():
        return specs / "milestone"
    dirs = sorted((d for d in specs.iterdir() if d.is_dir() and d.name[:1].isdigit()), key=version_key)
    found = [d for d in dirs if (d / "language-gaps.md").is_file()]
    return found[-1] if found else None


def gaps_file(root: Path, tmp: Path) -> tuple[Path, str]:
    """The milestone's language-gaps.md, and where it came from."""
    for specs, source in ((Path(os.environ["SPECS_ROOT"]) if os.environ.get("SPECS_ROOT") else None, "$SPECS_ROOT"), (root / "specs", "specs/")):
        if specs is not None and specs.is_dir():
            ms = newest_with_gaps(specs)
            if ms is None:
                sys.exit(f"language-gap-markers: no milestone/language-gaps.md under {specs}")
            return ms / "language-gaps.md", source
    out = subprocess.run(["specs-bot", "export", "language-gaps", "--to", str(tmp)], capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit(f"language-gap-markers: the specs are not in this checkout and specs-bot could not export them:\n{out.stderr.strip()}")
    ms = newest_with_gaps(tmp)
    if ms is None:
        sys.exit("language-gap-markers: specs-bot exported no language-gaps.md")
    return ms / "language-gaps.md", "specs-bot"


def read_index(gaps: Path):
    rows, titles, has_index, in_index = [], set(), False, False
    for line in gaps.read_text(encoding="utf-8").splitlines():
        if line.startswith("## "):
            in_index = line.startswith("## Marker index")
            has_index = has_index or in_index
            continue
        m = in_index and re.match(r"^\| `([^`]+\.bp)` \| ([^|]*) \| (.*?) \|?$", line)
        if m:
            count = re.sub(r"\D", "", m.group(2))
            rows.append((m.group(1), int(count) if count else None, re.findall(r"\*\*(.+?)\*\*", m.group(3))))
        elif not in_index:
            g = re.match(r"^\| \*\*(.+?)\*\*", line)
            if g:
                titles.add(g.group(1))
    return rows, titles, has_index


def main() -> int:
    root = Path(git("rev-parse", "--show-toplevel", cwd=Path.cwd()).stdout.strip())
    status = 0
    markers: dict[str, list[str]] = {}

    with tempfile.TemporaryDirectory() as tmp:
        gaps, source = gaps_file(root, Path(tmp))
        rows, titles, has_index = read_index(gaps)
        gaps_name = f"{gaps.parent.name}/language-gaps.md ({source})"

    # The meta repository: every tracked `.bp`; a local specs/ (before the cutover) only for its newest milestone.
    excludes = []
    specs = root / "specs"
    local_specs = specs.is_dir()
    if local_specs:
        newest = newest_with_gaps(specs)
        excludes = [f":!specs/{d.name}" for d in specs.iterdir() if d.is_dir() and d != newest]
    out = git("grep", "-n", "-I", "-F", "-e", MARK, "--", "*.bp", *excludes, cwd=root).stdout
    for line in out.splitlines():
        markers.setdefault(line.split(":", 1)[0], []).append(line)

    # Every repository under repository/.
    paths = git("config", "-f", ".gitmodules", "--get-regexp", r"^submodule\..*\.path$", cwd=root).stdout.split()[1::2]
    if not paths:
        print("language-gap-markers: .gitmodules names no repository", file=sys.stderr)
        return 1
    for repo in sorted(paths):
        top = git("rev-parse", "--show-toplevel", cwd=root / repo)
        if top.returncode != 0 or Path(top.stdout.strip()) != root / repo:
            print(f"language-gap-markers: {repo} is not checked out — nothing was read there (git submodule update --init)", file=sys.stderr)
            status = 1
            continue
        for line in git("grep", "-n", "-I", "-F", "-e", MARK, "--", "*.bp", cwd=root / repo).stdout.splitlines():
            markers.setdefault(f"{repo}/{line.split(':', 1)[0]}", []).append(f"{repo}/{line}")

    if not has_index:
        print(f"language-gap-markers: {gaps_name} has no `## Marker index` section", file=sys.stderr)
        status = 1

    total = sum(len(v) for v in markers.values())
    for f in sorted(markers):
        for m in markers[f]:
            print(f"  {m}")

    by_path = {path: (count, named) for path, count, named in rows}
    for f in sorted(markers):
        count = len(markers[f])
        if f not in by_path:
            status = 1
            print(f"language-gap-markers: no row for the {count} marker(s) in {f}:", file=sys.stderr)
            for m in markers[f]:
                print(f"    {m}", file=sys.stderr)
            print(f"    → write the gap's row in {gaps_name}, then the file's row in its `## Marker index`", file=sys.stderr)
            continue
        listed = by_path[f][0]
        if listed != count:
            status = 1
            print(f"language-gap-markers: {f} holds {count} marker(s), its index row says {listed if listed is not None else 'nothing'}:", file=sys.stderr)
            for m in markers[f]:
                print(f"    {m}", file=sys.stderr)
            print(f"    → a marker was added or removed; make the index row of {gaps_name} say what the file holds", file=sys.stderr)

    spec_rows = 0
    for path, _count, named in rows:
        # A spec example's markers are specs-bot's to count once the specs left this checkout.
        is_spec = path.startswith("specs/")
        spec_rows += is_spec
        if not (is_spec and not local_specs) and path not in markers:
            status = 1
            print(f"language-gap-markers: stale index row — {path} holds no marker", file=sys.stderr)
            print(f"    → delete its row in the `## Marker index` of {gaps_name}", file=sys.stderr)
            continue
        if not named:
            status = 1
            print(f"language-gap-markers: the index row of {path} names no gap row (want **<gap>** in its third cell)", file=sys.stderr)
        for gap in named:
            if gap not in titles:
                status = 1
                print(f"language-gap-markers: {path} names the row **{gap}**, which {gaps_name} does not hold:", file=sys.stderr)
                for m in markers.get(path, []):
                    print(f"    {m}", file=sys.stderr)
                print("    → the gap closed: delete the marker; or the row was renamed: name it as the table spells it", file=sys.stderr)

    note = "" if local_specs or not spec_rows else f"; {spec_rows} index row(s) of spec examples are counted by specs-bot check"
    if status:
        print(f"language-gap-markers: FAILED — {total} marker(s) in {len(markers)} file(s) read against {gaps_name}{note}", file=sys.stderr)
        return 1
    print(f"language-gap-markers: {total} marker(s) in {len(markers)} file(s), every one names a row of {gaps_name}{note}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
