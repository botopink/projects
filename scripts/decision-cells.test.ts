// Tests of decision-cells.ts: one green case and one red case per reason of check 7, in throwaway trees,
// plus the classification and the scaffold / promote round trip.
//
// Usage: bun test scripts/decision-cells.test.ts
import { afterEach, beforeEach, describe, expect, test } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, renameSync, rmSync, unlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { COMPLETE_REPOS, Row, checkRepo } from "./decision-cells.ts";

const SCRIPT = join(import.meta.dir, "decision-cells.ts");
const LEDGER = `Generated from x.

## Language

| # | Id | Rule in force | Binds | Cell |
|---|---|---|---|---|
| 10 | a-1 | **Code rule ten.** Body text. | 144 | code_rule_ten |
| 11 | a-2 | **Replaced by 10.** | 144 | |
| 12 | a-3 (process) | **A process rule.** Body. | 163 | |
| 13 | a-4 | **Another code rule.** \`x \\| y\` | 144 | another_code_rule |
| 14 | a-5 | **Overtaken by 10 and 13** (a note). | 144 | |
| 15 | a-6 | **A rule with no slug yet.** | 144 | |
`;
const D = "—";
const T10 = `Decision 10 ${D} Code rule ten.`;
const T13 = `Decision 13 ${D} Another code rule.`;
const S: Record<number, string> = { 10: "code_rule_ten", 13: "another_code_rule" };

let root = "", repo = "", d = "", seen = "";

const read = (p: string) => readFileSync(p, "utf8");
function write(p: string, text: string) {
  mkdirSync(dirname(p), { recursive: true });
  writeFileSync(p, text);
}

beforeEach(() => {
  root = mkdtempSync(join(tmpdir(), "decision-cells-test-"));
  repo = join(root, "repository", "snap");
  mkdirSync(join(repo, "conformance", "modules"), { recursive: true });
  writeFileSync(join(repo, "decisions-taken.md"), LEDGER);
  writeFileSync(join(repo, "conformance/modules/botopink.json"),
    '{ "name": "conformance", "targets": ["commonJS", "erlang"], "workspaces": ["*"] }\n');
  d = join(repo, "conformance/modules/decisions-taken");
});

afterEach(() => rmSync(root, { recursive: true, force: true }));

function runCmd(...a: string[]): [number, string] {
  const r = Bun.spawnSync([process.execPath, SCRIPT, "--root", root, ...a], { stdout: "pipe", stderr: "pipe" });
  return [r.exitCode ?? 1, r.stdout.toString() + r.stderr.toString()];
}

function cell(n: number, title: string, promoted = false): string {
  const c = join(d, n in S ? `${S[n]}-${n}` : `slug_${n}-${n}`);
  mkdirSync(join(c, promoted ? "src" : "draft"), { recursive: true });
  const inc = promoted ? "src/main.bp" : "draft/main.bp";
  writeFileSync(join(c, "docs.md"), `# ${title}\n\nprose\n\n[${inc}](${inc})\n`);
  writeFileSync(join(c, inc), `//// ${title}\npub fn main() -> void {}\n`);
  if (promoted) writeFileSync(join(c, "botopink.json"), JSON.stringify({ name: c.split("/").pop() }));
  return c;
}

/** A stand-in for the compiler: a Bun script at the tree's compiler path. */
function compiler(body: string) {
  const b = join(root, "repository/botopink-lang/zig-out/bin/botopink");
  write(b, `#!${process.execPath}\n${body}`);
  chmodSync(b, 0o755);
}

function fakeCompiler() {
  const report = [
    "FAIL .botopinkbuild/tmp/decision-cells/code_rule_ten-10",
    "  main on commonJS: the targets disagree",
    "    commonJS: error: type mismatch at src/main.bp:3:1",
    "    commonJS: more detail",
    "  main on erlang: broke",
    "    erlang: error: no such function foo",
    "cells: 1 checked - 0 passed, 1 failed",
    "",
  ].join("\n");
  compiler(`process.stdout.write(${JSON.stringify(report)});\nprocess.exit(1);\n`);
}

function slugOn(n: number, slug: string) {
  const lines = read(join(repo, "decisions-taken.md")).split("\n");
  writeFileSync(join(repo, "decisions-taken.md"),
    lines.map((ln) => (ln.startsWith(`| ${n} |`) ? ln.slice(0, -1) + slug + " |" : ln)).join("\n"));
}

function expectRed(text: string) {
  const [code, out] = runCmd("check");
  expect(code).toBe(1);
  expect(out).toContain(text);
  expect(out).toContain("front 166");
}

