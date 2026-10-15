#!/usr/bin/env python3
"""Split the milestone's decisions-taken.md into one generated file per repository (decision 482).

Reads specs/<newest milestone>/decisions-taken.md and, for every table row, maps its Binds column
to repositories: a front number (144 botopink-lang ... 162, rakun), or an old id resolved through the
alias tables at the top of each front README (old id -> the front that holds it now). Writes
repository/<repo>/decisions-taken.md: the generated-from line, then every section that has rows,
each with the table header and the rows binding that repository, verbatim, in the source's order.

  scripts/decisions-split.py           write the files
  scripts/decisions-split.py --check   exit 1 when a file differs from what would be written

A row that maps to no repository stays in the meta repository only; those that name no process-only
target are listed on stderr with their Binds text (never guessed), and are not a failure.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

FRONT_REPO = {
    144: "botopink-lang", 145: "query", 146: "validation", 147: "css", 148: "rakun",
    149: "rakun", 150: "rakun", 151: "json", 152: "yaml", 153: "rakun", 154: "rakun",
    155: "http", 156: "log", 157: "routing", 158: "markdown", 159: "actions", 160: "snap",
    161: "vscode-extension", 162: "rakun",
}
# Front 165 joined rakun, styled, jhonstart, emilia, onze and dbcontext into the one `rakun` workspace
# (fronts 148, 149, 153, 154, 162 map to it) and renamed erika to `query` (front 145).
# Fronts of the medium tier: process, or a repository the front's README names that is not (yet)
# under repository/ (cardume, i18n, release) -- no file is written for them.
MEDIUM_FRONTS = {136, 163, 105, 107, 98, 135}
NEW_FRONTS = set(FRONT_REPO) | MEDIUM_FRONTS
LIB_FRONTS = [n for n in sorted(FRONT_REPO) if n >= 145]

# Old track directories and what they hold now.
TRACKS = {
    "01-compiler": [144], "02-std-and-packaging": [144], "05-jhonstart": [149],
    "04-rakun": [150], "06-emilia": [154], "07-onze": [162],
}
# Repository words in a Binds cell.
WORDS = {
    "rakun": 150, "jhonstart": 149, "onze": 162, "emilia": 154, "onze-cli": 162,
    "styled": 148, "dbcontext": 153, "erika": 145, "query": 145,
    "lib-test-runner": 144, "libs/std": 144, "libs/actions": 159, "std": 144,
}

HEADER = "Generated from botopink/projects · specs/{ms}/decisions-taken.md — edit there."
STEP = r"(?:\s+(?:steps?\s+|s)(?P<{n}>\d+[a-z]?(?:(?:\s*,\s*|\s+and\s+|\s*[–-]\s*)s?\d+[a-z]?)*))?"


def newest_milestone():
    best = None
    for d in (ROOT / "specs").iterdir():
        m = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)-beta", d.name)
        if m and (d / "decisions-taken.md").exists():
            key = tuple(int(x) for x in m.groups())
            if best is None or key > best[0]:
                best = (key, d)
    return best[1]


def load_aliases(ms):
    """old name -> [(front, row text)]; old number (string) -> {names}."""
    by_name, by_num = {}, {}
    for readme in sorted(ms.glob("*/*/README.md")):
        fm = re.match(r"(\d+)-", readme.parent.name)
        if not fm:
            continue
        front = int(fm.group(1))
        lines = readme.read_text().splitlines()
        on = False
        for ln in lines:
            if ln.startswith("| Old id"):
                on = True
                continue
            if on:
                if not ln.startswith("|"):
                    on = False
                    continue
                if ln.startswith("|---"):
                    continue
                cell = ln.split("|")[1].replace("`", "").strip()
                nm = re.match(r"(\d+-[a-z0-9-]+)", cell)
                if not nm:
                    continue
                name = nm.group(1)
                by_name.setdefault(name, []).append((front, cell))
                by_num.setdefault(re.match(r"\d+", name).group(0), set()).add(name)
    return by_name, by_num


def step_set(text):
    out = set()
    if not text:
        return out
    parts = re.split(r"\s*,\s*|\s+and\s+", text)
    for p in parts:
        r = re.match(r"s?(\d+)[a-z]?\s*[–-]\s*s?(\d+)", p)
        if r:
            out.update(range(int(r.group(1)), int(r.group(2)) + 1))
        else:
            r = re.match(r"s?(\d+)", p)
            if r:
                out.add(int(r.group(1)))
    return out


def resolve_old(name, steps, by_name):
    """Fronts holding old front `name` (all when no step is named or none matches)."""
    holders = by_name.get(name, [])
    if not holders:
        return []
    if steps:
        hit = []
        for front, cell in holders:
            m = re.search(r"\bs(\d+)", cell)
            if m and int(m.group(1)) in steps:
                hit.append(front)
        if hit:
            return hit
    return [f for f, _ in holders]


def resolve_num(num, steps, by_name, by_num):
    out = []
    for name in sorted(by_num.get(num, [])):
        out += resolve_old(name, steps, by_name)
    return out


PROCESS_MARK = re.compile(
    r"^—$|\bevery front\b(?! that| writing)|\bevery track\b|\bfronts\.md\b|\bREADME\.md\b|\bstatus\.md\b"
    r"|3-medium/(?:163|136|105|107|98|135)\b|3-medium/\d+")

TOKEN = re.compile(
    r"(?P<newtr>\b[123]-[a-z][a-z0-9-]*/(?P<newn>\d+))" + STEP.format(n="ns") + r"|"
    r"(?P<oldtr>\b\d\d-[a-z][a-z0-9-]*/(?P<oldn>\d+(?:-[a-z0-9-]+)?|\d\d-[a-z0-9-]+))" + STEP.format(n="os") + r"|"
    r"(?P<short>\b\d\d/(?P<shortn>\d+))" + STEP.format(n="ss") + r"|"
    r"(?P<oldname>\b\d\d-[a-z][a-z0-9-]*)" + STEP.format(n="ons") + r"|"
    r"(?P<word>\blibs/std\b|\blibs/actions\b|\bonze-cli\b|\blib-test-runner\b|\brakun\b|\bjhonstart\b|\bonze\b|\bemilia\b|\bstyled\b|\bdbcontext\b|\berika\b|(?<![\w/-])std\b)|"
    r"(?P<range>\b145\s*…\s*162\b)|"
    r"(?P<bare>\b\d{2,3}\b)" + STEP.format(n="bs")
)


def map_row(binds, by_name, by_num, all_repos):
    """Return (list of repositories, process?)."""
    text = binds.replace("`", "")
    fronts, repos = [], []
    process = bool(PROCESS_MARK.search(text.strip()))
    if re.search(r"\bevery repository\b", text):
        repos += all_repos
    if re.search(r"\bevery library front\b", text):
        fronts += LIB_FRONTS
    if re.search(r"\bevery front that changes botopink-lang\b|\bevery step of\b", text):
        fronts.append(144)
    for seg in text.split(" · "):
        rakun_ctx = bool(re.search(r"\b(rakun|jhonstart|onze|emilia)\b", seg))
        for m in TOKEN.finditer(seg):
            k = m.lastgroup
            g = m.groupdict()
            if g["newtr"]:
                n = int(g["newn"])
                if n in NEW_FRONTS:
                    fronts.append(n)
                else:
                    fronts += resolve_num(g["newn"], step_set(g["ns"]), by_name, by_num)
            elif g["oldtr"]:
                sub = g["oldn"]
                trk = g["oldtr"].split("/")[0]
                if trk == "20-snap" and sub == "135":
                    fronts.append(135)
                elif re.fullmatch(r"\d+", sub):
                    got = resolve_num(sub, step_set(g["os"]), by_name, by_num)
                    # an old front the alias tables do not list: its track still names the repository
                    fronts += got or TRACKS.get(trk, [])
                else:
                    name = re.sub(r"^(\d+-[a-z0-9]+(?:-[a-z0-9]+)*?)(?:-[a-z0-9-]*)?$", r"\1", sub)
                    nm = [n for n in by_name if sub == n or sub.startswith(n) or n.startswith(sub)]
                    if re.match(r"\d+", sub) and re.match(r"\d+", sub).group(0) in by_num and not nm:
                        nm = sorted(by_num[re.match(r"\d+", sub).group(0)])
                    if not nm:
                        nm = [name]
                    for n in nm:
                        fronts += resolve_old(n, step_set(g["os"]), by_name)
                    if not any(n in by_name for n in nm) and sub.startswith("01-checker"):
                        fronts.append(144)
            elif g["short"]:
                fronts += resolve_num(g["shortn"], step_set(g["ss"]), by_name, by_num)
            elif g["oldname"]:
                name = g["oldname"]
                if name in TRACKS:
                    fronts += TRACKS[name]
                else:
                    cands = [n for n in by_name if n == name or n.startswith(name + "-")]
                    for n in cands:
                        fronts += resolve_old(n, step_set(g["ons"]), by_name)
            elif g["word"]:
                fronts.append(WORDS[g["word"]])
            elif g["range"]:
                fronts += LIB_FRONTS
            elif g["bare"]:
                num = g["bare"]
                n = int(num)
                if n in NEW_FRONTS and n >= 144:
                    fronts.append(n)
                elif n in (98, 105, 107, 135, 136) and not rakun_ctx and num not in by_num:
                    fronts.append(n)
                elif num in by_num and not (rakun_ctx and n < 98):
                    fronts += resolve_num(num, step_set(g["bs"]), by_name, by_num)
        # backend fronts 02-05 by their bare numbers
        if re.search(r"\b0[2-5]\b(?!-)|\bbackends?\b|\bbackend fronts\b", seg) and not rakun_ctx:
            fronts.append(144)
    for f in fronts:
        if f in FRONT_REPO and FRONT_REPO[f] not in repos:
            repos.append(FRONT_REPO[f])
        elif f in MEDIUM_FRONTS:
            process = True
    seen, out = set(), []
    for r in repos:
        if r in all_repos and r not in seen:
            seen.add(r)
            out.append(r)
    return out, process


def main():
    check = "--check" in sys.argv[1:]
    ms = newest_milestone()
    src = ms / "decisions-taken.md"
    by_name, by_num = load_aliases(ms)
    all_repos = sorted(p.name for p in (ROOT / "repository").iterdir() if p.is_dir())
    all_repos = [r for r in all_repos if r in FRONT_REPO.values()]

    sections = []  # (heading, header_lines, [(num, line, repos)])
    cur = None
    unmapped, process_rows = [], []
    lines = src.read_text().splitlines()
    for i, ln in enumerate(lines):
        if ln.startswith("## "):
            cur = [ln, [], []]
            sections.append(cur)
        elif cur is not None and (ln.startswith("| #") or ln.startswith("|---")):
            cur[1].append(ln)
        elif cur is not None and re.match(r"\| \d+ \|", ln):
            num = int(ln.split("|")[1])
            body = ln.rstrip()
            if body.endswith("|"):
                body = body[:-1].rstrip()
            binds = body.rsplit(" | ", 1)[1]
            repos, process = map_row(binds, by_name, by_num, all_repos)
            if not repos:
                (process_rows if process else unmapped).append((num, binds))
            cur[2].append((num, ln, repos))

    outputs = {}
    for repo in all_repos:
        body = []
        n = 0
        for heading, hdr, rows in sections:
            mine = [ln for _, ln, rs in rows if repo in rs]
            if mine:
                body += [heading, ""] + hdr + mine + [""]
                n += len(mine)
        if n:
            outputs[repo] = (HEADER.format(ms=ms.name) + "\n\n" + "\n".join(body).rstrip("\n") + "\n", n)

    for num, binds in unmapped:
        print(f"meta only (no repository mapped): decision {num}: Binds = {binds}", file=sys.stderr)

    if check:
        bad = False
        for repo in all_repos:
            f = ROOT / "repository" / repo / "decisions-taken.md"
            want = outputs.get(repo, (None, 0))[0]
            have = f.read_text() if f.exists() else None
            if have != want:
                print(f"differs: repository/{repo}/decisions-taken.md", file=sys.stderr)
                bad = True
        sys.exit(1 if bad else 0)

    for repo in all_repos:
        f = ROOT / "repository" / repo / "decisions-taken.md"
        if repo in outputs:
            f.write_text(outputs[repo][0])
            print(f"{repo}: {outputs[repo][1]} rows")
        elif f.exists():
            f.unlink()
    print(f"process-only (no repository): {len(process_rows)} rows: "
          + ", ".join(str(n) for n, _ in process_rows))
    print(f"unmapped (stay in the meta repository only): {len(unmapped)} rows")
    sys.exit(0)


if __name__ == "__main__":
    main()
