# Front 114 — gate-docs-and-ci: no `skip` fence, no soft CI row, every workflow green and pinned

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [144-botopink-lang](../README.md): s3 → B-29 · s7 → B-29 · s8 box 1 → B-29; [163-meta-ci](../../../3-medium/163-meta-ci/README.md): s9 → 163 s1. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high · **State:** partial: steps 1, 2, 4, 5, step 3 box 1, step 6 and step 8
boxes 1–3 done; steps 3 (box 2), 7, 8 (boxes 4–5), 9 open
**Depends on:** nothing open (botopink-lang CI fixes on feat; only a green run remains)
**Owns:** `scripts/check-docs.sh` · `docs.md` marker lines and the fence lines after them (no prose) ·
botopink-lang `.github/workflows/test.yml` · meta `.github/workflows/**` and meta `AGENTS.md` § CI ·
windows snapshot-capture normalisation · gate residue (115, 132, 133 closed): `scripts/gate.sh`
budget lines (`budget_cold`, § budget comment), vscode-extension workflow's Erlang install, stale
glibc comment in `repository/rakun/.github/workflows/test.yml`, emilia `test.yml` jhonstart
checkout (step 8), the cold-gate record here.
**Does not touch:** `docs.md` prose (`../../01-compiler/07-residuals`) · `build.zig`
(`../../01-compiler/26-cli-tooling`) · any library's hook or test step · `README.md`'s one fence.

## Goal

Every `botopink` fence of `docs.md`/`README.md` checked; every CI workflow the gate relies on hard,
OTP 28, green on `feat`; a recorded green cold gate on the tip within 450 s (decision 265).

## Mechanism

- `check-docs.sh` directives: `reject [body] <expectation>` (verbatim in the first `error` line of
  a non-zero `botopink check`; one refusal per fence), `project <name> <path>` (scratch project;
  deps by name via `libs/`, `<repo>/..`, `<repo>/repository`), `body`. Fails: `skip`, unknown
  directive, directive on a non-`botopink` fence (`project` excepted), `reject` without
  expectation. Nine synthetic fences judged first (`--self-test` = only them). Table/grammar =
  ```` ```text ````.
- `test.yml`: `../README.md` § Rules 5, 13 (decisions 226, 231, 219); the `test` job checks out
  erika at `repository/erika` for `test-docs`.
- Meta `hook-integrity.yml`: one job, push/PR to `feat`/`main`; checks in `../README.md` § Rules 16.

## Handed out

| Item | To | Why |
|---|---|---|
| `docs.md:5` — "a fence that is not a module … says so in a `docs-check` comment" stale (table is ```` ```text ````) | `../../01-compiler/07-residuals` (prose) | fence/marker lines only here |
| `build.zig` `test-docs` comment (near `:574`) describes `<!-- docs-check: skip <reason> -->` | `../../01-compiler/26-cli-tooling` (owns `build.zig`, decision 219) | not this front's file |

## Blast radius

- `../../01-compiler/07-residuals` owns `docs.md` prose.
- `../../01-compiler/18-comptime-runtimes`' "CI matrix run test.yml" = same file; no windows row until step 3 lands.