const GREEN: [number, string] = [0, "decision-cells: green\n"];

test("compile keeps the error of a failing draft", () => {
  cell(10, T10);
  fakeCompiler();
  let [code, out] = runCmd("compile", "snap");
  expect(code).toBe(1);
  const lines = out.split("\n");
  const i = lines.findIndex((ln) => ln.startsWith("compile snap: code_rule_ten-10: FAIL "));
  expect(i).toBeGreaterThanOrEqual(0);
  expect(lines[i + 1]).toContain("commonJS: error: type mismatch at src/main.bp:3:1");
  expect(lines[i + 2]).toContain("erlang: error: no such function foo");
  expect(out).not.toContain("more detail");
  expect(out).toContain("front 166: the example above does not build");
  [code, out] = runCmd("compile", "--verbose", "snap");
  expect(code).toBe(1);
  expect(out).toContain("more detail");
});

test("green empty", () => expect(runCmd("check")).toEqual(GREEN));

test("green phase 1 and promoted", () => {
  cell(10, T10);
  cell(13, T13, true);
  expect(runCmd("check")).toEqual(GREEN);
});

test("unknown row", () => {
  cell(99, `Decision 99 ${D} x`);
  expectRed("snap: directory slug_99-99: directory name is <slug>-<N> with N naming no row");
});

test("one-liner row", () => {
  slugOn(11, "slug_11");
  cell(11, `Decision 11 ${D} Replaced by 10.`);
  expectRed("snap: decision 11: row is a one-liner");
});

test("overtaken one-liner with note", () => {
  slugOn(14, "slug_14");
  cell(14, `Decision 14 ${D} Overtaken by 10 and 13`);
  expectRed("decision 14: row is a one-liner");
});

test("a rule that opens superseded is a one-liner", () => {
  expect(new Row(20, "x", "Overtaken by 10 (1): the rule in force, restated.", "144").kind).toBe("oneliner");
  expect(new Row(21, "x", "Reversed by 13 the same day: restated.", "144").kind).toBe("oneliner");
  expect(new Row(22, "x", "**B-1 is overtaken by 10: a rule of its own.**", "144").kind).toBe("code");
});

test("a process tag is the id column's tag, never the word in the row's text (decision 989)", () => {
  const rule = "**A rule.** Body.";
  expect(new Row(30, "a-1 (process)", rule, "144").kind).toBe("process");
  expect(new Row(31, "a-2 · (process, the maintainer, 2026-10-11)", rule, "144").kind).toBe("process");
  expect(new Row(32, "a-3 · process · (the maintainer)", rule, "144").kind).toBe("process");
  expect(new Row(33, "a-4 · (the coordinator; process, the queues' order)", rule, "144").kind).toBe("process");
  expect(new Row(34, "suite-self · (the maintainer: \"the suite checks itself in-process\")", rule, "144").kind).toBe("code");
  expect(new Row(35, "809-i · (a root that lives with its process)", rule, "144").kind).toBe("code");
});

test("process row", () => {
  slugOn(12, "slug_12");
  cell(12, `Decision 12 ${D} A process rule.`);
  expectRed("decision 12: row is tagged process");
});

test("wrong slug", () => {
  cell(10, T10);
  renameSync(join(d, "code_rule_ten-10"), join(d, "other_name-10"));
  expectRed("directory other_name-10: directory slug differs from the row's (code_rule_ten)");
});

test("docs first line", () => {
  const c = cell(10, T10);
  writeFileSync(join(c, "docs.md"), "# wrong\n\n[draft/main.bp](draft/main.bp)\n");
  expectRed("decision 10: docs.md first line is not the row's");
});

test("no include", () => {
  const c = cell(10, T10);
  writeFileSync(join(c, "docs.md"), `# ${T10}\n\nprose\n`);
  expectRed("docs.md has no [path](path) link");
});

test("include of a missing file", () => {
  const c = cell(10, T10);
  writeFileSync(join(c, "docs.md"), `# ${T10}\n\n[other.bp](other.bp)\n`);
  expectRed("docs.md links other.bp, which does not exist");
});

test("placeholder include", () => {
  const c = cell(10, T10);
  writeFileSync(join(c, "docs.md"), `# ${T10}\n\n[draft/main.bp](draft/main.bp)\n\n{draft/main.bp}\n`);
  expectRed("docs.md holds a {path} placeholder");
});

test("fenced code", () => {
  const c = cell(10, T10);
  writeFileSync(join(c, "docs.md"), `# ${T10}\n\n\`\`\`bp\nx\n\`\`\`\n\n[draft/main.bp](draft/main.bp)\n`);
  expectRed("docs.md contains a fenced code block");
});

