# Front 114 — gate-docs-and-ci: no `skip` fence, no soft CI row, every workflow green and pinned

**Priority:** high · **State:** partial: steps 1, 2, 4 and step 3 box 1 on feat; steps 3 (box 2), 5–8 open
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
`hook-integrity` checks 1–5 green on remote `feat`.

## Open

### Step 3 — the windows row is hard or absent (decision 158)

Row deleted until capture normalises CRLF/separators (known gap, `../../status.md`). To restore: run
the `test` job on windows, list failing snapshots by cause (CRLF in stdout; `\` in paths); if
normalisable in `modules/compiler-core/src/codegen/tests/helpers.zig` without touching an emitter,
do it and restore the row hard with every ubuntu stage (`erlef/setup-beam` supports windows).
- [ ] botopink-lang `test` workflow green on GitHub on `feat`, every row (fixes on feat: test-web
      wasm32, `test-libs.sh`/`run.sh` under macOS bash 3.2 / BSD `xargs`, `pool.sh` without GNU
      `timeout`, macOS `/private/var`)
- [ ] (only with a windows runner) drift measured, capture normalised, row restored hard — else row
      stays deleted, gap carried

### Step 5 — `budget_cold=450` (decision 265)

`scripts/gate.sh` sets `budget_cold=300` (near `budget_warm=60`); comment says "5 minutes cold, 1
minute warm".
- [ ] `grep -n '^budget_cold=' scripts/gate.sh` → `budget_cold=450`; `budget_warm=60` unchanged
- [ ] header and budget comments say 7m30s cold (decision 265), 5 minutes deferred; over budget
      stays yellow, never red

### Step 6 — the vscode-extension workflow on OTP 28 (decisions 228, 227)

`repository/vscode-extension/.github/workflows/test.yml` (both jobs `ubuntu-22.04`) runs `apt-get
install -y erlang` = OTP 24, refused by the compiler (`botopink check` evaluates `comptime` via
`erl`); last green may predate the OTP check — latent red.
- [ ] install takes the release from the compiler (`erlef/setup-beam` with what `botopink --version`
      prints, or `otp-version: '28'` read as the library workflows read it)
- [ ] `npm test` and `npm run compiler-check` green on GitHub on remote `feat` after that

### Step 7 — a cold gate recorded on the current tip

No cold verdict on any tree containing `gate-integration-7…14`; no ~7m30s cold run recorded (133's
last full cold: 9m31s, loaded).
- [ ] `scripts/gate.sh --cold` green on botopink-lang `feat`, every sibling library at its `feat`
      tip; record tip, each stage's count vs `--list` plan, wall clock, CPU-s, machine load
- [ ] wall clock ≤ 450 s on 16 cores, or the over-budget line recorded as printed (yellow — decision 265)
- [ ] `../README.md` § Exit check counts updated to this run's output

### Step 8 — the gate's other residue

- [ ] 133 step 2 completed: every emitted module of every `test-libs` and `test-language` cell
      diffed byte-for-byte, `feat` vs the tree before 133's first merge (only printed results were
      diffed); record it here — or withdraw "every cell byte-identical" from `../../status.md`
- [ ] `repository/rakun/.github/workflows/test.yml` header comment (glibc 2.38, "ubuntu-22.04 cannot
      start") rewritten: pin 2.35 (decision 219); rows stay ubuntu-24.04, macos-14
- [ ] after `06-emilia/33` step 2 (emilia-card emilia-only): emilia `.github/workflows/test.yml` step
      "Checkout jhonstart (dependency — examples/emilia-card depends on jhonstart)" (`:94-99`) and
      its comment (`:21`) removed
- [ ] `scripts/check-docs.sh`'s header says `check` is target-independent (`:63`, `:76`): it is not
      since decision 167 — `#[@BeamMemory…]` checks under an erlang manifest and is refused under the
      harness's `commonJS` one, so `docs.md` § `@BeamMemory` is a `project` fence with an erlang
      `botopink.json` (from `07` step 6); the comment says the manifest's target is read

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
