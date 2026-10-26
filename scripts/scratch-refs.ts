#!/usr/bin/env bun
/*
scratch-refs.ts — a spec never points at scratch: where a task's work lives
while it is in flight is not where the work is described.

Usage:
  scripts/scratch-refs.ts [PATH ...]      (from anywhere in the meta checkout)

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
*/
import {
  ValueError, argv, cmpKey, cpIndex, cpSlice, decode, err, glob, isDigitStart, isDir, iterdir, out, pjoin, pname,
  psuffix, re, relativeTo, resolve, run, sortPaths, spawnChecked, splitlines, strip, universal, versionKey, type Re,
} from "./lib/compat.ts";
import { readFileSync } from "node:fs";

export const PATTERNS: [string, Re][] = [
  ["tasks-path", re("\\.tasks/(?!<)[A-Za-z0-9._-]+")],
  // `/tmp/` alone in backticks names the rule, not a location.
  ["tmp-path", re("(?<![A-Za-z0-9_.`])/tmp/(?!`)|scratchpad")],
  // `front/step` is status.md's legend (a front and its step), not a branch.
  ["task-branch", re("(?<![A-Za-z0-9_/.-])front/(?!<|step\\b)[a-z0-9][a-z0-9._-]*[a-z0-9](?=[`\\s,;:)]|$)")],
  // worktree `--lang` / `--repo …` names a mode of worktree-add.sh, not a worktree.
  ["worktree", re("\\bworktree `(?!<|-)[^`]+`")],
];

const TEXT_SUFFIXES = new Set([".md", ".txt", ".bp", ".json", ".yml", ".yaml", ".sh", ".py"]);

function metaRoot(): string {
  return pjoin(strip(spawnChecked(["git", "rev-parse", "--show-toplevel"]).stdout));
}

function defaultTree(root: string): string {
  const versions = iterdir(pjoin(root, "specs"))
    .filter((p) => isDir(p) && isDigitStart(pname(p)))
    .sort((a, b) => cmpKey(versionKey(pname(a)), versionKey(pname(b))));
  if (!versions.length) throw new RangeError("list index out of range");
  return versions[versions.length - 1];
}

function tracked(root: string, paths: string[]): string[] {
  const rel = paths.map((p) => relativeTo(resolve(p), root));
  const listed = spawnChecked(["git", "-C", root, "ls-files", "-z", "--", ...rel]).stdout;
  return listed.split("\0").filter((f) => f && TEXT_SUFFIXES.has(psuffix(f))).map((f) => pjoin(root, f));
}

function main(): number {
  const root = metaRoot();
  const args = argv();
  if (!args.length && !isDir(pjoin(root, "specs"))) {
    // The specs live in specs-data since the cutover; specs-bot refuses a scratch reference at write time.
    out("scratch-refs: no specs/ in this checkout — specs-bot checks spec text when it is written");
    return 0;
  }
  const paths = args.length ? args.map((a) => pjoin(a)) : [defaultTree(root), ...sortPaths(glob(pjoin(root, "specs"), "*.md"))];
  let found = 0;
  for (const f of tracked(root, paths)) {
    let lines: string[];
    try {
      lines = splitlines(universal(decode(readFileSync(f))));
    } catch (e) {
      if (e instanceof ValueError) continue;
      throw e;
    }
    lines.forEach((line, i) => {
      for (const [kind, rx] of PATTERNS) {
        const m = rx.search(line);
        if (!m) continue;
        found++;
        const start = cpIndex(line, m.index), end = cpIndex(line, m.end);
        const snippet = strip(cpSlice(line, Math.max(0, start - 50), end + 50));
        out(`${relativeTo(f, root)}:${i + 1}: ${kind}: …${snippet}…`);
      }
    });
  }
  if (found) {
    err(`scratch-refs: ${found} reference(s) to scratch locations`);
    return 1;
  }
  err("scratch-refs: none");
  return 0;
}

if (import.meta.main) run(main);