test("no docs", () => {
  const c = cell(10, T10);
  unlinkSync(join(c, "docs.md"));
  expectRed("decision 10: no docs.md");
});

test("neither draft nor src", () => {
  const c = cell(10, T10);
  unlinkSync(join(c, "draft/main.bp"));
  writeFileSync(join(c, "docs.md"), `# ${T10}\n\n{docs.md}\n`);
  expectRed("decision 10: holds neither draft/main.bp nor src/main.bp");
});

test("both draft and src", () => {
  const c = cell(10, T10);
  mkdirSync(join(c, "src"));
  writeFileSync(join(c, "src/main.bp"), read(join(c, "draft/main.bp")));
  expectRed("decision 10: holds both draft/main.bp and src/main.bp");
});

test("header", () => {
  const c = cell(10, T10);
  writeFileSync(join(c, "draft/main.bp"), "//// stale\n");
  expectRed("main.bp header is not the row's");
});

test("promoted without manifest", () => {
  const c = cell(13, T13, true);
  unlinkSync(join(c, "botopink.json"));
  expectRed("decision 13: promoted cell has no botopink.json");
});

test("targets not a subset", () => {
  const c = cell(13, T13, true);
  writeFileSync(join(c, "botopink.json"), '{"name": "another_code_rule-13", "targets": ["wasm"]}');
  expectRed("targets ['wasm'] are not the workspace's");
});

test("phase 1 with src", () => {
  const c = cell(10, T10);
  mkdirSync(join(c, "src"));
  expectRed("phase 1 cell has a manifest or src/");
});

test("completeness", () => {
  const [code] = runCmd("check");
  expect(code).toBe(0);
  COMPLETE_REPOS.push("snap");
  try {
    const reasons = checkRepo(root, "snap");
    expect(reasons.map((r) => r.split(": decision ")[1].split(":")[0]).sort()).toEqual(["10", "13", "15"]);
    expect(reasons[0]).toContain("code-bearing row has no conformance/modules/decisions-taken/code_rule_ten-10 directory");
    expect(reasons[2]).toContain("decision 15: code-bearing row has no slug");
    expect(reasons[0]).toContain("front 166");
  } finally {
    COMPLETE_REPOS.splice(COMPLETE_REPOS.indexOf("snap"), 1);
  }
});

test("scaffold --list, then scaffold", () => {
  const [code, out] = runCmd("scaffold", "--list", "snap");
  expect(code).toBe(0);
  expect(out).toContain("snap: 6 rows, 2 one-liners, 1 tagged process, 3 to scaffold");
  expect(existsSync(d)).toBe(false);
  expect(runCmd("scaffold", "snap")[0]).toBe(0);
  expect(readdirSync(d).sort()).toEqual(["another_code_rule-13", "code_rule_ten-10"]);
  expect(read(join(d, "code_rule_ten-10/docs.md"))).toBe(`# ${T10}\n\n[draft/main.bp](draft/main.bp)\n`);
  expect(runCmd("check")).toEqual(GREEN);
});

test("scaffold rewrites a changed lead", () => {
  runCmd("scaffold", "snap");
  writeFileSync(join(repo, "decisions-taken.md"), LEDGER.replace("Code rule ten.", "Renamed rule."));
  runCmd("scaffold", "snap");
  expect(read(join(d, "code_rule_ten-10/docs.md")).split("\n")[0]).toBe(`# Decision 10 ${D} Renamed rule.`);
  expect(read(join(d, "code_rule_ten-10/draft/main.bp")).split("\n")[0]).toBe(`//// Decision 10 ${D} Renamed rule.`);
});

test("promote", () => {
  runCmd("scaffold", "snap");
  expect(runCmd("promote", "snap")[0]).toBe(0);
  const c = join(d, "code_rule_ten-10");
  expect(existsSync(join(c, "cells/example/src/main.bp"))).toBe(true);
  expect(existsSync(join(c, "draft")) || existsSync(join(c, "src"))).toBe(false);
  expect(JSON.parse(read(join(c, "cells/example/botopink.json")))).toEqual({ name: "code_rule_ten-10-example" });
  expect(read(join(c, "docs.md"))).toContain("[cells/example/src/main.bp](cells/example/src/main.bp)");
  expect(read(join(repo, "conformance/modules/botopink.json"))).toContain('"decisions-taken/*/cells/*"');
  expect(runCmd("check")).toEqual(GREEN);
});

