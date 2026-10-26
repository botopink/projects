#!/usr/bin/env bun
/*
Split the milestone's decisions-taken-steps.md into one generated file per repository (decision 482).

Reads specs/decisions-taken-steps.md (the row-per-decision record, decision 730) and, for every table row, maps its Binds column
to repositories: a front number (144 botopink-lang ... 162, rakun), or an old id resolved through the
alias tables at the top of each front README (old id -> the front that holds it now). Writes
repository/<repo>/decisions-taken.md: the generated-from line, then every section that has rows,
each with the table header and the rows binding that repository, verbatim, in the source's order.
The rows carry the ledger's fifth column `Cell` (decision 647), the slug of the row's decision cell; two rows
with one slug are refused (exit 1, in both modes).

  scripts/decisions-split.ts           write the files
  scripts/decisions-split.ts --check   exit 1 when a file differs from what would be written

A row that maps to no repository stays in the meta repository only; those that name no process-only
target are listed on stderr with their Binds text (never guessed), and are not a failure.
*/
import { existsSync, mkdtempSync, realpathSync, rmSync, unlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname } from "node:path";
import {
  argv, cmpKey, die, err, exists, glob, isDir, iterdir, out, pjoin, pname, pparent, re, readText, relativeTo, rsplit, run,
  rstrip, sortPaths, sortStr, spawn, splitlines, strip, toInt,
} from "./lib/compat.ts";

const ROOT = pparent(dirname(realpathSync(import.meta.path)));

/** The specs, laid out as `specs/`: $SPECS_ROOT (CI checks out botopink/specs-data), a local specs/ (before the
 *  cutover), else what `specs-bot export ledger` writes — the record and the current milestone's READMEs. */
function specsRoot(): string {
  if (process.env.SPECS_ROOT) return pjoin(process.env.SPECS_ROOT);
  if (isDir(pjoin(ROOT, "specs"))) return pjoin(ROOT, "specs");
  const tmp = mkdtempSync(pjoin(tmpdir(), "decisions-split-"));
  process.once("exit", () => rmSync(tmp, { recursive: true, force: true }));
  const r = spawn(["specs-bot", "export", "ledger", "--to", tmp]);
  if (r.code !== 0) die(`decisions-split: the specs are not in this checkout and specs-bot could not export them:\n${strip(r.stderr)}`);
  return tmp;
}

export const FRONT_REPO: Record<number, string> = {
  144: "botopink-lang", 145: "query", 146: "validation", 147: "css", 148: "rakun",
  149: "rakun", 150: "rakun", 151: "json", 152: "yaml", 153: "rakun", 154: "rakun",
  155: "http", 156: "log", 157: "routing", 158: "markdown", 159: "actions", 160: "snap",
  161: "vscode-extension", 162: "rakun", 165: "rakun",
};
// Front 165 (the rakun workspace, machine-1/165-rakun-workspace) maps to `rakun`; it joined rakun, styled, jhonstart, emilia, onze and dbcontext into the one `rakun` workspace
// (fronts 148, 149, 153, 154, 162 map to it) and renamed erika to `query` (front 145).
// Fronts of the medium tier: process, or a repository the front's README names that is not (yet)
// under repository/ (cardume, i18n, release) -- no file is written for them.
const MEDIUM_FRONTS = new Set([136, 163, 105, 107, 98, 135]);
const isFront = (n: number) => n in FRONT_REPO;
const NEW_FRONTS = new Set([...Object.keys(FRONT_REPO).map(Number), ...MEDIUM_FRONTS]);
const LIB_FRONTS = Object.keys(FRONT_REPO).map(Number).sort((a, b) => a - b).filter((n) => n >= 145);

// Old track directories and what they hold now.
const TRACKS: Record<string, number[]> = {
  "01-compiler": [144], "02-std-and-packaging": [144], "05-jhonstart": [149],
  "04-rakun": [150], "06-emilia": [154], "07-onze": [162],
};
// Repository words in a Binds cell.
const WORDS: Record<string, number> = {
  "rakun": 150, "jhonstart": 149, "onze": 162, "emilia": 154, "onze-cli": 162,
  "styled": 148, "dbcontext": 153, "erika": 145, "query": 145,
  "lib-test-runner": 144, "libs/std": 144, "libs/actions": 159, "std": 144,
};

