#!/usr/bin/env bun
/*
land-check.ts — the coordinator's check of a branch before it lands (decision 484, front 163 s12).

Usage:
  scripts/land-check.ts <repo> <branch> [--base <ref>]

  <repo>    a git checkout: a path, or a name under `repository/` of the meta checkout
  <branch>  the branch (or any commit) to land
  --base    what it lands on (default `origin/feat`)

Prints `land-check: green`, or one line per reason it is red, and exits 1 when red:

  not-fast-forward   the base is not an ancestor of the branch (rebase onto it);
  forbidden-file     a tracked `*.snap.new`, `*.snap.md.new` or `todo.md` at the branch;
  scratch-ref        an added line under `specs/` naming scratch (`scratch-refs.ts`'s patterns);
  commit-hash        an added line under `specs/` holding a commit hash;
  pair-differs       an English/Portuguese pair (`decisions-pending.md` / `decisoes-pendentes.md`)
                     changed by the branch whose heading ids or code blocks differ;
  snapshot-targets   a file the branch adds under `snapshot/targets/` (named, for the coordinator
                     to read against decision 458 — a departure never records a defect).

The spec checks run only where the repository has a `specs/` tree (the meta repository).
*/
import { realpathSync } from "node:fs";
import { dirname } from "node:path";
import {
  argv, cmpPath, die, err, exists, isDir, lstrip, out, pjoin, pname, pparent, re, repr, resolve, run, spawn, spawnChecked,
  splitlines, toInt, type Ran,
} from "./lib/compat.ts";
import { PATTERNS } from "./scratch-refs.ts";

const HERE = dirname(realpathSync(import.meta.path));
const FORBIDDEN = re("(^|/)(todo\\.md|[^/]*\\.snap\\.new|[^/]*\\.snap\\.md\\.new)$");
const HASH = re("\\b(?=[0-9a-f]*[0-9])(?=[0-9a-f]*[a-f])[0-9a-f]{7,40}\\b");
// English/Portuguese pairs: (English file, Portuguese file) — the pairs AGENTS.md § Conventions names.
const PAIRS: [string, string][] = [["decisions-pending.md", "decisoes-pendentes.md"]];

function git(repo: string, args: string[], check = true): Ran {
  return (check ? spawnChecked : spawn)(["git", "-C", repo, ...args]);
}

function resolveRepo(arg: string): string {
  let p = pjoin(arg);
  if (!exists(p)) p = pjoin(pparent(HERE), "repository", arg);
  if (!exists(p)) die(`land-check: no repository ${repr(arg)}`);
  return resolve(p);
}

/** (file, line number, text) of each line the branch adds under `prefix`. */
function* addedLines(repo: string, base: string, branch: string, prefix: string): Generator<[string, number, string]> {
  const diff = git(repo, ["diff", "--unified=0", "--no-color", `${base}...${branch}`, "--", prefix]).stdout;
  let f: string | null = null, n = 0;
  for (const line of splitlines(diff)) {
    if (line.startsWith("+++ ")) f = line.startsWith("+++ b/") ? line.slice(6) : null;
    else if (line.startsWith("@@")) n = toInt(re("\\+(\\d+)").search(line)!.group(1)!) - 1;
    else if (f && line.startsWith("+")) {
      n++;
      yield [f, n, line.slice(1)];
    }
  }
}

function show(repo: string, branch: string, path: string): string | null {
  const r = git(repo, ["show", `${branch}:${path}`], false);
  return r.code === 0 ? r.stdout : null;
}

const HEADING_ID = re("#+\\s+([A-Za-z0-9][A-Za-z0-9.-]*)\\s+·");

function pairShape(text: string): [string[], string[]] {
  const ids: string[] = [], blocks: string[] = [];
  let cur: string[] = [], fenced = false;
  for (const line of splitlines(text)) {
    if (lstrip(line).startsWith("```")) {
      if (fenced) {
        blocks.push(cur.join("\n"));
        cur = [];
      }
      fenced = !fenced;
    } else if (fenced) cur.push(line);
    else if (line.startsWith("#")) {
      const m = HEADING_ID.match(line);
      if (m) ids.push(m.group(1)!);
    }
  }
  return [ids, blocks];
}

const PROG = "land-check.ts";
const USAGE = `usage: ${PROG} [-h] [--base BASE] repo branch`;
const HELP = `${USAGE}

positional arguments:
  repo
  branch

options:
  -h, --help   show this help message and exit
  --base BASE
`;