function cases(n: number, title: string, names: string[] = ["a"]): string {
  const c = join(d, `${S[n]}-${n}`);
  mkdirSync(c, { recursive: true });
  let links = "";
  for (const nm of names) {
    const k = join(c, "cases", nm);
    mkdirSync(join(k, "src"), { recursive: true });
    mkdirSync(join(k, "snapshot"));
    writeFileSync(join(k, "botopink.json"), JSON.stringify({ name: `${S[n]}-${n}-${nm}` }));
    writeFileSync(join(k, "src/main.bp"), `//// ${nm}\npub fn main() -> void {}\n`);
    links += `[cases/${nm}/src/main.bp](cases/${nm}/src/main.bp)\n`;
  }
  writeFileSync(join(c, "docs.md"), `# ${title}\n\n${links}`);
  return c;
}

function packed(n: number, title: string, run: string[] = ["a", "b"]): string {
  const c = join(d, `${S[n]}-${n}`);
  const p = join(c, "run");
  mkdirSync(join(p, "src/cases"), { recursive: true });
  mkdirSync(join(p, "snapshot"));
  writeFileSync(join(p, "botopink.json"), JSON.stringify({ name: `${S[n]}-${n}-run` }));
  writeFileSync(join(p, "src/main.bp"), "mod cases;\n");
  writeFileSync(join(p, "src/cases/mod.bp"), run.map((nm) => `pub mod ${nm};\n`).join(""));
  let links = "";
  for (const nm of run) {
    mkdirSync(join(p, "src/cases", nm));
    writeFileSync(join(p, "src/cases", nm, "mod.bp"), "pub fn run() {}\n");
    links += `[run/src/cases/${nm}/mod.bp](run/src/cases/${nm}/mod.bp)\n`;
  }
  writeFileSync(join(c, "docs.md"), `# ${title}\n\n${links}`);
  return c;
}

test("green packed", () => {
  packed(10, T10);
  expect(runCmd("check")).toEqual(GREEN);
});

test("packed malformed", () => {
  const c = packed(10, T10);
  unlinkSync(join(c, "run/src/cases/a/mod.bp"));
  expectRed("decision 10: run/ case a has no mod.bp (decision 779)");
  writeFileSync(join(c, "run/src/cases/a/mod.bp"), "pub fn run() {}\n");
  unlinkSync(join(c, "run/src/cases/mod.bp"));
  expectRed("run/ has no src/cases/mod.bp");
});

test("green cases", () => {
  cases(10, T10, ["a", "b"]);
  expect(runCmd("check")).toEqual(GREEN);
});

test("cases and draft", () => {
  const c = cases(10, T10);
  mkdirSync(join(c, "draft"));
  writeFileSync(join(c, "draft/main.bp"), `//// ${T10}\n`);
  expectRed("decision 10: holds both cases/ and draft/main.bp");
});

test("cases malformed", () => {
  const c = cases(10, T10);
  rmSync(join(c, "cases/a/snapshot"), { recursive: true });
  expectRed("decision 10: case a has no snapshot/");
  mkdirSync(join(c, "cases/a/snapshot"));
  unlinkSync(join(c, "cases/a/botopink.json"));
  expectRed("case a has no botopink.json");
});

test("cases empty", () => {
  const c = cases(10, T10, []);
  mkdirSync(join(c, "cases"));
  expectRed("decision 10: cases/ holds no case");
});

test("cases targets", () => {
  const c = cases(10, T10);
  writeFileSync(join(c, "cases/a/botopink.json"), '{"name": "x", "targets": ["wasm"]}');
  expectRed("case a botopink.json targets ['wasm'] are not the workspace's");
});

test("every link resolves", () => {
  const c = cell(10, T10);
  writeFileSync(join(c, "docs.md"), `# ${T10}\n\n[draft/main.bp](draft/main.bp)\n[more](notes.md)\n[web](https://x.y/z)\n`);
  expectRed("docs.md links notes.md, which does not exist");
});

test("compile builds cases", () => {
  cases(10, T10);
  fakeCompiler();
  const [code, out] = runCmd("compile", "snap");
  expect(code).toBe(1);
  expect(out).not.toContain("no draft");
});

