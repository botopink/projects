#!/usr/bin/env bun
/*
language-gap-markers.ts — every `// LANGUAGE GAP` marker names a row of the milestone's
`language-gaps.md`, and the marker index there is exact. (Ported from language-gap-markers.sh.)

Usage:
  scripts/language-gap-markers.ts        (from anywhere in the meta checkout)

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
*/
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import {
  cmpKey, die, err, isDigitStart, isDir, isFile, iterdir, out, pjoin, pname, pnorm, pparent, re, readText, run,
  sortStr, spawn, splitWs, splitlines, strip, toInt, versionKey, type Ran,
} from "./lib/compat.ts";

const MARK = "// LANGUAGE GAP";

function git(args: string[], cwd: string): Ran {
  return spawn(["git", "-C", cwd, ...args]);
}

function newestWithGaps(specs: string): string | null {
  // The flat tree: the milestone's own documents are in specs/milestone/.
  if (isFile(pjoin(specs, "milestone", "language-gaps.md"))) return pjoin(specs, "milestone");
  const dirs = iterdir(specs)
    .filter((d) => isDir(d) && isDigitStart(pname(d)))
    .sort((a, b) => cmpKey(versionKey(pname(a)), versionKey(pname(b))));
  const found = dirs.filter((d) => isFile(pjoin(d, "language-gaps.md")));
  return found.length ? found[found.length - 1] : null;
}

/** The milestone's language-gaps.md, and where it came from. */
function gapsFile(root: string, tmp: string): [string, string] {
  const env = process.env.SPECS_ROOT;
  for (const [specs, source] of [[env ? pjoin(env) : null, "$SPECS_ROOT"], [pjoin(root, "specs"), "specs/"]] as const) {
    if (specs !== null && isDir(specs)) {
      const ms = newestWithGaps(specs);
      if (ms === null) die(`language-gap-markers: no milestone/language-gaps.md under ${specs}`);
      return [pjoin(ms, "language-gaps.md"), source];
    }
  }
  const r = spawn(["specs-bot", "export", "language-gaps", "--to", tmp]);
  if (r.code !== 0)
    die(`language-gap-markers: the specs are not in this checkout and specs-bot could not export them:\n${strip(r.stderr)}`);
  const ms = newestWithGaps(tmp);
  if (ms === null) die("language-gap-markers: specs-bot exported no language-gaps.md");
  return [pjoin(ms, "language-gaps.md"), "specs-bot"];
}

const INDEX_ROW = re("^\\| `([^`]+\\.bp)` \\| ([^|]*) \\| (.*?) \\|?$");
const BOLD = re("\\*\\*(.+?)\\*\\*");
const TITLE = re("^\\| \\*\\*(.+?)\\*\\*");
const NOT_DIGIT = re("\\D");

type IndexRow = [string, number | null, string[]];

function readIndex(gaps: string): [IndexRow[], Set<string>, boolean] {
  const rows: IndexRow[] = [], titles = new Set<string>();
  let hasIndex = false, inIndex = false;
  for (const line of splitlines(readText(gaps))) {
    if (line.startsWith("## ")) {
      inIndex = line.startsWith("## Marker index");
      hasIndex = hasIndex || inIndex;
      continue;
    }
    const m = inIndex ? INDEX_ROW.match(line) : null;
    if (m) {
      const count = NOT_DIGIT.sub("", m.group(2)!);
      rows.push([m.group(1)!, count ? toInt(count) : null, BOLD.findall(m.group(3)!)]);
    } else if (!inIndex) {
      const g = TITLE.match(line);
      if (g) titles.add(g.group(1)!);
    }
  }
  return [rows, titles, hasIndex];
}