/** The command line, read as its argparse parser read it (prefixes of a long option, `--base=x`, `--`). */
function parseArgs(argv: string[]): { repo: string; branch: string; base: string } {
  const usageError = (msg: string): never => {
    err(USAGE);
    err(`${PROG}: error: ${msg}`);
    process.exit(2);
  };
  // Each argument is an option (O), the first `--` (-), or a value (A); after the first `--` everything is a value.
  type Opt = { name: "help" | "base" | null; inline?: string };
  const kinds: ("O" | "-" | "A")[] = [];
  const opts: (Opt | null)[] = [];
  let afterDashes = false;
  for (const a of argv) {
    if (afterDashes) {
      kinds.push("A"), opts.push(null);
      continue;
    }
    if (a === "--") {
      afterDashes = true;
      kinds.push("-"), opts.push(null);
      continue;
    }
    const opt = classify(a);
    kinds.push(opt ? "O" : "A"), opts.push(opt);
  }
  function classify(a: string): Opt | null {
    if (!a.startsWith("-") || a.length === 1) return null;
    if (a === "-h" || a === "--help") return { name: "help" };
    if (a === "--base") return { name: "base" };
    if (a.startsWith("--")) {
      const eq = a.indexOf("=");
      const flag = eq >= 0 ? a.slice(0, eq) : a, inline = eq >= 0 ? a.slice(eq + 1) : undefined;
      const hits = (["--help", "--base"] as const).filter((o) => o.startsWith(flag));
      if (hits.length > 1) usageError(`ambiguous option: ${flag} could match ${hits.join(", ")}`);
      if (hits.length === 1) return { name: hits[0] === "--help" ? "help" : "base", inline };
    } else if (a.startsWith("-h")) {
      return { name: "help", inline: a[2] === "=" ? a.slice(3) : undefined };
    }
    if (/^-\d+$|^-\d*\.\d+$/.test(a) || a.includes(" ")) return null;
    return { name: null };
  }
  const positional: string[] = [];
  const extras: string[] = [];
  let base = "origin/feat";
  for (let i = 0; i < argv.length; ) {
    if (kinds[i] === "O") {
      const o = opts[i]!;
      if (o.name === "help") {
        if (o.inline !== undefined) usageError(`argument -h/--help: ignored explicit argument ${repr(o.inline)}`);
        process.stdout.write(HELP);
        process.exit(0);
      }
      if (o.name === "base") {
        if (o.inline !== undefined) base = o.inline;
        else if (kinds[i + 1] === "A") base = argv[++i];
        else usageError("argument --base: expected one argument");
      } else extras.push(argv[i]);
      i++;
      continue;
    }
    // a run of values: each positional still wanted takes `-*A-*` of it, the rest is unrecognized
    let j = i;
    while (positional.length < 2) {
      let k = j;
      while (kinds[k] === "-") k++;
      if (kinds[k] !== "A") break;
      positional.push(argv[k]);
      k++;
      while (kinds[k] === "-") k++;
      j = k;
    }
    while (j < argv.length && kinds[j] !== "O") extras.push(argv[j++]);
    i = j;
  }
  if (positional.length < 2) usageError(`the following arguments are required: ${["repo", "branch"].slice(positional.length).join(", ")}`);
  if (extras.length) usageError(`unrecognized arguments: ${extras.join(" ")}`);
  return { repo: positional[0], branch: positional[1], base };
}

function main(): number {
  const a = parseArgs(argv());
  const repo = resolveRepo(a.repo);
  const base = a.base, branch = a.branch;
  const red: string[] = [];

  for (const ref of [base, branch])
    if (git(repo, ["rev-parse", "--verify", "--quiet", `${ref}^{commit}`], false).code)
      die(`land-check: ${repr(ref)} is not a commit of ${repo}`);

  if (git(repo, ["merge-base", "--is-ancestor", base, branch], false).code)
    red.push(`not-fast-forward: ${base} is not an ancestor of ${branch} — rebase onto ${base}`);

  for (const f of splitlines(git(repo, ["ls-tree", "-r", "--name-only", branch]).stdout))
    if (FORBIDDEN.test(f)) red.push(`forbidden-file: ${f} is tracked`);

  const changed = splitlines(git(repo, ["diff", "--name-status", "--no-renames", `${base}...${branch}`]).stdout);
  for (const row of changed) {
    const tab = row.indexOf("\t");
    const [st, f] = tab < 0 ? [row, ""] : [row.slice(0, tab), row.slice(tab + 1)];
    if (st === "A" && f.includes("snapshot/targets/")) red.push(`snapshot-targets: ${f} added — read against decision 458`);
  }

  if (isDir(pjoin(repo, "specs"))) {
    for (const [f, n, text] of addedLines(repo, base, branch, "specs")) {
      if (!f.endsWith(".md")) continue;
      for (const [kind, rx] of PATTERNS) if (rx.test(text)) red.push(`scratch-ref: ${f}:${n}: ${kind}`);
      const h = HASH.search(text);
      if (h) red.push(`commit-hash: ${f}:${n}: ${h.group(0)}`);
    }
    const touched = new Set(changed.map((r) => pjoin(r.includes("\t") ? r.slice(r.indexOf("\t") + 1) : "")));
    const dirs = new Map<string, [string, [string, string]]>();
    for (const p of touched)
      PAIRS.forEach((pair, k) => {
        if (pair.includes(pname(p))) dirs.set(`${k}\0${pparent(p)}`, [pparent(p), pair]);
      });
    const ordered = [...dirs.values()].sort((x, y) => cmpPath(x[0], y[0]) || PAIRS.indexOf(x[1]) - PAIRS.indexOf(y[1]));
    for (const [d, pair] of ordered) {
      const [en, pt] = pair.map((n) => show(repo, branch, pjoin(d, n)));
      if (en === null || pt === null) {
        red.push(`pair-differs: ${d}: only one of ${pair[0]} / ${pair[1]} exists`);
        continue;
      }
      const [[ei, eb], [pi, pb]] = [pairShape(en), pairShape(pt)];
      if (ei.length !== pi.length || ei.some((x, i) => x !== pi[i]))
        red.push(`pair-differs: ${d}: heading ids differ (${ei.length} English, ${pi.length} Portuguese)`);
      if (eb.length !== pb.length || eb.some((x, i) => x !== pb[i])) {
        let bad = Math.min(eb.length, pb.length);
        for (let i = 0; i < Math.min(eb.length, pb.length); i++)
          if (eb[i] !== pb[i]) {
            bad = i;
            break;
          }
        red.push(`pair-differs: ${d}: code block ${bad + 1} differs (${eb.length} English, ${pb.length} Portuguese)`);
      }
    }
  }

  if (red.length) {
    out(red.map((r) => `land-check: ${r}`).join("\n"));
    err(`land-check: red (${red.length})`);
    return 1;
  }
  out("land-check: green");
  return 0;
}

if (import.meta.main) run(main);
