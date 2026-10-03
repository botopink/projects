# Front 114 — gate-docs-and-ci: no `skip` fence, no soft CI row, every workflow green and pinned

**Priority:** high · **State:** partial: steps 1, 2, 4 and step 3 box 1 on feat; steps 3 (box 2), 5–8 open
**Depends on:** nothing open (the botopink-lang CI fixes are on feat; only a green run remains)
**Owns:** `scripts/check-docs.sh` · the marker lines of `docs.md` and the fence lines after them
(no prose) · botopink-lang `.github/workflows/test.yml` · the meta `.github/workflows/**` and the
meta `AGENTS.md` § CI · the snapshot-capture normalisation for windows · and, for the gate's
residue now that 115, 132 and 133 are closed: `scripts/gate.sh`'s budget lines (`budget_cold`, the
§ budget comment), the vscode-extension workflow's Erlang install, the stale glibc comment in
`repository/rakun/.github/workflows/test.yml`, and the cold-gate record in this README.
**Does not touch:** `docs.md` prose (`../../01-compiler/08-hygiene`) · `build.zig`
(`../../01-compiler/26-cli-tooling`) · any library's hook or test step · `README.md`'s one fence.

## Goal

Every `botopink` fence of `docs.md` and `README.md` is checked (a refusal claim is a `reject` fence),
and every CI workflow the gate relies on is hard, pinned to OTP 28 and green on `feat`. The cold gate
has a recorded green run on the current tip within decision 265's 450 s budget.

## Mechanism

- `check-docs.sh` directives: `reject [body] <expectation>` (the expectation must appear verbatim in
  the first `error` line of a non-zero `botopink check`; one refusal per fence), `project <name>
  <path>` (a scratch project; dependencies resolve by name through `libs/`, `<repo>/..`,
  `<repo>/repository`), `body`. `skip` does not exist; an unknown directive, a directive on a
  non-`botopink` fence (`project` excepted) or a `reject` with no expectation fails. Every run judges
  nine synthetic fences first (`--self-test` runs only them). A table or grammar is ```` ```text ````.
- `test.yml`: matrix `[ubuntu-22.04, macos-14]`, every row runs every step, no `allow_fail` /
  `continue-on-error`, stages after the unit tests built `-Doptimize=ReleaseSafe` (decision 226),
  `test-web` a step and a gate stage (decision 231); the `test` job checks out erika under
  `repository/erika` for `test-docs`. ubuntu-22.04 works because `build.zig` pins glibc 2.35
  (decision 219).
- Meta `hook-integrity.yml`: one job on push/PR to `feat`/`main`, five hard checks (listed in the
  meta `AGENTS.md` § CI and in `../README.md` § Rules).

## Done

- Step 1 — `reject` and `project` replace `skip` (decision 157)
- Step 2 — `scripts/AGENTS.md` § check-docs.sh: `reject` in the directive table, `skip` gone
- Step 3, box 1 — no `allow_fail`, no windows row in `test.yml` (decision 158)
- Step 4 — the meta `hook-integrity` workflow, checks 1–5 green on the remote `feat`

## Open

### Step 3 — the windows row is hard or absent (decision 158)

The row stays deleted until the snapshot capture normalises CRLF and path separators (known gap,
listed in `../../status.md`). To restore it: run the `test` job's steps on a windows runner, list the
failing snapshot tests by cause (CRLF in captured stdout; `\` in captured paths); if the capture can
be normalised in `modules/compiler-core/src/codegen/tests/helpers.zig` without touching an emitter,
do it and restore the row hard, running every stage the ubuntu row runs (`erlef/setup-beam`
supports windows).
- [ ] botopink-lang's `test` workflow green on GitHub on `feat`, every row. The fixes are on feat
      (test-web wasm32, `test-libs.sh` and `run.sh` under macOS bash 3.2 / BSD `xargs`, `pool.sh`
      without GNU `timeout`, macOS `/private/var`); only a green run remains to record
- [ ] (only if a windows runner is available) the drift measured, the capture normalised, the row
      restored hard — otherwise the row stays deleted and the gap carried

### Step 5 — `budget_cold=450` (decision 265)

`scripts/gate.sh` still sets `budget_cold=300` (§ budgets, near `budget_warm=60`) and its budget
comment says "5 minutes cold, 1 minute warm".
- [ ] `grep -n '^budget_cold=' scripts/gate.sh` → `budget_cold=450`; `budget_warm=60` unchanged
- [ ] the header and budget comments say 7m30s cold (decision 265), 5 minutes deferred; over budget
      stays a yellow line, never a red

### Step 6 — the vscode-extension workflow on OTP 28 (decisions 228, 227)

`repository/vscode-extension/.github/workflows/test.yml` (both jobs `ubuntu-22.04`) installs
`apt-get install -y erlang` — ubuntu-22.04's distro release is OTP 24, which the compiler refuses
(`botopink check` evaluates `comptime` through `erl`). Its last green run may predate the OTP check
on feat: a latent red.
- [ ] the install step takes the release from the compiler (`erlef/setup-beam` with the release
      `botopink --version` prints, or `otp-version: '28'` read the way the library workflows read it)
- [ ] `npm test` and `npm run compiler-check` green on GitHub on the remote `feat` after that change

### Step 7 — a cold gate recorded on the current tip

No cold-gate verdict is recorded on any tree that contains `gate-integration-7…14`; the last
recorded green cold gate predates them, and no ~7m30s cold run is recorded (133's last full cold
figure is 9m31s, loaded).
- [ ] `scripts/gate.sh --cold` green on botopink-lang `feat` with every sibling library at its
      `feat` tip; record here the tip, each stage's count against its `--list` plan, the wall clock,
      the CPU-s and the machine's load
- [ ] the wall clock ≤ 450 s on 16 cores, or the over-budget line recorded as printed (yellow, not
      red — decision 265)
- [ ] `../README.md` § Exit check's counts updated to what this run printed

### Step 8 — the gate's other residue

- [ ] 133 step 2's consistency claim completed: every emitted module of every `test-libs` and
      `test-language` cell diffed byte-for-byte between `feat` and the tree before 133's first merge
      (its printed results were diffed, its emitted modules were not); record the diff here — or the
      claim "every cell byte-identical" is withdrawn from `../../status.md`
- [ ] `repository/rakun/.github/workflows/test.yml`'s header comment (glibc 2.38 pin, "ubuntu-22.04
      cannot start") rewritten: the pin is 2.35 since decision 219; the rows stay ubuntu-24.04 and
      macos-14 (no row change)

## Handed out

| Item | To | Why |
|---|---|---|
| `docs.md:5` — "a fence that is not a module … says so in a `docs-check` comment" is stale (a table is ```` ```text ````, no comment) | `../../01-compiler/08-hygiene` (prose) | this front edits fence and marker lines only |
| `build.zig` `test-docs` comment (near `:574`) still describes `<!-- docs-check: skip <reason> -->` | `../../01-compiler/26-cli-tooling` (owner of `build.zig`, decision 219) | not this front's file |

## Blast radius

- `../../01-compiler/08-hygiene` owns `docs.md`'s prose; this front touches fence and marker lines.
- `../../01-compiler/18-comptime-runtimes`' "CI matrix run test.yml" is the same file: there is no
  windows row until step 3's measurement lands.

**Gate:** standard (fronts.md § Gate) + `zig build test-docs` green with `0 skipped`.