const SLUG = re("[a-z][a-z0-9]*(?:_[a-z0-9]+)*");
const HEADER = "Generated from botopink/projects · specs/decisions-taken-steps.md — edit there.";
const STEP = (n: string) => `(?:\\s+(?:steps?\\s+|s)(?P<${n}>\\d+[a-z]?(?:(?:\\s*,\\s*|\\s+and\\s+|\\s*[–-]\\s*)s?\\d+[a-z]?)*))?`;

let SPECS = pjoin(ROOT, "specs");

const VERSION_DIR = re("(\\d+)\\.(\\d+)\\.(\\d+)-beta");

function newestMilestone(): string {
  // The flat tree: the milestone's own documents are in specs/milestone/.
  if (exists(pjoin(SPECS, "milestone", "README.md"))) return pjoin(SPECS, "milestone");
  let best: [number[], string] | null = null;
  for (const d of iterdir(SPECS)) {
    const m = VERSION_DIR.fullmatch(pname(d));
    if (m && exists(pjoin(d, "README.md"))) {
      const key = [1, 2, 3].map((i) => toInt(m.group(i)!));
      if (best === null || cmpKey(key, best[0]) > 0) best = [key, d];
    }
  }
  if (best === null) throw new TypeError("'NoneType' object is not subscriptable");
  return best[1];
}

const MILESTONE_FIELD = re("^\\*\\*Milestone:\\*\\* *(\\S+)", "M");

/** A document's milestone: the `milestone:` key of the YAML block at its top (specs-bot, 2026-10-26), or the
 *  `**Milestone:**` line under its title it replaced. */