describe("decision 775: a draft carries its manifest and its dependencies", () => {
  /** A compiler that records what compile staged: each package's manifest and its tree, then passes. */
  function stagingCompiler() {
    seen = join(root, "seen.json");
    compiler(`
const { readdirSync, readFileSync, statSync, writeFileSync } = require("node:fs");
const { join } = require("node:path");
const dir = process.argv[4];
const files = (base, rel = "") => readdirSync(join(base, rel)).flatMap((n) =>
  statSync(join(base, rel, n)).isDirectory() ? files(base, join(rel, n)) : ["./" + join(rel, n)]);
const staged = {};
for (const p of readdirSync(dir)) {
  if (!statSync(join(dir, p)).isDirectory()) continue;
  staged[p] = { manifest: JSON.parse(readFileSync(join(dir, p, "botopink.json"), "utf8")), files: files(join(dir, p)).sort() };
}
writeFileSync(${JSON.stringify(seen)}, JSON.stringify(staged));
console.log("cells: 1 checked - 1 passed, 0 failed");
`);
  }

  const staged = (name: string): { manifest: any; files: string[] } => JSON.parse(read(seen))[name];

  test("compile honours a draft's targets", () => {
    const c = cell(10, T10);
    writeFileSync(join(c, "draft/botopink.json"), '{"name": "ignored", "targets": ["erlang"], "bpp": "rakun-bpp"}');
    stagingCompiler();
    const [code] = runCmd("compile", "snap");
    expect(code).toBe(0);
    const { manifest, files } = staged("code_rule_ten-10");
    expect(manifest).toEqual({ name: "code_rule_ten-10", targets: ["erlang"], bpp: "rakun-bpp" });
    expect(files).toEqual(["./botopink.json", "./src/main.bp"]); // the manifest is the package's, not a source
  });

  test("compile without a draft manifest is as before", () => {
    cell(10, T10);
    stagingCompiler();
    expect(runCmd("compile", "snap")[0]).toBe(0);
    expect(staged("code_rule_ten-10").manifest).toEqual({ name: "code_rule_ten-10" });
  });

  test("compile resolves a draft dependency", () => {
    const c = cell(10, T10);
    writeFileSync(join(c, "draft/botopink.json"), '{"dependencies": {"helper": {"path": "deps/helper"}}}');
    write(join(c, "draft/deps/helper/botopink.json"), '{"name": "helper"}');
    write(join(c, "draft/deps/helper/src/main.bp"), "pub fn help() -> void {}\n");
    stagingCompiler();
    expect(runCmd("compile", "snap")[0]).toBe(0);
    const { manifest, files } = staged("code_rule_ten-10");
    expect(manifest.dependencies).toEqual({ helper: { path: "deps/helper" } }); // relative to the manifest
    expect(files).toEqual(["./botopink.json", "./deps/helper/botopink.json", "./deps/helper/src/main.bp", "./src/main.bp"]);
  });

  test("promote merges the manifest and moves deps", () => {
    const c = cell(10, T10);
    writeFileSync(join(c, "draft/botopink.json"),
      '{"name": "mine", "targets": ["erlang", "wasm"], "bpp": "rakun-bpp", "dependencies": {"helper": {"path": "deps/helper"}}}');
    write(join(c, "draft/deps/helper/botopink.json"), '{"name": "helper"}');
    writeFileSync(join(c, "docs.md"), `# ${T10}\n\n[draft/main.bp](draft/main.bp)\n[the manifest](draft/botopink.json)\n` +
      "[draft/deps/helper/botopink.json](draft/deps/helper/botopink.json)\n");
    expect(runCmd("check")).toEqual(GREEN); // phase 1 accepts both
    expect(runCmd("promote", "snap")[0]).toBe(0);
    const kase = join(c, "cells/example");
    expect(JSON.parse(read(join(kase, "botopink.json")))).toEqual({
      name: "code_rule_ten-10-example", targets: ["erlang"], bpp: "rakun-bpp", dependencies: { helper: { path: "deps/helper" } },
    });
    expect(existsSync(join(kase, "deps/helper/botopink.json"))).toBe(true);
    expect(existsSync(join(kase, "src/botopink.json")) || existsSync(join(kase, "src/deps")) || existsSync(join(c, "draft"))).toBe(false);
    const docs = read(join(c, "docs.md"));
    for (const link of ["[cells/example/src/main.bp](cells/example/src/main.bp)", "[the manifest](cells/example/botopink.json)",
      "[cells/example/deps/helper/botopink.json](cells/example/deps/helper/botopink.json)"])
      expect(docs).toContain(link);
    expect(runCmd("check")).toEqual(GREEN);
  });

  test("check accepts a draft's manifest and deps", () => {
    const c = cell(10, T10);
    writeFileSync(join(c, "draft/botopink.json"), '{"targets": ["erlang"]}');
    write(join(c, "draft/deps/helper/src/main.bp"), "pub fn help() -> void {}\n");
    writeFileSync(join(c, "docs.md"), `# ${T10}\n\n[draft/main.bp](draft/main.bp)\n[draft/botopink.json](draft/botopink.json)\n` +
      "[draft/deps/helper](draft/deps/helper)\n");
    expect(runCmd("check")).toEqual(GREEN);
  });
});
