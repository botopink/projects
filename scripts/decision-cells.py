#!/usr/bin/env python3
"""Decision cells (front 166): one conformance cell per decision in force, in the repository it binds.

Reads the generated ledger repository/<repo>/decisions-taken.md (decisions-split.py, decision 482) and
keeps `conformance/modules/decisions-taken/<slug>-<N>/` for every row that fixes program behaviour, the slug being
the ledger's `Cell` column (decisions 646, 647, 648).

  scripts/decision-cells.py scaffold [--list] [<repo>]   create the missing directories (docs.md + stub
                                                         draft/main.bp); --list prints what it would scaffold
                                                         and the rows it reads as process, writes nothing
  scripts/decision-cells.py compile <repo>               build every draft/ in a scratch cell with
                                                         `botopink cell check`; red on a refusal
  scripts/decision-cells.py promote <repo>               draft/ -> src/ + botopink.json (s4)
  scripts/decision-cells.py check                        CI check 7: consistency always, completeness
                                                         for the repositories in COMPLETE_REPOS

A row is classified from the ledger text alone, never guessed: a one-liner (its rule is only
`Replaced by N` / `Reversed by N` / `Overtaken by N`), a process row (`process` in its id column), else
code-bearing. `--root <dir>` points at another meta tree (the tests). Open questions 166-a, 166-b and
166-c are each answered in one function below (decisions 646–650).
"""
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

sys.dont_write_bytecode = True  # importing decisions-split.py must leave no __pycache__ in the tree
ROOT = Path(__file__).resolve().parent.parent

# s4 extends this list, one repository per landing: its completeness (ii) is then checked, no exemption.
COMPLETE_REPOS = []

CELLS = "conformance/modules/decisions-taken"
MANIFESTS = ["conformance/modules/botopink.json", "conformance/botopink.json"]
ALL_TARGETS = ["commonJS", "erlang", "beam", "wasm"]
DASH = "—"


# ── the three open choices, one function each ───────────────────────────────────

def cell_dirname(slug, num):
    """Decision 648: the directory is `<slug>-<N>`, the ledger's slug, a hyphen, the number."""
    return f"{slug}-{num}"


def package_name(dirname):
    """511 holds untouched: the package is named by its directory (a hyphen is legal)."""
    return dirname


def phase1_main(promoted):
    """Decision 649: phase 1 is `<slug>-<N>/draft/main.bp` (no `src/`, no manifest); promoted is `<slug>-<N>/src/main.bp`."""
    return "src/main.bp" if promoted else "draft/main.bp"


def include_line(path):
    """Decision 650 (166-c): code is included by an ordinary Markdown relative link, `[<path>](<path>)`."""
    return f"[{path}]({path})"


INCLUDE = re.compile(r"\[[^\]]*\]\(([^()\s]+\.bp)\)")  # a relative link to a `.bp` file
PLACEHOLDER = re.compile(r"^\{[^{}\s]+\}$")


# ── the ledger ──────────────────────────────────────────────────────────────────