function milestoneOf(text: string): string | null {
  if (text.startsWith("---\n")) {
    const close = text.indexOf("\n---", 4);
    const block = close < 0 ? "" : text.slice(4, close);
    const m = /^milestone:[ \t]*["']?([^"'\s]+)/m.exec(block);
    if (m) return m[1]!;
  }
  const f = MILESTONE_FIELD.search(text);
  return f ? f.group(1) : null;
}

/** The current milestone's front READMEs: in the flat tree, the fronts whose milestone is the one
 *  milestone/README.md names; before it, <version>/<machine>/<front>/README.md. */
function frontReadmes(ms: string): string[] {
  if (pname(ms) !== "milestone") return sortPaths(glob(ms, "*/*/README.md"));
  const current = milestoneOf(readText(pjoin(ms, "README.md")));
  const found: string[] = [];
  for (const readme of sortPaths(glob(pparent(ms), "*/README.md"))) {
    if (current && milestoneOf(readText(readme)) === current) found.push(readme);
  }
  return found;
}

type ByName = Map<string, [number, string][]>;
type ByNum = Map<string, Set<string>>;

const FRONT_DIR = re("(\\d+)-");
const OLD_NAME = re("(\\d+-[a-z0-9-]+)");
const DIGITS = re("\\d+");

/** old name -> [(front, row text)]; old number (string) -> {names}. */
function loadAliases(ms: string): [ByName, ByNum] {
  const byName: ByName = new Map(), byNum: ByNum = new Map();
  for (const readme of frontReadmes(ms)) {
    const fm = FRONT_DIR.match(pname(pparent(readme)));
    if (!fm) continue;
    const front = toInt(fm.group(1)!);
    let on = false;
    for (const ln of splitlines(readText(readme))) {
      if (ln.startsWith("| Old id")) {
        on = true;
        continue;
      }
      if (on) {
        if (!ln.startsWith("|")) {
          on = false;
          continue;
        }
        if (ln.startsWith("|---")) continue;
        const cell = strip(ln.split("|")[1].replaceAll("`", ""));
        const nm = OLD_NAME.match(cell);
        if (!nm) continue;
        const name = nm.group(1)!;
        (byName.get(name) ?? byName.set(name, []).get(name)!).push([front, cell]);
        const num = DIGITS.match(name)!.group(0)!;
        (byNum.get(num) ?? byNum.set(num, new Set()).get(num)!).add(name);
      }
    }
  }
  return [byName, byNum];
}

const STEP_SPLIT = re("\\s*,\\s*|\\s+and\\s+");
const STEP_RANGE = re("s?(\\d+)[a-z]?\\s*[–-]\\s*s?(\\d+)");
const STEP_ONE = re("s?(\\d+)");

function stepSet(text: string | null): Set<number> {
  const found = new Set<number>();
  if (!text) return found;
  for (const p of STEP_SPLIT.split(text)) {
    let r = STEP_RANGE.match(p);
    if (r) {
      for (let i = toInt(r.group(1)!); i <= toInt(r.group(2)!); i++) found.add(i);
    } else {
      r = STEP_ONE.match(p);
      if (r) found.add(toInt(r.group(1)!));
    }
  }
  return found;
}

const CELL_STEP = re("\\bs(\\d+)");

/** Fronts holding old front `name` (all when no step is named or none matches). */
function resolveOld(name: string, steps: Set<number>, byName: ByName): number[] {
  const holders = byName.get(name) ?? [];
  if (!holders.length) return [];
  if (steps.size) {
    const hit: number[] = [];
    for (const [front, cell] of holders) {
      const m = CELL_STEP.search(cell);
      if (m && steps.has(toInt(m.group(1)!))) hit.push(front);
    }
    if (hit.length) return hit;
  }
  return holders.map(([f]) => f);
}

function resolveNum(num: string, steps: Set<number>, byName: ByName, byNum: ByNum): number[] {
  const found: number[] = [];
  for (const name of sortStr(byNum.get(num) ?? [])) found.push(...resolveOld(name, steps, byName));
  return found;
}

export const PROCESS_MARK = re(
  "^—$|\\bevery front\\b(?! that| writing)|\\bevery track\\b|\\bfronts\\.md\\b|\\bREADME\\.md\\b|\\bstatus\\.md\\b" +
    "|3-medium/(?:163|136|105|107|98|135)\\b|3-medium/\\d+|machine-2/(?:163|107|98)\\b|machine-1/(?:136|105|135)\\b",
);

const TOKEN = re(
  "(?P<newtr>\\b(?:[123]-[a-z][a-z0-9-]*|machine-[12])/(?P<newn>\\d+))" + STEP("ns") + "|" +
    "(?P<oldtr>\\b\\d\\d-[a-z][a-z0-9-]*/(?P<oldn>\\d+(?:-[a-z0-9-]+)?|\\d\\d-[a-z0-9-]+))" + STEP("os") + "|" +
    "(?P<short>\\b\\d\\d/(?P<shortn>\\d+))" + STEP("ss") + "|" +
    "(?P<oldname>\\b\\d\\d-[a-z][a-z0-9-]*)" + STEP("ons") + "|" +
    "(?P<word>\\blibs/std\\b|\\blibs/actions\\b|\\bonze-cli\\b|\\blib-test-runner\\b|\\brakun\\b|\\bjhonstart\\b|\\bonze\\b|\\bemilia\\b|\\bstyled\\b|\\bdbcontext\\b|\\berika\\b|(?<![\\w/-])std\\b)|" +
    "(?P<range>\\b145\\s*…\\s*162\\b)|" +
    "(?P<bare>(?<![\\w-])\\d{2,3}\\b)" + STEP("bs"), // not the number of a step id such as B-146
);

const EVERY_REPOSITORY = re("\\bevery repository\\b");
const EVERY_LIBRARY_FRONT = re("\\bevery library front\\b");
const EVERY_FRONT_LANG = re("\\bevery front that changes botopink-lang\\b|\\bevery step of\\b");
const RAKUN_CTX = re("\\b(rakun|jhonstart|onze|emilia)\\b");
const ALL_DIGITS = re("\\d+");
const OLD_SUB = re("^(\\d+-[a-z0-9]+(?:-[a-z0-9]+)*?)(?:-[a-z0-9-]*)?$");
const BACKENDS = re("\\b0[2-5]\\b(?!-)|\\bbackends?\\b|\\bbackend fronts\\b");

/** Return (list of repositories, process?). */
function mapRow(binds: string, byName: ByName, byNum: ByNum, allRepos: string[]): [string[], boolean] {
  const text = binds.replaceAll("`", "");
  const fronts: number[] = [], repos: string[] = [];
  let process_ = PROCESS_MARK.test(strip(text));
  if (EVERY_REPOSITORY.test(text)) repos.push(...allRepos);
  if (EVERY_LIBRARY_FRONT.test(text)) fronts.push(...LIB_FRONTS);
  if (EVERY_FRONT_LANG.test(text)) fronts.push(144);
  for (const seg of text.split(" · ")) {
    const rakunCtx = RAKUN_CTX.test(seg);
    for (const m of TOKEN.finditer(seg)) {
      const g = m.groups;
      if (g.newtr) {
        const n = toInt(g.newn!);
        if (NEW_FRONTS.has(n)) fronts.push(n);
        else fronts.push(...resolveNum(g.newn!, stepSet(g.ns), byName, byNum));
      } else if (g.oldtr) {
        const sub = g.oldn!;
        const trk = g.oldtr.split("/")[0];
        if (trk === "20-snap" && sub === "135") fronts.push(135);
        else if (ALL_DIGITS.fullmatch(sub)) {
          const got = resolveNum(sub, stepSet(g.os), byName, byNum);
          // an old front the alias tables do not list: its track still names the repository
          fronts.push(...(got.length ? got : (TRACKS[trk] ?? [])));
        } else {
          const name = OLD_SUB.sub("\\1", sub);
          let nm = [...byName.keys()].filter((n) => sub === n || sub.startsWith(n) || n.startsWith(sub));
          const lead = DIGITS.match(sub);
          if (lead && byNum.has(lead.group(0)!) && !nm.length) nm = sortStr(byNum.get(lead.group(0)!)!);
          if (!nm.length) nm = [name];
          for (const n of nm) fronts.push(...resolveOld(n, stepSet(g.os), byName));
          if (!nm.some((n) => byName.has(n)) && sub.startsWith("01-checker")) fronts.push(144);
        }
      } else if (g.short) {
        fronts.push(...resolveNum(g.shortn!, stepSet(g.ss), byName, byNum));
      } else if (g.oldname) {
        const name = g.oldname;
        if (name in TRACKS) fronts.push(...TRACKS[name]);
        else {
          const cands = [...byName.keys()].filter((n) => n === name || n.startsWith(name + "-"));
          for (const n of cands) fronts.push(...resolveOld(n, stepSet(g.ons), byName));
        }
      } else if (g.word) {
        fronts.push(WORDS[g.word]);
      } else if (g.range) {
        fronts.push(...LIB_FRONTS);
      } else if (g.bare) {
        const num = g.bare;
        const n = toInt(num);
        if (NEW_FRONTS.has(n) && n >= 144) fronts.push(n);
        else if ([98, 105, 107, 135, 136].includes(n) && !rakunCtx && !byNum.has(num)) fronts.push(n);
        else if (byNum.has(num) && !(rakunCtx && n < 98)) fronts.push(...resolveNum(num, stepSet(g.bs), byName, byNum));
      }
    }
    // backend fronts 02-05 by their bare numbers
    if (BACKENDS.test(seg) && !rakunCtx) fronts.push(144);
  }
  for (const f of fronts) {
    if (isFront(f) && !repos.includes(FRONT_REPO[f])) repos.push(FRONT_REPO[f]);
    else if (MEDIUM_FRONTS.has(f)) process_ = true;
  }
  const seen = new Set<string>(), found: string[] = [];
  for (const r of repos)
    if (allRepos.includes(r) && !seen.has(r)) {
      seen.add(r);
      found.push(r);
    }
  return [found, process_];
}

const ROW = re("\\| \\d+ \\|");

function main(): number {
  const check = argv().includes("--check");
  SPECS = specsRoot();
  const ms = newestMilestone();
  const src = pjoin(SPECS, "decisions-taken-steps.md");
  const [byName, byNum] = loadAliases(ms);
  const repoValues = new Set(Object.values(FRONT_REPO));
  const allRepos = sortStr(iterdir(pjoin(ROOT, "repository")).filter(isDir).map(pname)).filter((r) => repoValues.has(r));

  type Section = [string, string[], [number, string, string[]][]];
  const sections: Section[] = [];
  let cur: Section | null = null;
  const unmapped: [number, string][] = [], processRows: [number, string][] = [];
  const badRows: string[] = [], slugs = new Map<string, number>();
  for (const ln of splitlines(readText(src))) {
    if (ln.startsWith("## ")) {
      cur = [ln, [], []];
      sections.push(cur);
    } else if (cur !== null && (ln.startsWith("| #") || ln.startsWith("|---"))) {
      cur[1].push(ln);
    } else if (cur !== null && ROW.match(ln)) {
      const num = toInt(ln.split("|")[1]);
      let body = rstrip(ln);
      if (body.endsWith("|")) body = rstrip(body.slice(0, -1));
      // a rule may hold an unescaped `|` inside code: the last two columns are split from the right
      const tail = rsplit(body + " ", " | ", 2);
      if (tail.length !== 3 || tail[2].includes("|") || !body.startsWith(`| ${num} | `)) {
        badRows.push(`decision ${num}: not five columns (# · Id · Rule in force · Binds · Cell)`);
        continue;
      }
      const binds = strip(tail[1]), slug = strip(strip(tail[2]), "`");
      if (slug) {
        if (!SLUG.fullmatch(slug)) badRows.push(`decision ${num}: slug \`${slug}\` is not lowercase_with_underscores`);
        else if (slugs.has(slug)) badRows.push(`decision ${num}: slug \`${slug}\` is already decision ${slugs.get(slug)}'s`);
        else slugs.set(slug, num);
      }
      const [repos, isProcess] = mapRow(binds, byName, byNum, allRepos);
      if (!repos.length) (isProcess ? processRows : unmapped).push([num, binds]);
      cur[2].push([num, ln, repos]);
    }
  }

  const outputs = new Map<string, [string, number]>();
  for (const repo of allRepos) {
    const body: string[] = [];
    let n = 0;
    for (const [heading, hdr, rows] of sections) {
      const mine = rows.filter(([, , rs]) => rs.includes(repo)).map(([, ln]) => ln);
      if (mine.length) {
        body.push(heading, "", ...hdr, ...mine, "");
        n += mine.length;
      }
    }
    if (n) outputs.set(repo, [HEADER + "\n\n" + rstrip(body.join("\n"), "\n") + "\n", n]);
  }

  if (badRows.length) {
    // the record as the meta checkout names it; one outside it ($SPECS_ROOT, CI) as specs-data does
    let where: string;
    try {
      where = relativeTo(src, ROOT);
    } catch {
      where = pjoin("specs", relativeTo(src, SPECS));
    }
    for (const why of badRows) err(`refused: ${where}: ${why}`);
    return 1;
  }

  for (const [num, binds] of unmapped) err(`meta only (no repository mapped): decision ${num}: Binds = ${binds}`);

  if (check) {
    let bad = false;
    for (const repo of allRepos) {
      const f = pjoin(ROOT, "repository", repo, "decisions-taken.md");
      const want = outputs.get(repo)?.[0] ?? null;
      const have = exists(f) ? readText(f) : null;
      if (have !== want) {
        err(`differs: repository/${repo}/decisions-taken.md`);
        bad = true;
      }
    }
    return bad ? 1 : 0;
  }

  for (const repo of allRepos) {
    const f = pjoin(ROOT, "repository", repo, "decisions-taken.md");
    const o = outputs.get(repo);
    if (o) {
      writeFileSync(f, o[0]);
      out(`${repo}: ${o[1]} rows`);
    } else if (existsSync(f)) unlinkSync(f);
  }
  out(`process-only (no repository): ${processRows.length} rows: ` + processRows.map(([n]) => String(n)).join(", "));
  out(`unmapped (stay in the meta repository only): ${unmapped.length} rows`);
  return 0;
}

if (import.meta.main) run(main);
