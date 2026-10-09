# Front 114 — gate-docs-and-ci: no `skip` fence, no soft CI row, every workflow green and pinned

**Priority:** high · **State:** partial: steps 1, 2, 4, 5, step 3 box 1, step 6 box 1 and step 8
boxes 1–2 done; steps 3 (box 2), 6 (box 2), 7, 8 (box 3), 9 open
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

## Done

Step 1 `reject`/`project` replace `skip` (decision 157) · 2 `scripts/AGENTS.md` § check-docs.sh
table has `reject`, no `skip` · 3 box 1 no `allow_fail`, no windows row (decision 158) · 4 meta
`hook-integrity` checks 1–5 green on remote `feat` · 5 `gate.sh` `budget_cold=450`, `budget_warm=60`, header
and § budget comments name 7m30s cold (decision 265), over budget yellow · 6 box 1 vscode-extension
`compiler` job reads `OTP_RELEASE` from the compiler source, installs it with `erlef/setup-beam`, asserts
it · 8 box 2 rakun `test.yml` and `AGENTS.md` name the 2.35 pin.
8 box 1 133's emitted modules diffed byte for byte, each of 133's two merges against its first
parent (step 2: `838f565a^1` vs `838f565a`; step 3: `b22aaa1d^1` vs `b22aaa1d`), four ReleaseSafe
compilers, one input set (botopink-lang `b22aaa1d`'s `tests/language` and `libs/`; emilia `42d51ec8`,
erika `0a463f5c`, jhonstart `bd397de6`, onze `b1a31105`, rakun `fac248b4` — the meta pins of
`f00c4992`, the first carrying 133): every `run/` cell `botopink build`, every `test/` cell and every
test-kind `modules/` cell `botopink test`, every other `modules/` cell `botopink build`, each on
commonJS, erlang, wasm and beam (1 492 jobs); every library member `botopink build` and `botopink
test` on each manifest target (298 jobs). Every file the compiler wrote but the `erlc`-built `.beam`s
compared (`botopink test`'s run directory kept by a one-line patch applied alike to all four):
step 2 — 3 281 + 246 396 files, step 3 — 3 307 + 246 416, byte-identical, exit status equal on every
job but one (`rakun-devtools` `botopink test --target erlang`, red before step 2 and green after with
identical emitted bytes — a test outcome, not an emission). stderr not compared: it carries the
compile time (`Compiled in 53.24ms`) and differs between two runs of one compiler.

## Open

### Step 3 — the windows row is hard or absent (decision 158)

Row deleted until capture normalises CRLF/separators (known gap, `../../status.md`). To restore: run
the `test` job on windows, list failing snapshots by cause (CRLF in stdout; `\` in paths); if
normalisable in `modules/compiler-core/src/codegen/tests/helpers.zig` without touching an emitter,
do it and restore the row hard with every ubuntu stage (`erlef/setup-beam` supports windows).
- [ ] botopink-lang `test` workflow green on GitHub on `feat`, every row (fixes on feat: test-web
      wasm32, `test-libs.sh`/`run.sh` under macOS bash 3.2 / BSD `xargs`, `pool.sh` without GNU
      `timeout`, macOS `/private/var`). Last run on `49455602` (2026-10-03) red, none of it in
      `test.yml`: stage 1 `zig fmt --check modules` (`comptime/transform.zig:1172`, one indent —
      01-checker's `19d59508`); behind it, reproduced locally, `codegen.tests.beam_templates` (15
      `std/math` templates refused, "operator `:`" — `a443f52d`, std-math-uniform) and
      `comptime/eval.zig` "comptime literals" (`3` expected, `3.0` found — 01-checker)
- [ ] (only with a windows runner) drift measured, capture normalised, row restored hard — else row
      stays deleted, gap carried

### Step 6 — the vscode-extension workflow on OTP 28 (decisions 228, 227)

The `compiler` job installs the compiler's `OTP_RELEASE` (box 1, Done); a green run on remote `feat` remains.
- [ ] `npm test` and `npm run compiler-check` green on GitHub on remote `feat` after that

### Step 7 — a cold gate recorded on the current tip

No cold verdict on any tree containing `gate-integration-7…14`; no ~7m30s cold run recorded (133's
last full cold: 9m31s, loaded).
- [ ] `scripts/gate.sh --cold` green on botopink-lang `feat`, every sibling library at its `feat`
      tip; record tip, each stage's count vs `--list` plan, wall clock, CPU-s, machine load
- [ ] wall clock ≤ 450 s on 16 cores, or the over-budget line recorded as printed (yellow — decision 265)
- [ ] `../README.md` § Exit check counts updated to this run's output

### Step 8 — the gate's other residue

- [ ] after `06-emilia/33` step 2 (emilia-card emilia-only): emilia `.github/workflows/test.yml` step
      "Checkout jhonstart (dependency — examples/emilia-card depends on jhonstart)" (`:94-99`) and
      its comment (`:21`) removed
- [ ] `scripts/check-docs.sh`'s header says `check` is target-independent (`:63`, `:76`): it is not
      since decision 167 — `#[@BeamMemory…]` checks under an erlang manifest and is refused under the
      harness's `commonJS` one, so `docs.md` § `@BeamMemory` is a `project` fence with an erlang
      `botopink.json` (from `07` step 6); the comment says the manifest's target is read
- [ ] the four other libraries' `test.yml` (emilia, erika, jhonstart, onze) carry the stale glibc 2.38
      comment rakun's had

## Handed out

| Item | To | Why |
|---|---|---|
| `docs.md:5` — "a fence that is not a module … says so in a `docs-check` comment" stale (table is ```` ```text ````) | `../../01-compiler/07-residuals` (prose) | fence/marker lines only here |
| `build.zig` `test-docs` comment (near `:574`) describes `<!-- docs-check: skip <reason> -->` | `../../01-compiler/26-cli-tooling` (owns `build.zig`, decision 219) | not this front's file |

## Blast radius

- `../../01-compiler/07-residuals` owns `docs.md` prose.
- `../../01-compiler/18-comptime-runtimes`' "CI matrix run test.yml" = same file; no windows row until step 3 lands.

### Step 9 — a red the gate can meet
- [ ] `repository/rakun/modules/rakun-websocket/test/limits_test.bp:48` (load-dependent cap): bound
      holds under load, or cap made deterministic; ten cold runs of rakun's cells green on a loaded machine

**Gate:** standard (fronts.md § Gate) + `zig build test-docs` green with `0 skipped`.
