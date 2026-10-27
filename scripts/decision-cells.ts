#!/usr/bin/env bun
/*
Decision cells (front 166): one conformance cell per decision in force, in the repository it binds.

Reads the generated ledger repository/<repo>/decisions-taken.md (decisions-split.ts, decision 482) and
keeps `conformance/modules/decisions-taken/<slug>-<N>/` for every row that fixes program behaviour, the slug being
the ledger's `Cell` column (decisions 646, 647, 648).

  scripts/decision-cells.ts scaffold [--list] [<repo>]   create the missing directories (docs.md + stub
                                                         draft/main.bp); --list prints what it would scaffold
                                                         and the rows it reads as process, writes nothing
  scripts/decision-cells.ts compile [--verbose] <repo>   build every draft/ in a scratch cell with
                                                         `botopink cell check`; red on a refusal, the
                                                         first error per target under each FAIL line
                                                         (--verbose: the whole report of each); a draft's
                                                         own draft/botopink.json and draft/deps/<pkg>/
                                                         are its manifest and dependencies (decision 775)
  scripts/decision-cells.ts promote <repo>               draft/ -> src/ + botopink.json (s4); draft/botopink.json
                                                         is merged into that manifest, draft/deps/ moves to deps/
  scripts/decision-cells.ts check                        CI check 7: consistency always, completeness
                                                         for the repositories in COMPLETE_REPOS

A row is classified from the ledger text alone, never guessed: a one-liner (its rule is only
`Replaced by N` / `Reversed by N` / `Overtaken by N`), a process row (`process` in its id column), else
code-bearing. `--root <dir>` points at another meta tree (the tests). Open questions 166-a, 166-b and
166-c are each answered in one function below (decisions 646–650).
*/
import { copyFileSync, mkdirSync, readdirSync, realpathSync, renameSync, rmSync, statSync, unlinkSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";
import {
  argv, cmpStr, contains, cpSlice, dumps, err, exists, get, isDir, isFile, isObject, item, iter, iterdir, lexists, loads,
  lstrip, out, pjoin, pname, pparent, re, readText, relativeTo, repr, resolve, rsplit, rstrip, run, sortPaths, sortStr, spawn,
  splitlines, strip, toInt, truthy, ValueError, type Json, type JsonObject, type Match,
} from "./lib/compat.ts";
import { FRONT_REPO, PROCESS_MARK } from "./decisions-split.ts";

const USAGE = `Decision cells (front 166): one conformance cell per decision in force, in the repository it binds.

Reads the generated ledger repository/<repo>/decisions-taken.md (decisions-split.ts, decision 482) and
keeps \`conformance/modules/decisions-taken/<slug>-<N>/\` for every row that fixes program behaviour, the slug being
the ledger's \`Cell\` column (decisions 646, 647, 648).

  scripts/decision-cells.ts scaffold [--list] [<repo>]   create the missing directories (docs.md + stub
                                                         draft/main.bp); --list prints what it would scaffold
                                                         and the rows it reads as process, writes nothing
  scripts/decision-cells.ts compile [--verbose] <repo>   build every draft/ in a scratch cell with
                                                         \`botopink cell check\`; red on a refusal, the
                                                         first error per target under each FAIL line
                                                         (--verbose: the whole report of each); a draft's
                                                         own draft/botopink.json and draft/deps/<pkg>/
                                                         are its manifest and dependencies (decision 775)
  scripts/decision-cells.ts promote <repo>               draft/ -> src/ + botopink.json (s4); draft/botopink.json
                                                         is merged into that manifest, draft/deps/ moves to deps/
  scripts/decision-cells.ts check                        CI check 7: consistency always, completeness
                                                         for the repositories in COMPLETE_REPOS

A row is classified from the ledger text alone, never guessed: a one-liner (its rule is only
\`Replaced by N\` / \`Reversed by N\` / \`Overtaken by N\`), a process row (\`process\` in its id column), else
code-bearing. \`--root <dir>\` points at another meta tree (the tests). Open questions 166-a, 166-b and
166-c are each answered in one function below (decisions 646–650).
`;

const ROOT = pparent(dirname(realpathSync(import.meta.path)));

// s4 extends this list, one repository per landing: its completeness (ii) is then checked, no exemption.
export const COMPLETE_REPOS: string[] = [];

const CELLS = "conformance/modules/decisions-taken";
const MANIFESTS = ["conformance/modules/botopink.json", "conformance/botopink.json"];
const ALL_TARGETS: Json[] = ["commonJS", "erlang", "beam", "wasm"];
const DASH = "—";

// ── the three open choices, one function each ───────────────────────────────────

/** Decision 648: the directory is `<slug>-<N>`, the ledger's slug, a hyphen, the number. */
function cellDirname(slug: string, num: number): string {
  return `${slug}-${num}`;
}

/** 511 holds untouched: the package is named by its directory (a hyphen is legal). */
function packageName(dirname: string): string {
  return dirname;
}

/** Decision 649: phase 1 is `<slug>-<N>/draft/main.bp` (no `src/`, no manifest); promoted is `<slug>-<N>/src/main.bp`. */
function phase1Main(promoted: boolean): string {
  return promoted ? "src/main.bp" : "draft/main.bp";
}

/** Decision 650 (166-c): code is included by an ordinary Markdown relative link, `[<path>](<path>)`. */
function includeLine(path: string): string {
  return `[${path}](${path})`;
}

const INCLUDE = re("\\[[^\\]]*\\]\\(([^()\\s]+\\.bp)\\)"); // a relative link to a `.bp` file
const LINK = re("\\[[^\\]]*\\]\\(([^()\\s]+)\\)"); // any Markdown link
const PLACEHOLDER = re("^\\{[^{}\\s]+\\}$");

// ── the ledger ──────────────────────────────────────────────────────────────────

const REPOS = new Set(Object.values(FRONT_REPO)); // the repositories a ledger is generated for (decision 482)
const SUPERSEDED = re("(?:Replaced|Reversed|Overtaken) by\\b|\\bis (?:overtaken|reversed|replaced) by\\b");

const ONE_LINER = re("(?:Replaced|Reversed|Overtaken) by [\\d,\\s]*(?:(?:and|with)[\\d,\\s]*)*\\.?");
// A rule that opens `Overtaken by N: …` / `Reversed by N …` only restates the row in force (586, 612, 633–636):
// that row has the cell. `Withdrawn (…)` states no rule at all.
const OPENS_SUPERSEDED = re("(?:(?:Replaced|Reversed|Overtaken) by \\d|Withdrawn\\b)");

const PARENS = re("\\([^()]*\\)");
const SPACES = re("\\s+");
const BOLD_LEAD = re("\\*\\*(.+?)\\*\\*");
const SENTENCE_END = re("(?<=[.!?])\\s");
// A row's `process` tag, as the record writes it in the id column — `(process)`, `(process, …)`,
// `· process ·`, `; process, …` —, never the word inside the row's own text ("in-process", "its
// process", decision 989).
const PROCESS_ID = re("(?:\\(|·\\s*|;\\s*)process\\b", "I");

function stripParens(text: string): string {
  let prev: string | null = null;
  while (prev !== text) {
    prev = text;
    text = PARENS.sub("", text);
  }
  return text;
}

function leadOf(rule: string): string {
  const m = BOLD_LEAD.match(rule);
  const lead = m ? m.group(1)! : cpSlice(SENTENCE_END.split(rule, 1)[0], 0, 120);
  return strip(SPACES.sub(" ", lead.replaceAll("\\|", "|")));
}

export class Row {
  readonly lead: string;
  readonly kind: "process" | "oneliner" | "code";
  constructor(
    readonly num: number,
    readonly id: string,
    readonly rule: string,
    readonly binds: string,
    readonly slug: string | null = null,
  ) {
    this.lead = leadOf(rule);
    const flat = strip(SPACES.sub(" ", stripParens(rule.replaceAll("**", ""))));
    if (PROCESS_ID.test(id)) this.kind = "process";
    else if (ONE_LINER.fullmatch(flat) || OPENS_SUPERSEDED.match(flat)) this.kind = "oneliner";
    else this.kind = "code";
  }

  /**
   * Decision 1020: a `Cell` value `tests/<name>.sh` names the CLI test script that proves the row; decision 1022 adds
   * `conformance/run.sh --self-test` (its fixtures the proof). Either way the row has no directory.
   */
  get script(): string | null {
    return this.slug && (SCRIPT_CELL.test(this.slug) || this.slug === SELF_TEST_CELL) ? this.slug : null;
  }

  /** The file a script-proven row needs, relative to its repository. */
  get scriptFile(): string | null {
    if (!this.script) return null;
    return this.script === SELF_TEST_CELL ? "conformance/run.sh" : `modules/compiler-cli/${this.script}`;
  }

  get dirname(): string | null {
    return this.slug && !this.script ? cellDirname(this.slug, this.num) : null;
  }

  get title(): string {
    return `Decision ${this.num} ${DASH} ${this.lead}`;
  }
}

const SCRIPT_CELL = re("^tests/[A-Za-z0-9_]+\\.sh$");
const SELF_TEST_CELL = "conformance/run.sh --self-test";
const LEDGER_ROW = re("\\| \\d+ \\| ");

function at<T>(xs: T[], i: number): T {
  if (i >= xs.length) throw new RangeError("list index out of range");
  return xs[i];
}

function ledger(root: string, repo: string): Row[] | null {
  const f = pjoin(root, "repository", repo, "decisions-taken.md");
  if (!exists(f)) return null;
  const rows: Row[] = [];
  let hasCell = false; // decision 647: a fifth column `Cell`, the slug of the row's decision cell
  for (const ln of splitlines(readText(f))) {
    if (ln.startsWith("| #")) {
      const cols = strip(strip(ln), "|").split("|").map((c) => strip(c));
      hasCell = cols[cols.length - 1] === "Cell";
      continue;
    }
    if (!LEDGER_ROW.match(ln)) continue;
    // a rule may hold an unescaped `|` inside code: # and Id from the left, Binds and Cell from the right
    let body = rstrip(ln);
    body = body.endsWith("|") ? rstrip(body.slice(0, -1)) : body;
    const first = splitOnce(body.slice(1), "|").map((c) => strip(c));
    if (first.length !== 2) throw new ValueError("not enough values to unpack");
    const [num] = first;
    let rest = first[1];
    // the Id column may quote a `|` too (791, 802): the rule opens bold, so split there when it does
    const cut = rest.indexOf(" | **");
    let rid: string;
    if (cut >= 0) [rid, rest] = [strip(rest.slice(0, cut)), rest.slice(cut + 3)];
    else {
      const two = splitOnce(rest, "|").map((c) => strip(c));
      if (two.length !== 2) throw new ValueError("not enough values to unpack");
      [rid, rest] = two;
    }
    const tail = rsplit(rest + " ", " | ", hasCell ? 2 : 1).map((c) => strip(c));
    const rule = at(tail, 0), binds = at(tail, 1);
    const slug = hasCell ? strip(at(tail, 2), "`") || null : null;
    rows.push(new Row(toInt(num), rid, rule, binds, slug));
  }
  return rows;
}

function splitOnce(s: string, sep: string): string[] {
  const i = s.indexOf(sep);
  return i < 0 ? [s] : [s.slice(0, i), s.slice(i + sep.length)];
}

function reposWith(root: string, has: (p: string) => boolean): string[] {
  const base = pjoin(root, "repository");
  return isDir(base) ? sortStr(iterdir(base).filter((p) => REPOS.has(pname(p)) && has(p)).map(pname)) : [];
}

const reposWithCells = (root: string) => reposWith(root, (p) => isDir(pjoin(p, "conformance")));
const reposWithLedger = (root: string) => reposWith(root, (p) => exists(pjoin(p, "decisions-taken.md")));

function cellsDir(root: string, repo: string): string {
  return pjoin(root, "repository", repo, CELLS);
}

function docsText(row: Row, path: string): string {
  return `# ${row.title}\n\n${includeLine(path)}\n`;
}

function mainText(row: Row): string {
  return `//// ${row.title}\npub fn main() -> void {}\n`;
}

/** A directory that must not exist yet (and, with `parents`, the ones above it). */
function mkdirNew(p: string, parents = false) {
  if (lexists(p)) throw new Error(`[Errno 17] File exists: '${p}'`);
  mkdirSync(p, { recursive: parents });
}

// ── scaffold ────────────────────────────────────────────────────────────────────

function cmdScaffold(root: string, args: string[]): number {
  const listing = args.includes("--list");
  args = args.filter((a) => a !== "--list");
  const repos = args.length ? args : reposWithLedger(root);
  const mark = PROCESS_MARK;
  for (const repo of repos) {
    const rows = ledger(root, repo);
    if (rows === null) {
      err(`${repo}: no decisions-taken.md`);
      return 1;
    }
    const d = cellsDir(root, repo);
    const one = rows.filter((r) => r.kind === "oneliner");
    const tagged = rows.filter((r) => r.kind === "process");
    const code = rows.filter((r) => r.kind === "code");
    const todo = code.filter((r) => !r.script && !(r.slug && exists(pjoin(d, r.dirname!))));
    const cand = todo.filter((r) => mark.test(r.binds));
    const sup = todo.filter((r) => !cand.includes(r) && SUPERSEDED.test(cpSlice(r.rule, 0, 200)));
    out(`${repo}: ${rows.length} rows, ${one.length} one-liners, ${tagged.length} tagged process, ` +
      `${todo.length} to scaffold, ${cand.length} of them process candidates, ` +
      `${sup.length} of them with a body that opens as superseded, ` +
      `${todo.filter((r) => !r.slug).length} of them with no slug yet`);
    if (listing) {
      for (const r of todo) if (!cand.includes(r) && !sup.includes(r)) out(`  scaffold  ${r.num}  ${r.slug || "(no slug)"}  ${r.lead}`);
      for (const r of cand) out(`  candidate ${r.num}  Binds = ${r.binds}`);
      for (const r of sup) out(`  superseded? ${r.num}  ${r.lead}`);
      continue;
    }
    for (const r of code) {
      if (r.script) continue;
      if (!r.slug) {
        err(`  decision ${r.num}: no slug in the ledger's Cell column (166 s2), not scaffolded`);
        continue;
      }
      const m = pjoin(d, r.dirname!);
      const promoted = exists(pjoin(m, "src", "main.bp"));
      if (!exists(m)) {
        mkdirNew(m, true);
        writeFileSync(pjoin(m, "docs.md"), docsText(r, phase1Main(false)));
        mkdirNew(pjoin(m, "draft"));
        writeFileSync(pjoin(m, phase1Main(false)), mainText(r));
        continue;
      }
      rewriteFirstLine(pjoin(m, "docs.md"), `# ${r.title}`);
      rewriteFirstLine(pjoin(m, phase1Main(promoted)), `//// ${r.title}`);
    }
  }
  return 0;
}

function rewriteFirstLine(f: string, first: string) {
  if (!exists(f)) return;
  const lines = readText(f).split("\n");
  if (lines[0] !== first) {
    lines[0] = first;
    writeFileSync(f, lines.join("\n"));
  }
}

// ── compile ─────────────────────────────────────────────────────────────────────

function workspaceManifest(root: string, repo: string): string | null {
  for (const m of MANIFESTS) {
    const p = pjoin(root, "repository", repo, m);
    if (exists(p)) return p;
  }
  return null;
}

/** This tree's compiler, else the main checkout's (a worktree builds none). */
function findBotopink(root: string): string | null {
  const rel = "repository/botopink-lang/zig-out/bin/botopink";
  const common = strip(spawn(["git", "-C", ROOT, "rev-parse", "--path-format=absolute", "--git-common-dir"]).stdout);
  for (const base of [root, common ? pparent(common) : ROOT]) if (exists(pjoin(base, rel))) return pjoin(base, rel);
  return null;
}

const HEADER_LINE = re("  \\S");

/** The first diagnostic line under each target header of one failing cell's report: a header is a
 *  line indented by two spaces (`  <targets>: <what>`), its diagnostics are the deeper lines below it. */
function firstDiagnostics(block: string[]): string[] {
  const found: string[] = [];
  let head: string | null = null, taken = true;
  for (const ln of block) {
    if (!strip(ln)) continue;
    if (HEADER_LINE.match(ln)) {
      if (head !== null && !taken) found.push(strip(head)); // a header with no detail under it is itself the message
      head = ln;
      taken = false;
    } else if (head !== null && !taken && !["candidate ", "+ botopink-cell"].some((p) => lstrip(ln).startsWith(p))) {
      found.push(`${strip(head)} -> ${strip(ln)}`);
      taken = true;
    }
  }
  if (head !== null && !taken) found.push(strip(head));
  return found;
}

/** A copy of a directory tree; names in `ignore` are left out at every level. */
function copyTree(src: string, dst: string, ignore: string[] = []) {
  mkdirNew(dst, true);
  for (const name of readdirSync(src).map(String)) {
    if (ignore.includes(name)) continue;
    const s = pjoin(src, name), d = pjoin(dst, name);
    if (statSync(s).isDirectory()) copyTree(s, d, ignore);
    else copyFileSync(s, d);
  }
}

const FAIL_LINE = re("FAIL (\\S+)");
const END_LINE = re("(ok   |cells: )");

function cmdCompile(root: string, args: string[]): number {
  const verbose = args.includes("--verbose");
  args = args.filter((a) => a !== "--verbose");
  if (args.length !== 1) {
    err("usage: decision-cells.ts compile [--verbose] <repo>");
    return 2;
  }
  const repo = args[0];
  const repoDir = pjoin(root, "repository", repo);
  const binary = findBotopink(root);
  if (binary === null) {
    err("compile: no botopink binary (repository/botopink-lang/zig-out/bin/botopink of this tree or of the main checkout)");
    return 1;
  }
  const d = cellsDir(root, repo);
  // a draft (<dir>/draft/main.bp) or each case of a cases directory (<dir>/cases/<case>/src/main.bp, decision 765)
  const mains = isDir(d)
    ? [...sortPaths(globIn(d, "*/draft/main.bp")), ...sortPaths(globIn(d, "*/cases/*/src/main.bp")), ...sortPaths(globIn(d, "*/cells/*/src/main.bp"))]
    : [];
  if (!mains.length) {
    out(`${repo}: no draft/main.bp or cases/*/src/main.bp to compile`);
    return 0;
  }
  const scratch = pjoin(repoDir, ".botopinkbuild", "tmp", "decision-cells");
  rmSync(scratch, { recursive: true, force: true });
  mkdirNew(scratch, true);
  const ws: JsonObject = new Map<string, Json>([["name", "decision-cells"], ["version", "0.0.1"], ["workspaces", ["*"]]]);
  const wm = workspaceManifest(root, repo);
  if (wm) {
    const base = loads(readText(wm));
    for (const k of ["targets", "dependencies"]) if (contains(base, k)) ws.set(k, item(base, k));
    const deps = ws.has("dependencies") ? ws.get("dependencies")! : new Map();
    if (!isObject(deps)) throw new TypeError(`'${typeof deps}' object has no attribute 'values'`);
    for (const dep of deps.values()) {
      if (isObject(dep) && dep.has("path")) {
        const p = dep.get("path");
        if (typeof p !== "string") throw new TypeError("expected str, bytes or os.PathLike object");
        if (!p.startsWith("/")) dep.set("path", resolve(pjoin(pparent(wm), p)));
      }
    }
  }
  writeFileSync(pjoin(scratch, "botopink.json"), dumps(ws, 2) + "\n");
  for (const m of mains) {
    const parent = pparent(m);
    const c = pname(parent) === "src"
      ? pjoin(scratch, packageName(`${pname(pparent(pparent(pparent(parent))))}-${pname(pparent(parent))}`)) // cases/<case>/src/main.bp
      : pjoin(scratch, packageName(pname(pparent(parent))));
    mkdirNew(c, true);
    let manifest: JsonObject = new Map([["name", pname(c)]]);
    if (pname(parent) === "draft") {
      // decision 775: draft/botopink.json is the package's manifest (its "targets" decide which targets run),
      // draft/deps/<pkg>/ its dependencies, beside the manifest as the promoted cell keeps them
      copyTree(parent, pjoin(c, "src"), ["botopink.json", "deps"]);
      if (isFile(pjoin(parent, "botopink.json"))) manifest = withName(loads(readText(pjoin(parent, "botopink.json"))), pname(c));
      if (isDir(pjoin(parent, "deps"))) copyTree(pjoin(parent, "deps"), pjoin(c, "deps"));
    } else {
      copyTree(parent, pjoin(c, "src")); // the whole draft/: main.bp and any <other>.bp
    }
    writeFileSync(pjoin(c, "botopink.json"), dumps(manifest, 2) + "\n");
  }
  const r = spawn([binary, "cell", "check", relativeTo(scratch, repoDir)], { cwd: repoDir });
  const output = r.stdout + r.stderr;
  const red: [string, string][] = [];
  const blocks = new Map<string, string[]>();
  let cur: string | null = null;
  for (const ln of splitlines(output)) {
    const m = FAIL_LINE.match(ln);
    if (m) {
      cur = pname(m.group(1)!);
      blocks.set(cur, []);
      if (!ln.includes("a new cell")) red.push([cur, ln]);
    } else if (ln.includes("+ refused") && cur) {
      red.push([cur, strip(ln)]);
    }
    if (cur && !m) {
      if (END_LINE.match(ln)) cur = null;
      else blocks.get(cur)!.push(ln);
    }
  }
  rmSync(scratch, { recursive: true, force: true });
  if (red.length) {
    for (const [cell, ln] of red) {
      out(`compile ${repo}: ${cell}: ${ln}`);
      if (ln.startsWith("FAIL ")) {
        if (verbose) for (const b of blocks.get(cell) ?? []) out(`    | ${b}`);
        else for (const b of firstDiagnostics(blocks.get(cell) ?? [])) out(`    ${b}`);
      }
    }
    out("front 166: the example above does not build");
    return 1;
  }
  out(`compile ${repo}: ${mains.length} examples build`);
  return 0;
}

/** `{**manifest, "name": name}`: the manifest's keys in their order, the name set (kept where it was). */
function withName(manifest: Json, name: string): JsonObject {
  if (!isObject(manifest)) throw new TypeError("'dict' required for a ** mapping");
  const o: JsonObject = new Map(manifest);
  o.set("name", name);
  return o;
}

function globIn(dir: string, pattern: string): string[] {
  // the parts are a cell directory, then fixed names or one `*` level: walk them
  let found = [dir];
  for (const seg of pattern.split("/")) {
    if (seg === "*") {
      const next: string[] = [];
      for (const f of found) {
        try {
          for (const n of readdirSync(f)) next.push(pjoin(f, String(n)));
        } catch {}
      }
      found = next;
    } else found = found.map((f) => pjoin(f, seg));
  }
  return found.filter(lexists);
}

// ── promote ─────────────────────────────────────────────────────────────────────

function cmdPromote(root: string, args: string[]): number {
  if (args.length !== 1) {
    err("usage: decision-cells.ts promote <repo>");
    return 2;
  }
  const repo = args[0];
  const d = cellsDir(root, repo);
  let n = 0;
  for (const m of isDir(d) ? sortPaths(iterdir(d)) : []) {
    const main = pjoin(m, phase1Main(false));
    if (!isFile(main) || ["src", "cases", "run", "refused", "cells"].some((x) => exists(pjoin(m, x)))) continue;
    // decisions 765, 779: draft/ -> cells/example/src/, a full cell of its own
    const kase = pjoin(m, "cells", "example");
    mkdirNew(kase, true);
    renameSync(pparent(main), pjoin(kase, "src")); // every file of the draft
    let manifest: JsonObject = new Map([["name", packageName(`${pname(m)}-example`)]]);
    const drafted = pjoin(kase, "src", "botopink.json");
    if (isFile(drafted)) {
      // decision 775: the draft's keys win over the generated defaults, the name stays the cell's
      manifest = withName(loads(readText(drafted)), manifest.get("name") as string);
      unlinkSync(drafted);
      if (manifest.has("targets")) {
        const allowed = workspaceTargets(root, repo);
        const kept = iter(manifest.get("targets")!).filter((t) => contains(allowed, t));
        if (kept.length) manifest.set("targets", kept);
        else manifest.delete("targets");
      }
    }
    if (isDir(pjoin(kase, "src", "deps"))) renameSync(pjoin(kase, "src", "deps"), pjoin(kase, "deps"));
    writeFileSync(pjoin(kase, "botopink.json"), dumps(manifest) + "\n");
    mkdirNew(pjoin(kase, "snapshot"));
    const docs = pjoin(m, "docs.md");
    if (exists(docs)) writeFileSync(docs, LINK.sub(promotedLink, readText(docs)));
    n++;
  }
  const wm = workspaceManifest(root, repo);
  if (n && wm) addWorkspaceGlob(wm, "decisions-taken/*/cells/*");
  out(`promote ${repo}: ${n} cells`);
  return 0;
}

/** Rewrite one Markdown link into draft/: its file lands in src/, except the manifest and deps/ (decision 775),
 *  which sit beside src/; a label that spelled the old path spells the new one. */
function promotedLink(k: Match): string {
  const whole = k.group(0)!;
  const i = whole.indexOf("](");
  const label = whole.slice(1, i);
  const target = whole.slice(i + 2, -1);
  if (!target.startsWith("draft/")) return whole;
  const rest = target.slice("draft/".length);
  const fresh = "cells/example/" + (rest === "botopink.json" || rest.startsWith("deps/") ? rest : "src/" + rest);
  return `[${label === target ? fresh : label}](${fresh})`;
}

const WORKSPACES = re('("workspaces"\\s*:\\s*\\[)(.*?)(\\s*\\])', "S");
const ITEM_INDENT = re('\\n(\\s*)\\"');
const ITEM_LINE = re('\\n\\s*\\"');

function addWorkspaceGlob(manifest: string, glob: string) {
  const text = readText(manifest);
  const m = WORKSPACES.search(text);
  if (!m || m.group(2)!.includes(`"${glob}"`)) return;
  const items = m.group(2)!;
  let fresh: string;
  if (items.includes("\n")) {
    const indents = ITEM_INDENT.findall(items);
    const indent = ITEM_LINE.test(items) ? indents[indents.length - 1] : "    ";
    fresh = rstrip(items) + `,\n${indent}"${glob}"`;
  } else {
    fresh = (strip(items) ? rstrip(items) + ", " : "") + `"${glob}"`;
  }
  const start = m.index + m.group(1)!.length, end = start + items.length;
  writeFileSync(manifest, text.slice(0, start) + fresh + text.slice(end));
}

// ── check (CI check 7) ──────────────────────────────────────────────────────────

function workspaceTargets(root: string, repo: string): Json {
  const wm = workspaceManifest(root, repo);
  if (wm) {
    const t = get(loads(readText(wm)), "targets");
    if (t !== undefined && truthy(t)) return t;
  }
  return ALL_TARGETS;
}

type Red = (row: number | string, why: string) => void;

const CELL_DIR = re("(.+)-(\\d+)");

/** Reasons, one line each. */
export function checkRepo(root: string, repo: string): string[] {
  const found: string[] = [];
  const red: Red = (row, why) => {
    const label = typeof row === "number" ? `decision ${row}` : `directory ${row}`;
    found.push(`decision-cells: ${repo}: ${label}: ${why} (front 166)`);
  };

  const rows = ledger(root, repo);
  const byNum = new Map<number, Row>();
  for (const r of rows ?? []) byNum.set(r.num, r);
  const d = cellsDir(root, repo);
  if (isDir(d)) {
    for (const m of iterdir(d).sort((a, b) => cmpStr(pname(a), pname(b)))) {
      if (!isDir(m)) continue;
      const name = pname(m);
      const nm = CELL_DIR.fullmatch(name);
      const row = nm ? byNum.get(toInt(nm.group(2)!)) : undefined;
      if (row === undefined) {
        red(name, "directory name is <slug>-<N> with N naming no row of the repository's decisions-taken.md");
        continue;
      }
      if (row.script) {
        red(name, `row ${row.num} is proven by ${row.script}, not by a cell (decisions 1020, 1022): the directory must not stay`);
        continue;
      }
      if (row.slug !== nm!.group(1)) {
        red(name, `directory slug differs from the row's (${row.slug || "none"})`);
        continue;
      }
      if (row.kind === "oneliner") {
        red(row.num, "row is a one-liner (replaced / reversed / overtaken) and has no cell");
        continue;
      }
      if (row.kind === "process") {
        red(row.num, "row is tagged process and has no cell");
        continue;
      }
      checkCell(root, repo, m, row, red);
    }
  }
  for (const r of rows ?? []) {
    if (r.kind === "code" && r.script && !exists(pjoin(root, "repository", repo, r.scriptFile!)))
      red(r.num, `code-bearing row names the proof script ${r.script} and ${r.scriptFile} does not exist (decisions 1020, 1022)`);
  }
  if (COMPLETE_REPOS.includes(repo)) {
    for (const r of rows ?? []) {
      if (r.kind !== "code") continue;
      if (r.script) continue;
      if (!r.slug) red(r.num, "code-bearing row has no slug in the ledger's Cell column");
      else if (!isDir(pjoin(d, r.dirname!))) red(r.num, `code-bearing row has no conformance/modules/decisions-taken/${r.dirname} directory`);
    }
  }
  return found;
}

/** The `targets` of a manifest; a ValueError (not JSON, not UTF-8) is reported as `notJson`. */
function manifestTargets(f: string, notJson: () => void): Json | undefined {
  let v: Json;
  try {
    v = loads(readText(f));
  } catch (e) {
    if (e instanceof ValueError) {
      notJson();
      return undefined;
    }
    throw e;
  }
  return get(v, "targets");
}

/** Decision 765: `cases/<case>/` (779: `cells/<case>/`) each a full cell: botopink.json, src/main.bp, snapshot/. */
function checkCases(root: string, repo: string, m: string, n: number, red: Red, where = "cases") {
  const found = sortPaths(iterdir(pjoin(m, where)).filter(isDir));
  if (!found.length) red(n, `${where}/ holds no case`);
  for (const c of found) {
    const name = pname(c);
    for (const [need, ok] of [
      ["botopink.json", isFile(pjoin(c, "botopink.json"))],
      ["src/main.bp", isFile(pjoin(c, "src/main.bp"))],
      ["snapshot/", isDir(pjoin(c, "snapshot"))],
    ] as const)
      if (!ok) red(n, `case ${name} has no ${need} (decision 765)`);
    if (isFile(pjoin(c, "botopink.json"))) {
      const targets = manifestTargets(pjoin(c, "botopink.json"), () => red(n, `case ${name} botopink.json is not JSON`));
      const extra = (targets !== undefined && truthy(targets) ? iter(targets) : []).filter((t) => !contains(workspaceTargets(root, repo), t));
      if (extra.length) red(n, `case ${name} botopink.json targets ${repr(extra)} are not the workspace's`);
    }
  }
}

/** Decision 989: a self-checking module — botopink.json and src/main.bp loading each `cases/<case>/` (a package
 *  of botopink.json and src/main.bp; its expected answer is a section of snapshot/main.snap), so a case has no
 *  snapshot/ of its own and the module's manifest sits within the workspace's targets. */
function checkSelfChecking(root: string, repo: string, m: string, n: number, red: Red) {
  const mf = pjoin(m, "botopink.json");
  if (!isFile(mf)) red(n, "self-checking module has src/main.bp and cases/ but no botopink.json (decision 989)");
  else {
    const targets = manifestTargets(mf, () => red(n, "botopink.json is not JSON"));
    const extra = (targets !== undefined && truthy(targets) ? iter(targets) : []).filter((t) => !contains(workspaceTargets(root, repo), t));
    if (extra.length) red(n, `botopink.json targets ${repr(extra)} are not the workspace's`);
  }
  const found = sortPaths(iterdir(pjoin(m, "cases")).filter(isDir));
  if (!found.length) red(n, "cases/ holds no case");
  for (const c of found) {
    const name = pname(c);
    if (!isFile(pjoin(c, "botopink.json"))) red(n, `case ${name} has no botopink.json (decision 989)`);
    else {
      const targets = manifestTargets(pjoin(c, "botopink.json"), () => red(n, `case ${name} botopink.json is not JSON`));
      const extra = (targets !== undefined && truthy(targets) ? iter(targets) : []).filter((t) => !contains(workspaceTargets(root, repo), t));
      if (extra.length) red(n, `case ${name} botopink.json targets ${repr(extra)} are not the workspace's`);
    }
    if (!isFile(pjoin(c, "src/main.bp"))) red(n, `case ${name} has no src/main.bp (decision 989)`);
  }
}

/** Decision 779: `run/` and `refused/` are packages of cases — botopink.json, src/main.bp,
 *  src/cases/mod.bp, snapshot/, each `src/cases/<case>/` holding mod.bp —, and `cells/<case>/`
 *  each a full cell. */
function checkPackages(root: string, repo: string, m: string, n: number, red: Red) {
  for (const kind of ["run", "refused"]) {
    const p = pjoin(m, kind);
    if (!isDir(p)) continue;
    for (const need of ["botopink.json", "src/main.bp", "src/cases/mod.bp", "snapshot"])
      if (!exists(pjoin(p, need))) red(n, `${kind}/ has no ${need} (decision 779)`);
    const casesDir = pjoin(p, "src", "cases");
    const found = isDir(casesDir) ? sortPaths(iterdir(casesDir).filter(isDir)) : [];
    if (!found.length) red(n, `${kind}/ holds no case (decision 779)`);
    for (const c of found) if (!isFile(pjoin(c, "mod.bp"))) red(n, `${kind}/ case ${pname(c)} has no mod.bp (decision 779)`);
  }
  if (isDir(pjoin(m, "cells"))) checkCases(root, repo, m, n, red, "cells");
}

const URL_SCHEME = re("[a-z][a-z0-9+.-]*:");

function checkCell(root: string, repo: string, m: string, row: Row, red: Red) {
  const n = row.num;
  const draft = isFile(pjoin(m, phase1Main(false))), src = isFile(pjoin(m, phase1Main(true)));
  const packed = ["run", "refused", "cells"].some((x) => isDir(pjoin(m, x)));
  const cases = isDir(pjoin(m, "cases")) || packed;
  // decision 989: a self-checking module is src/main.bp beside cases/ (and the leftovers run/, refused/, cells/)
  const selfChecking = src && !draft && isDir(pjoin(m, "cases"));
  if (cases && (draft || src) && !selfChecking) {
    red(n, `holds both cases/ and ${phase1Main(draft === false)} (decision 765: a draft or cases, not both)`);
    return;
  }
  if (draft && src) {
    red(n, `holds both ${phase1Main(false)} and ${phase1Main(true)} (decision 649: one or the other)`);
    return;
  }
  if (!draft && !src && !cases) {
    red(n, `holds neither ${phase1Main(false)} nor ${phase1Main(true)} nor cases (decisions 649, 765, 779)`);
    return;
  }
  const promoted = src;
  const program = pjoin(m, phase1Main(promoted));
  if (selfChecking) checkSelfChecking(root, repo, m, n, red);
  else if (isDir(pjoin(m, "cases"))) checkCases(root, repo, m, n, red);
  if (packed) checkPackages(root, repo, m, n, red);
  const docs = pjoin(m, "docs.md");
  if (!isFile(docs)) red(n, "no docs.md");
  else {
    const lines = readText(docs).split("\n");
    if (lines[0] !== `# ${row.title}`) red(n, "docs.md first line is not the row's");
    const includes = lines.flatMap((ln) => INCLUDE.findall(ln));
    if (!includes.length) red(n, "docs.md has no [path](path) link to its .bp example");
    if (lines.some((ln) => PLACEHOLDER.match(strip(ln)))) red(n, "docs.md holds a {path} placeholder; code is included by a Markdown link (decision 650)");
    for (const inc of includes) if (!isFile(pjoin(m, inc))) red(n, `docs.md links ${inc}, which does not exist`);
    // decision 765: every link resolves
    const links = sortStr(new Set(lines.flatMap((ln) => LINK.findall(ln)).filter((t) => !includes.includes(t))));
    for (const tgt of links) {
      const path = tgt.split("#")[0];
      if (path && !URL_SCHEME.match(path) && !exists(pjoin(m, path))) red(n, `docs.md links ${tgt}, which does not exist`);
    }
    if (lines.some((ln) => lstrip(ln).startsWith("```"))) red(n, "docs.md contains a fenced code block (code lives in the included file)");
  }
  if (cases && !selfChecking) return;
  // a self-checking module's main.bp and cases carry the module's own header (989), not the row's
  if (isFile(program) && !selfChecking) {
    const first = readText(program).split("\n")[0];
    if (first !== `//// ${row.title}`) red(n, `${phase1Main(promoted)} header is not the row's`);
  }
  if (promoted && !selfChecking) {
    const mf = pjoin(m, "botopink.json");
    if (!isFile(mf)) red(n, "promoted cell has no botopink.json");
    else {
      const targets = manifestTargets(mf, () => red(n, "botopink.json is not JSON"));
      if (targets !== undefined && truthy(targets)) {
        const extra = iter(targets).filter((t) => !contains(workspaceTargets(root, repo), t));
        if (extra.length) red(n, `botopink.json targets ${repr(extra)} are not the workspace's`);
      }
    }
  } else if (!selfChecking && (exists(pjoin(m, "botopink.json")) || exists(pjoin(m, "src")))) {
    red(n, "phase 1 cell has a manifest or src/ without being promoted");
  }
}

function cmdCheck(root: string, _args: string[]): number {
  const bad: string[] = [];
  for (const repo of reposWithCells(root)) bad.push(...checkRepo(root, repo));
  for (const ln of bad) out(ln);
  if (!bad.length) out("decision-cells: green");
  return bad.length ? 1 : 0;
}

function main(): number {
  const args = argv();
  let root = ROOT;
  const i = args.indexOf("--root");
  if (i >= 0) {
    root = resolve(at(args, i + 1));
    args.splice(i, 2);
  }
  const cmds: Record<string, (root: string, args: string[]) => number> = {
    scaffold: cmdScaffold, compile: cmdCompile, promote: cmdPromote, check: cmdCheck,
  };
  if (!args.length || !Object.hasOwn(cmds, args[0])) {
    err(USAGE);
    return 2;
  }
  return cmds[args[0]](root, args.slice(1));
}

if (import.meta.main) run(main);