def load_split():
    spec = importlib.util.spec_from_file_location("decisions_split", Path(__file__).resolve().parent / "decisions-split.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


SPLIT = load_split()
REPOS = set(SPLIT.FRONT_REPO.values())  # the repositories a ledger is generated for (decision 482)
SUPERSEDED = re.compile(r"(?:Replaced|Reversed|Overtaken) by\b|\bis (?:overtaken|reversed|replaced) by\b")


ONE_LINER = re.compile(r"(?:Replaced|Reversed|Overtaken) by [\d,\s]*(?:(?:and|with)[\d,\s]*)*\.?")


def strip_parens(text):
    prev = None
    while prev != text:
        prev = text
        text = re.sub(r"\([^()]*\)", "", text)
    return text


def lead_of(rule):
    m = re.match(r"\*\*(.+?)\*\*", rule)
    lead = m.group(1) if m else re.split(r"(?<=[.!?])\s", rule, maxsplit=1)[0][:120]
    return re.sub(r"\s+", " ", lead.replace("\\|", "|")).strip()


class Row:
    def __init__(self, num, rid, rule, binds, slug=None):
        self.num, self.id, self.rule, self.binds, self.slug = num, rid, rule, binds, slug
        self.lead = lead_of(rule)
        flat = re.sub(r"\s+", " ", strip_parens(rule.replace("**", ""))).strip()
        if re.search(r"\bprocess\b", rid, re.I):
            self.kind = "process"
        elif ONE_LINER.fullmatch(flat):
            self.kind = "oneliner"
        else:
            self.kind = "code"

    @property
    def dirname(self):
        return cell_dirname(self.slug, self.num) if self.slug else None

    @property
    def title(self):
        return f"Decision {self.num} {DASH} {self.lead}"


def ledger(root, repo):
    f = root / "repository" / repo / "decisions-taken.md"
    if not f.exists():
        return None
    rows = []
    has_cell = False  # decision 647: a fifth column `Cell`, the slug of the row's decision cell
    for ln in f.read_text().splitlines():
        if ln.startswith("| #"):
            has_cell = [c.strip() for c in ln.strip().strip("|").split("|")][-1] == "Cell"
            continue
        if not re.match(r"\| \d+ \| ", ln):
            continue
        # a rule may hold an unescaped `|` inside code: # and Id from the left, Binds and Cell from the right
        body = ln.rstrip()
        body = body[:-1].rstrip() if body.endswith("|") else body
        num, rid, rest = [c.strip() for c in body[1:].split("|", 2)]
        tail = [c.strip() for c in (rest + " ").rsplit(" | ", 2 if has_cell else 1)]
        rule, binds = tail[0], tail[1]
        slug = (tail[2].strip("`") or None) if has_cell else None
        rows.append(Row(int(num), rid, rule, binds, slug))
    return rows


def repos_with_cells(root):
    base = root / "repository"
    return sorted(p.name for p in base.iterdir() if p.name in REPOS and (p / "conformance").is_dir()) if base.is_dir() else []


def repos_with_ledger(root):
    base = root / "repository"
    return sorted(p.name for p in base.iterdir() if p.name in REPOS and (p / "decisions-taken.md").exists()) if base.is_dir() else []


def cells_dir(root, repo):
    return root / "repository" / repo / CELLS


def docs_text(row, path):
    return f"# {row.title}\n\n{include_line(path)}\n"


def main_text(row):
    return f"//// {row.title}\npub fn main() -> void {{}}\n"


# ── scaffold ────────────────────────────────────────────────────────────────────

def cmd_scaffold(root, args):
    listing = "--list" in args
    args = [a for a in args if a != "--list"]
    repos = args or repos_with_ledger(root)
    mark = SPLIT.PROCESS_MARK
    for repo in repos:
        rows = ledger(root, repo)
        if rows is None:
            print(f"{repo}: no decisions-taken.md", file=sys.stderr)
            return 1
        d = cells_dir(root, repo)
        one = [r for r in rows if r.kind == "oneliner"]
        tagged = [r for r in rows if r.kind == "process"]
        code = [r for r in rows if r.kind == "code"]
        todo = [r for r in code if not (r.slug and (d / r.dirname).exists())]
        cand = [r for r in todo if mark.search(r.binds)]
        sup = [r for r in todo if r not in cand and SUPERSEDED.search(r.rule[:200])]
        print(f"{repo}: {len(rows)} rows, {len(one)} one-liners, {len(tagged)} tagged process, "
              f"{len(todo)} to scaffold, {len(cand)} of them process candidates, "
              f"{len(sup)} of them with a body that opens as superseded, "
              f"{len([r for r in todo if not r.slug])} of them with no slug yet")
        if listing:
            for r in todo:
                if r not in cand and r not in sup:
                    print(f"  scaffold  {r.num}  {r.slug or '(no slug)'}  {r.lead}")
            for r in cand:
                print(f"  candidate {r.num}  Binds = {r.binds}")
            for r in sup:
                print(f"  superseded? {r.num}  {r.lead}")
            continue
        for r in code:
            if not r.slug:
                print(f"  decision {r.num}: no slug in the ledger's Cell column (166 s2), not scaffolded", file=sys.stderr)
                continue
            m = d / r.dirname
            promoted = (m / "src" / "main.bp").exists()
            if not m.exists():
                m.mkdir(parents=True)
                (m / "docs.md").write_text(docs_text(r, phase1_main(False)))
                (m / "draft").mkdir()
                (m / phase1_main(False)).write_text(main_text(r))
                continue
            rewrite_first_line(m / "docs.md", f"# {r.title}")
            rewrite_first_line(m / phase1_main(promoted), f"//// {r.title}")
    return 0


def rewrite_first_line(f, first):
    if not f.exists():
        return
    lines = f.read_text().split("\n")
    if lines[0] != first:
        lines[0] = first
        f.write_text("\n".join(lines))


# ── compile ─────────────────────────────────────────────────────────────────────

def workspace_manifest(root, repo):
    for m in MANIFESTS:
        p = root / "repository" / repo / m
        if p.exists():
            return p
    return None


def find_botopink(root):
    """This tree's compiler, else the main checkout's (a worktree builds none)."""
    rel = "repository/botopink-lang/zig-out/bin/botopink"
    common = subprocess.run(["git", "-C", str(ROOT), "rev-parse", "--path-format=absolute", "--git-common-dir"],
                            capture_output=True, text=True).stdout.strip()
    for base in (root, Path(common).parent if common else ROOT):
        if (base / rel).exists():
            return base / rel
    return None


def cmd_compile(root, args):
    if len(args) != 1:
        print("usage: decision-cells.py compile <repo>", file=sys.stderr)
        return 2
    repo = args[0]
    repo_dir = root / "repository" / repo
    binary = find_botopink(root)
    if binary is None:
        print("compile: no botopink binary (repository/botopink-lang/zig-out/bin/botopink of this tree or of the main checkout)",
              file=sys.stderr)
        return 1
    d = cells_dir(root, repo)
    mains = sorted(p for p in d.glob("*/draft/main.bp")) if d.is_dir() else []
    if not mains:
        print(f"{repo}: no draft/main.bp to compile")
        return 0
    scratch = repo_dir / ".botopinkbuild" / "tmp" / "decision-cells"
    shutil.rmtree(scratch, ignore_errors=True)
    scratch.mkdir(parents=True)
    ws = {"name": "decision-cells", "version": "0.0.1", "workspaces": ["*"]}
    wm = workspace_manifest(root, repo)
    if wm:
        base = json.loads(wm.read_text())
        for k in ("targets", "dependencies"):
            if k in base:
                ws[k] = base[k]
        for dep in ws.get("dependencies", {}).values():
            if isinstance(dep, dict) and "path" in dep and not os.path.isabs(dep["path"]):
                dep["path"] = str((wm.parent / dep["path"]).resolve())
    (scratch / "botopink.json").write_text(json.dumps(ws, indent=2) + "\n")
    for m in mains:
        c = scratch / package_name(m.parent.parent.name)
        c.mkdir(parents=True)
        shutil.copytree(m.parent, c / "src")  # the whole draft/: main.bp and any <other>.bp
        (c / "botopink.json").write_text(json.dumps({"name": c.name}) + "\n")
    r = subprocess.run([str(binary), "cell", "check", str(scratch.relative_to(repo_dir))],
                       cwd=repo_dir, capture_output=True, text=True)
    out = r.stdout + r.stderr
    red, cur = [], None
    for ln in out.splitlines():
        m = re.match(r"FAIL (\S+)", ln)
        if m:
            cur = Path(m.group(1)).name
            if "a new cell" not in ln:
                red.append((cur, ln))
        elif "+ refused" in ln and cur:
            red.append((cur, ln.strip()))
    shutil.rmtree(scratch, ignore_errors=True)
    if red:
        for cell, ln in red:
            print(f"compile {repo}: {cell}: {ln}")
        print("front 166: the example above does not build")
        return 1
    print(f"compile {repo}: {len(mains)} examples build")
    return 0


# ── promote ─────────────────────────────────────────────────────────────────────

def cmd_promote(root, args):
    if len(args) != 1:
        print("usage: decision-cells.py promote <repo>", file=sys.stderr)
        return 2
    repo = args[0]
    d = cells_dir(root, repo)
    n = 0
    for m in sorted(d.iterdir()) if d.is_dir() else []:
        main = m / phase1_main(False)
        if not main.is_file() or (m / "src").exists():
            continue
        main.parent.rename(m / "src")  # draft/ -> src/, every file of it
        (m / "botopink.json").write_text(json.dumps({"name": package_name(m.name)}) + "\n")
        docs = m / "docs.md"
        if docs.exists():
            # every [draft/<file>](draft/<file>) link
            docs.write_text(re.sub(r"\[draft/([^\]]*)\]\(draft/", r"[src/\1](src/", docs.read_text()))
        n += 1
    wm = workspace_manifest(root, repo)
    if n and wm:
        add_workspace_glob(wm, "decisions-taken/*")
    print(f"promote {repo}: {n} cells")
    return 0


def add_workspace_glob(manifest, glob):
    text = manifest.read_text()
    m = re.search(r'("workspaces"\s*:\s*\[)(.*?)(\s*\])', text, re.S)
    if not m or f'"{glob}"' in m.group(2):
        return
    items = m.group(2)
    if "\n" in items:
        indent = re.findall(r"\n(\s*)\"", items)[-1] if re.search(r"\n\s*\"", items) else "    "
        new = items.rstrip() + f',\n{indent}"{glob}"'
    else:
        new = (items.rstrip() + ", " if items.strip() else "") + f'"{glob}"'
    manifest.write_text(text[:m.start(2)] + new + text[m.end(2):])


# ── check (CI check 7) ──────────────────────────────────────────────────────────

def workspace_targets(root, repo):
    wm = workspace_manifest(root, repo)
    if wm:
        t = json.loads(wm.read_text()).get("targets")
        if t:
            return t
    return ALL_TARGETS


def check_repo(root, repo):
    """Reasons, one line each."""
    out = []

    def red(row, why):
        label = f"decision {row}" if isinstance(row, int) else f"directory {row}"
        out.append(f"decision-cells: {repo}: {label}: {why} (front 166)")

    rows = ledger(root, repo)
    by_num = {r.num: r for r in rows or []}
    d = cells_dir(root, repo)
    if d.is_dir():
        for m in sorted(d.iterdir(), key=lambda p: p.name):
            if not m.is_dir():
                continue
            name = m.name
            nm = re.fullmatch(r"(.+)-(\d+)", name)
            row = by_num.get(int(nm.group(2))) if nm else None
            if row is None:
                red(name, "directory name is <slug>-<N> with N naming no row of the repository's decisions-taken.md")
                continue
            if row.slug != nm.group(1):
                red(name, f"directory slug differs from the row's ({row.slug or 'none'})")
                continue
            if row.kind == "oneliner":
                red(row.num, "row is a one-liner (replaced / reversed / overtaken) and has no cell")
                continue
            if row.kind == "process":
                red(row.num, "row is tagged process and has no cell")
                continue
            check_cell(root, repo, m, row, red)
    if repo in COMPLETE_REPOS:
        for r in rows or []:
            if r.kind != "code":
                continue
            if not r.slug:
                red(r.num, "code-bearing row has no slug in the ledger's Cell column")
            elif not (d / r.dirname).is_dir():
                red(r.num, f"code-bearing row has no conformance/modules/decisions-taken/{r.dirname} directory")
    return out


def check_cell(root, repo, m, row, red):
    n = row.num
    draft, src = (m / phase1_main(False)).is_file(), (m / phase1_main(True)).is_file()
    if draft and src:
        red(n, f"holds both {phase1_main(False)} and {phase1_main(True)} (decision 649: one or the other)")
        return
    if not draft and not src:
        red(n, f"holds neither {phase1_main(False)} nor {phase1_main(True)} (decision 649)")
        return
    promoted = src
    program = m / phase1_main(promoted)
    docs = m / "docs.md"
    if not docs.is_file():
        red(n, "no docs.md")
    else:
        lines = docs.read_text().split("\n")
        if lines[0] != f"# {row.title}":
            red(n, "docs.md first line is not the row's")
        includes = [inc for ln in lines for inc in INCLUDE.findall(ln)]
        if not includes:
            red(n, "docs.md has no [path](path) link to its .bp example")
        if any(PLACEHOLDER.match(ln.strip()) for ln in lines):
            red(n, "docs.md holds a {path} placeholder; code is included by a Markdown link (decision 650)")
        for inc in includes:
            if not (m / inc).is_file():
                red(n, f"docs.md links {inc}, which does not exist")
        if any(ln.lstrip().startswith("```") for ln in lines):
            red(n, "docs.md contains a fenced code block (code lives in the included file)")
    if program.is_file():
        first = program.read_text().split("\n")[0]
        if first != f"//// {row.title}":
            red(n, f"{phase1_main(promoted)} header is not the row's")
    if promoted:
        mf = m / "botopink.json"
        if not mf.is_file():
            red(n, "promoted cell has no botopink.json")
        else:
            try:
                targets = json.loads(mf.read_text()).get("targets")
            except ValueError:
                red(n, "botopink.json is not JSON")
                targets = None
            if targets:
                extra = [t for t in targets if t not in workspace_targets(root, repo)]
                if extra:
                    red(n, f"botopink.json targets {extra} are not the workspace's")
    elif (m / "botopink.json").exists() or (m / "src").exists():
        red(n, "phase 1 cell has a manifest or src/ without being promoted")


def cmd_check(root, args):
    bad = []
    for repo in repos_with_cells(root):
        bad += check_repo(root, repo)
    for ln in bad:
        print(ln)
    if not bad:
        print("decision-cells: green")
    return 1 if bad else 0


def main():
    argv = sys.argv[1:]
    root = ROOT
    if "--root" in argv:
        i = argv.index("--root")
        root = Path(argv[i + 1]).resolve()
        del argv[i:i + 2]
    cmds = {"scaffold": cmd_scaffold, "compile": cmd_compile, "promote": cmd_promote, "check": cmd_check}
    if not argv or argv[0] not in cmds:
        print(__doc__, file=sys.stderr)
        return 2
    return cmds[argv[0]](root, argv[1:])


if __name__ == "__main__":
    sys.exit(main())
