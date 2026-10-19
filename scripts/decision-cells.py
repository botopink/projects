#!/usr/bin/env python3
"""Decision cells (front 166): one conformance cell per decision in force, in the repository it binds.

Reads the generated ledger repository/<repo>/decisions-taken.md (decisions-split.py, decision 482) and
keeps `conformance/modules/decisions-taken/<slug>-<N>/` for every row that fixes program behaviour, the slug being
the ledger's `Cell` column (decisions 646, 647, 648).

  scripts/decision-cells.py scaffold [--list] [<repo>]   create the missing directories (docs.md + stub
                                                         draft/main.bp); --list prints what it would scaffold
                                                         and the rows it reads as process, writes nothing
  scripts/decision-cells.py compile [--verbose] <repo>   build every draft/ in a scratch cell with
                                                         `botopink cell check`; red on a refusal, the
                                                         first error per target under each FAIL line
                                                         (--verbose: the whole report of each); a draft's
                                                         own draft/botopink.json and draft/deps/<pkg>/
                                                         are its manifest and dependencies (decision 775)
  scripts/decision-cells.py promote <repo>               draft/ -> src/ + botopink.json (s4); draft/botopink.json
                                                         is merged into that manifest, draft/deps/ moves to deps/
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
LINK = re.compile(r"\[[^\]]*\]\(([^()\s]+)\)")  # any Markdown link
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
# A rule that opens `Overtaken by N: …` / `Reversed by N …` only restates the row in force (586, 612, 633–636):
# that row has the cell. `Withdrawn (…)` states no rule at all.
OPENS_SUPERSEDED = re.compile(r"(?:(?:Replaced|Reversed|Overtaken) by \d|Withdrawn\b)")


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
        elif ONE_LINER.fullmatch(flat) or OPENS_SUPERSEDED.match(flat):
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


def first_diagnostics(block):
    """The first diagnostic line under each target header of one failing cell's report: a header is a
    line indented by two spaces (`  <targets>: <what>`), its diagnostics are the deeper lines below it."""
    found, head, taken = [], None, True
    for ln in block:
        if not ln.strip():
            continue
        if re.match(r"  \S", ln):
            if head is not None and not taken:
                found.append(head.strip())  # a header with no detail under it is itself the message
            head, taken = ln, False
        elif head is not None and not taken and not ln.lstrip().startswith(("candidate ", "+ botopink-cell")):
            found.append(f"{head.strip()} -> {ln.strip()}")
            taken = True
    if head is not None and not taken:
        found.append(head.strip())
    return found


def cmd_compile(root, args):
    verbose = "--verbose" in args
    args = [a for a in args if a != "--verbose"]
    if len(args) != 1:
        print("usage: decision-cells.py compile [--verbose] <repo>", file=sys.stderr)
        return 2
    repo = args[0]
    repo_dir = root / "repository" / repo
    binary = find_botopink(root)
    if binary is None:
        print("compile: no botopink binary (repository/botopink-lang/zig-out/bin/botopink of this tree or of the main checkout)",
              file=sys.stderr)
        return 1
    d = cells_dir(root, repo)
    # a draft (<dir>/draft/main.bp) or each case of a cases directory (<dir>/cases/<case>/src/main.bp, decision 765)
    mains = sorted(p for p in d.glob("*/draft/main.bp")) if d.is_dir() else []
    mains += sorted(p for p in d.glob("*/cases/*/src/main.bp")) if d.is_dir() else []
    mains += sorted(p for p in d.glob("*/cells/*/src/main.bp")) if d.is_dir() else []
    if not mains:
        print(f"{repo}: no draft/main.bp or cases/*/src/main.bp to compile")
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
        if m.parent.name == "src":  # cases/<case>/src/main.bp
            c = scratch / package_name(f"{m.parent.parent.parent.parent.name}-{m.parent.parent.name}")
        else:
            c = scratch / package_name(m.parent.parent.name)
        c.mkdir(parents=True)
        manifest = {"name": c.name}
        if m.parent.name == "draft":
            # decision 775: draft/botopink.json is the package's manifest (its "targets" decide which targets run),
            # draft/deps/<pkg>/ its dependencies, beside the manifest as the promoted cell keeps them
            shutil.copytree(m.parent, c / "src", ignore=shutil.ignore_patterns("botopink.json", "deps"))
            if (m.parent / "botopink.json").is_file():
                manifest = {**json.loads((m.parent / "botopink.json").read_text()), "name": c.name}
            if (m.parent / "deps").is_dir():
                shutil.copytree(m.parent / "deps", c / "deps")
        else:
            shutil.copytree(m.parent, c / "src")  # the whole draft/: main.bp and any <other>.bp
        (c / "botopink.json").write_text(json.dumps(manifest, indent=2) + "\n")
    r = subprocess.run([str(binary), "cell", "check", str(scratch.relative_to(repo_dir))],
                       cwd=repo_dir, capture_output=True, text=True)
    out = r.stdout + r.stderr
    red, cur, blocks = [], None, {}
    for ln in out.splitlines():
        m = re.match(r"FAIL (\S+)", ln)
        if m:
            cur = Path(m.group(1)).name
            blocks[cur] = []
            if "a new cell" not in ln:
                red.append((cur, ln))
        elif "+ refused" in ln and cur:
            red.append((cur, ln.strip()))
        if cur and not m:
            if re.match(r"(ok   |cells: )", ln):
                cur = None
            else:
                blocks[cur].append(ln)
    shutil.rmtree(scratch, ignore_errors=True)
    if red:
        for cell, ln in red:
            print(f"compile {repo}: {cell}: {ln}")
            if ln.startswith("FAIL "):
                if verbose:
                    for b in blocks.get(cell, []):
                        print(f"    | {b}")
                else:
                    for b in first_diagnostics(blocks.get(cell, [])):
                        print(f"    {b}")
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
        if not main.is_file() or any((m / x).exists() for x in ("src", "cases", "run", "refused", "cells")):
            continue
        # decisions 765, 779: draft/ -> cells/example/src/, a full cell of its own
        case = m / "cells" / "example"
        case.mkdir(parents=True)
        main.parent.rename(case / "src")  # every file of the draft
        manifest = {"name": package_name(f"{m.name}-example")}
        drafted = case / "src" / "botopink.json"
        if drafted.is_file():  # decision 775: the draft's keys win over the generated defaults, the name stays the cell's
            manifest = {**json.loads(drafted.read_text()), "name": manifest["name"]}
            drafted.unlink()
            if "targets" in manifest:
                allowed = workspace_targets(root, repo)
                manifest["targets"] = [t for t in manifest["targets"] if t in allowed]
                if not manifest["targets"]:
                    del manifest["targets"]
        if (case / "src" / "deps").is_dir():
            (case / "src" / "deps").rename(case / "deps")
        (case / "botopink.json").write_text(json.dumps(manifest) + "\n")
        (case / "snapshot").mkdir()
        docs = m / "docs.md"
        if docs.exists():
            docs.write_text(LINK.sub(promoted_link, docs.read_text()))
        n += 1
    wm = workspace_manifest(root, repo)
    if n and wm:
        add_workspace_glob(wm, "decisions-taken/*/cells/*")
    print(f"promote {repo}: {n} cells")
    return 0


def promoted_link(k):
    """Rewrite one Markdown link into draft/: its file lands in src/, except the manifest and deps/ (decision 775),
    which sit beside src/; a label that spelled the old path spells the new one."""
    label, target = k.group(0)[1:].split("](", 1)
    target = target[:-1]
    if not target.startswith("draft/"):
        return k.group(0)
    rest = target[len("draft/"):]
    new = "cells/example/" + (rest if rest == "botopink.json" or rest.startswith("deps/") else "src/" + rest)
    return f"[{new if label == target else label}]({new})"


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


def check_cases(root, repo, m, n, red, where="cases"):
    """Decision 765: `cases/<case>/` (779: `cells/<case>/`) each a full cell: botopink.json, src/main.bp, snapshot/."""
    found = sorted(c for c in (m / where).iterdir() if c.is_dir())
    if not found:
        red(n, f"{where}/ holds no case")
    for c in found:
        for need, ok in (("botopink.json", (c / "botopink.json").is_file()), ("src/main.bp", (c / "src/main.bp").is_file()),
                         ("snapshot/", (c / "snapshot").is_dir())):
            if not ok:
                red(n, f"case {c.name} has no {need} (decision 765)")
        if (c / "botopink.json").is_file():
            try:
                targets = json.loads((c / "botopink.json").read_text()).get("targets")
            except ValueError:
                red(n, f"case {c.name} botopink.json is not JSON")
                targets = None
            extra = [t for t in targets or [] if t not in workspace_targets(root, repo)]
            if extra:
                red(n, f"case {c.name} botopink.json targets {extra} are not the workspace's")


def check_packages(root, repo, m, n, red):
    """Decision 779: `run/` and `refused/` are packages of cases — botopink.json, src/main.bp,
    src/cases/mod.bp, snapshot/, each `src/cases/<case>/` holding mod.bp —, and `cells/<case>/`
    each a full cell."""
    for kind in ("run", "refused"):
        p = m / kind
        if not p.is_dir():
            continue
        for need in ("botopink.json", "src/main.bp", "src/cases/mod.bp", "snapshot"):
            if not (p / need).exists():
                red(n, f"{kind}/ has no {need} (decision 779)")
        cases_dir = p / "src" / "cases"
        found = sorted(c for c in cases_dir.iterdir() if c.is_dir()) if cases_dir.is_dir() else []
        if not found:
            red(n, f"{kind}/ holds no case (decision 779)")
        for c in found:
            if not (c / "mod.bp").is_file():
                red(n, f"{kind}/ case {c.name} has no mod.bp (decision 779)")
    if (m / "cells").is_dir():
        check_cases(root, repo, m, n, red, "cells")


def check_cell(root, repo, m, row, red):
    n = row.num
    draft, src = (m / phase1_main(False)).is_file(), (m / phase1_main(True)).is_file()
    packed = any((m / x).is_dir() for x in ("run", "refused", "cells"))
    cases = (m / "cases").is_dir() or packed
    if cases and (draft or src):
        red(n, f"holds both cases/ and {phase1_main(draft is False)} (decision 765: a draft or cases, not both)")
        return
    if draft and src:
        red(n, f"holds both {phase1_main(False)} and {phase1_main(True)} (decision 649: one or the other)")
        return
    if not draft and not src and not cases:
        red(n, f"holds neither {phase1_main(False)} nor {phase1_main(True)} nor cases (decisions 649, 765, 779)")
        return
    promoted = src
    program = m / phase1_main(promoted)
    if (m / "cases").is_dir():
        check_cases(root, repo, m, n, red)
    if packed:
        check_packages(root, repo, m, n, red)
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
        for tgt in sorted({t for ln in lines for t in LINK.findall(ln)} - set(includes)):  # decision 765: every link resolves
            path = tgt.split("#")[0]
            if path and not re.match(r"[a-z][a-z0-9+.-]*:", path) and not (m / path).exists():
                red(n, f"docs.md links {tgt}, which does not exist")
        if any(ln.lstrip().startswith("```") for ln in lines):
            red(n, "docs.md contains a fenced code block (code lives in the included file)")
    if cases:
        return
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