function main(): number {
  const root = pjoin(strip(git(["rev-parse", "--show-toplevel"], process.cwd()).stdout));
  let status = 0;
  const markers = new Map<string, string[]>();
  const add = (k: string, v: string) => (markers.get(k) ?? markers.set(k, []).get(k)!).push(v);

  const tmp = mkdtempSync(pjoin(tmpdir(), "tmp"));
  const cleanup = () => rmSync(tmp, { recursive: true, force: true });
  process.once("exit", cleanup); // also when gapsFile ends the run
  const [gaps, source] = gapsFile(root, tmp);
  const [rows, titles, hasIndex] = readIndex(gaps);
  const gapsName = `${pname(pparent(gaps))}/language-gaps.md (${source})`;
  cleanup();

  // The meta repository: every tracked `.bp`; a local specs/ (before the cutover) only for its newest milestone.
  let excludes: string[] = [];
  const specs = pjoin(root, "specs");
  const localSpecs = isDir(specs);
  if (localSpecs) {
    const newest = newestWithGaps(specs);
    excludes = iterdir(specs).filter((d) => isDir(d) && d !== newest).map((d) => `:!specs/${pname(d)}`);
  }
  for (const line of splitlines(git(["grep", "-n", "-I", "-F", "-e", MARK, "--", "*.bp", ...excludes], root).stdout))
    add(line.split(":", 1)[0], line);

  // Every repository under repository/.
  const paths = splitWs(git(["config", "-f", ".gitmodules", "--get-regexp", "^submodule\\..*\\.path$"], root).stdout).filter((_, i) => i % 2 === 1);
  if (!paths.length) {
    err("language-gap-markers: .gitmodules names no repository");
    return 1;
  }
  for (const repo of sortStr(paths)) {
    const top = git(["rev-parse", "--show-toplevel"], pjoin(root, repo));
    if (top.code !== 0 || pjoin(strip(top.stdout)) !== pjoin(root, repo)) {
      err(`language-gap-markers: ${repo} is not checked out — nothing was read there (git submodule update --init)`);
      status = 1;
      continue;
    }
    for (const line of splitlines(git(["grep", "-n", "-I", "-F", "-e", MARK, "--", "*.bp"], pjoin(root, repo)).stdout))
      add(`${repo}/${line.split(":", 1)[0]}`, `${repo}/${line}`);
  }

  if (!hasIndex) {
    err(`language-gap-markers: ${gapsName} has no \`## Marker index\` section`);
    status = 1;
  }

  const total = [...markers.values()].reduce((n, v) => n + v.length, 0);
  const files = sortStr(markers.keys());
  for (const f of files) for (const m of markers.get(f)!) out(`  ${m}`);

  const byPath = new Map<string, [number | null, string[]]>();
  for (const [path, count, named] of rows) byPath.set(path, [count, named]);
  for (const f of files) {
    const count = markers.get(f)!.length;
    if (!byPath.has(f)) {
      status = 1;
      err(`language-gap-markers: no row for the ${count} marker(s) in ${f}:`);
      for (const m of markers.get(f)!) err(`    ${m}`);
      err(`    → write the gap's row in ${gapsName}, then the file's row in its \`## Marker index\``);
      continue;
    }
    const listed = byPath.get(f)![0];
    if (listed !== count) {
      status = 1;
      err(`language-gap-markers: ${f} holds ${count} marker(s), its index row says ${listed !== null ? listed : "nothing"}:`);
      for (const m of markers.get(f)!) err(`    ${m}`);
      err(`    → a marker was added or removed; make the index row of ${gapsName} say what the file holds`);
    }
  }

  let specRows = 0;
  for (const [path, , named] of rows) {
    // A spec example's markers are specs-bot's to count once the specs left this checkout.
    const isSpec = path.startsWith("specs/");
    specRows += isSpec ? 1 : 0;
    if (!(isSpec && !localSpecs) && !markers.has(path)) {
      status = 1;
      err(`language-gap-markers: stale index row — ${path} holds no marker`);
      err(`    → delete its row in the \`## Marker index\` of ${gapsName}`);
      continue;
    }
    if (!named.length) {
      status = 1;
      err(`language-gap-markers: the index row of ${path} names no gap row (want **<gap>** in its third cell)`);
    }
    for (const gap of named) {
      if (!titles.has(gap)) {
        status = 1;
        err(`language-gap-markers: ${path} names the row **${gap}**, which ${gapsName} does not hold:`);
        for (const m of markers.get(path) ?? []) err(`    ${m}`);
        err("    → the gap closed: delete the marker; or the row was renamed: name it as the table spells it");
      }
    }
  }

  const note = localSpecs || !specRows ? "" : `; ${specRows} index row(s) of spec examples are counted by specs-bot check`;
  if (status) {
    err(`language-gap-markers: FAILED — ${total} marker(s) in ${markers.size} file(s) read against ${gapsName}${note}`);
    return 1;
  }
  out(`language-gap-markers: ${total} marker(s) in ${markers.size} file(s), every one names a row of ${gapsName}${note}`);
  return 0;
}

if (import.meta.main) run(main);
