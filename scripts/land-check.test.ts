// Tests of land-check.ts: one green case and one red case per reason, each in a throwaway git repo.
//
// Usage: bun test scripts/land-check.test.ts
import { afterEach, beforeEach, expect, test } from "bun:test";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";

const SCRIPT = join(import.meta.dir, "land-check.ts");
const PT = "specs/m/decisoes-pendentes.md", EN = "specs/m/decisions-pending.md";
const BLOCK = "#### A-1 · q\n```bp\nval x = 1;\n```\n";

let repo = "";

function git(...a: string[]) {
  const r = Bun.spawnSync(["git", "-C", repo, "-c", "user.name=t", "-c", "user.email=t@t", ...a], { stdout: "pipe", stderr: "pipe" });
  if (r.exitCode !== 0) throw new Error(`git ${a.join(" ")}: ${r.stderr.toString()}`);
}

function write(rel: string, text: string) {
  mkdirSync(dirname(join(repo, rel)), { recursive: true });
  writeFileSync(join(repo, rel), text);
}

function commit(msg = "c") {
  git("add", "-A", "-f");
  git("commit", "-q", "-m", msg);
}

function runCheck(): [number, string] {
  const r = Bun.spawnSync([process.execPath, SCRIPT, repo, "work"], { stdout: "pipe", stderr: "pipe" });
  return [r.exitCode ?? 1, r.stdout.toString()];
}

function expectRed(reason: string) {
  const [code, out] = runCheck();
  expect(code).toBe(1);
  expect(out).toContain(reason + ":");
}

beforeEach(() => {
  repo = mkdtempSync(join(tmpdir(), "land-check-test-"));
  git("init", "-q", "-b", "feat");
  write(EN, BLOCK);
  write(PT, BLOCK);
  commit("base");
  git("update-ref", "refs/remotes/origin/feat", "HEAD");
  git("checkout", "-q", "-b", "work");
});

afterEach(() => rmSync(repo, { recursive: true, force: true }));

test("green", () => {
  write("specs/m/ok.md", "plain text\n");
  commit();
  expect(runCheck()).toEqual([0, "land-check: green\n"]);
});

test("not fast-forward", () => {
  git("checkout", "-q", "feat");
  write("other.txt", "x");
  commit("moved");
  git("update-ref", "refs/remotes/origin/feat", "HEAD");
  git("checkout", "-q", "work");
  write("a.txt", "a");
  commit();
  expectRed("not-fast-forward");
});

test("forbidden file", () => {
  for (const name of ["a.snap.new", "b.snap.md.new", "todo.md"]) {
    write(name, "x");
    commit();
    expectRed("forbidden-file");
    git("reset", "-q", "--hard", "HEAD~1");
  }
});

test("scratch ref", () => {
  write("specs/m/n.md", "see .tasks/foo-1/patch\n");
  commit();
  expectRed("scratch-ref");
});

test("commit hash", () => {
  write("specs/m/n.md", "landed in 1a2b3c4d5e6f\n");
  commit();
  expectRed("commit-hash");
});

test("pair code differs", () => {
  write(PT, BLOCK.replace("x = 1", "x = 2"));
  commit();
  expectRed("pair-differs");
});

test("pair ids differ", () => {
  write(PT, BLOCK.replace("A-1", "A-2"));
  commit();
  expectRed("pair-differs");
});

test("snapshot targets", () => {
  write("lib/snapshot/targets/erlang/a.out", "x");
  commit();
  expectRed("snapshot-targets");
});
