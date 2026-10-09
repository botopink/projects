# Track 00 — the gate: every repository green under its own gate, zero tolerated reds

**Priority:** critical — every later front lands on this baseline.
**Depends on:** nothing. "`00-gate` green" = rules below hold + landing is a green `scripts/gate.sh --cold`.

## Goal

Gate = `repository/botopink-lang/scripts/gate.sh --cold` + each library's `test` workflow and
pre-commit hook + vscode-extension `npm test` / `npm run compiler-check` + meta `hook-integrity`.
All hard, every declared cell green, no red counts as green. Residue: front 114.

## Rules (the gate as it is enforced)

1. **Zero tolerated reds** (decisions 67, 160): red = fixed or test deleted by decision; nothing
   allow-listed, pinned, expected, skipped, soft or bypassable. "skipped" ≠ passed; an
   external-service cell is no gate cell (in-process double).
2. **No ledgers** (153, 154, 161): `scripts/restricted-targets.txt`, `scripts/known-red-libs.txt`,
   `tests/language/expected-failures.txt`, `scripts/known-broken-examples.txt`,
   `--include-unsupported` gone for good.
3. **Manifest `targets` = single source of truth** (153): `test-libs` runs a member on exactly its
   `botopink.json` targets; an existing cell is green or the stage fails. Compiler, `compiler-cli`,
   `lib-test-runner` name no library. rakun erlang-only (113).
4. **Restriction audit** (156): excluding a target (member, `run/<name>.targets`, `modules/<cell>/`
   manifest) needs a host-binding refusal from `botopink build --target <t>` (`has no
   #[@External.<t>]`, `external_missing`). Prints `<A> restrictions audited`; `<X> restrictions not
   structural` fails.
5. **Stages** (`gate.sh` header): 1 staged files, `zig fmt --check modules`, OTP release · 2
   `zig build -Doptimize=ReleaseSafe` · 3 `format-check.sh` · 4 `zig build test` · 4b runtime-parity
   snapshot audit · 5 `test-bpmp` · 6 beam export audit · 7 `test-cli` · 8 `test-libs` · 9
   `test-language` · 10 `test-docs` · 11 `tsc-check.sh` · 12 `test-web` (231). 1–4 serial; 4b–12
   parallel, reported in order. CI builds what the gate builds, ReleaseSafe after unit tests (226).
6. **Cold gate decides every landing** (229, 249, 265): `--cold` deletes the runtime cache and every
   root's `.botopinkbuild/cache/`, runs all, writes passes to the store, never reads it.
   **`budget_cold=450`** (7m30s), `budget_warm=60`, 16 cores; over budget = yellow, never red; no coverage traded for time.
7. **Result store** `.botopinkbuild/cache/results/` (229, 249, 246, 258): warm reuse only on equal
   full key (target, runtime version, SHA-256 of every byte read, compiler sources by backend, every
   root library); no dependency analysis; failures rerun; no persistent runtime process; several
   `--lib` → one report.
8. **All build caches under `<root>/.botopinkbuild/cache/`** (225, 232, 233): erlang verdicts,
   `.beam` cache, cell durations, `cache/lsp/`; nothing in `$HOME`; `botopink clean` deletes
   `.botopinkbuild/`; package under test built from source; no closure cache.
9. **OTP 28 pinned** (228, 227): `OTP_RELEASE` (`modules/manifest/src/root.zig`), printed by
   `botopink --version`; erlang/beam `build`/`run`/`test` refuse another `erl` on `PATH`; manifest
   `"otp"` supported and agreed across a closure; `gate.sh` stage 1 and workflows read it from the
   compiler; macOS library rows install `erlang@28`.
10. **beam in `run.sh --target all`** (`commonJS erlang wasm beam`); prints passed/failed only (154).
    A std module wasm cannot build = located refusal (146, 230, 241).
11. **Format** (155): `scripts/format-check.sh` `TREES` = `examples`, `libs/std`, bundled libraries,
    `compiler-cli/tests`, `manifest/tests`, `tests/language`. Structural exemptions only: hidden
    dirs, `node_modules`, `reject/<n>.bp` beside `<n>.expect`, an unparsable `modules/<cell>/` file
    its `.expect` names. A `.zig` red under `zig fmt --check modules` fails stage 1.
12. **Docs** (157): every `botopink` fence of `docs.md`/`README.md` compiled; refusal = `reject
    <expectation>`, dependency = `project`, table/grammar = ```` ```text ````; no `skip`; nine
    synthetic fences first.
13. **botopink-lang CI** (`test.yml`; 219, 158): `[ubuntu-22.04, macos-14]`, every row every step, no
    `allow_fail` / `continue-on-error`; glibc 2.35 (`build.zig` `libcResolvedTarget`, `objdump -T`);
    no windows row until capture normalises CRLF/separators.
14. **Library CI** (162; emilia, erika, jhonstart, onze, rakun): rows = targets × {`ubuntu-24.04`,
    `macos-14`}, all hard; one `botopink-lib-test --target <t> --strict` from a scratch dir,
    `BOTOPINK_LIB_ROOTS` = the repository, discovery; then the hook's other stages.
15. **Library pre-commit, one text** (161): `scripts/git-hooks/pre-commit`,
    `scripts/git-hooks/lib/runner-standalone.sh` byte-identical across the five. Refuses: no compiler
    / non-executable `BOTOPINK_BIN`, staged `*.snap.new` / `*.snap.md.new`, conflict marker. Runs
    `botopink test --target <t>` per member × target, `botopink build` per example × target and every
    `refusals/*/` case, listing every red. `.gitignore` names both patterns.
    `scripts/git-hooks/repository-stages.sh` runs in a child, only its exit status read: adds reds,
    never removes a stage.
16. **Meta `hook-integrity`** (`.github/workflows/hook-integrity.yml`): the five hard checks of meta
    `AGENTS.md` § CI (submodule pointers on `feat`; § Layout paths; no tracked `*.snap.new` /
    `*.snap.md.new` / `todo.md`; library hook guards, no `known-broken-examples.txt`,
    `core.hooksPath`; `scripts/language-gap-markers.sh` exits 0).
17. **Migrated language rule** (159): `if` is not an operand, parentheses included.

### Exit check

```
$ scripts/gate.sh --cold                # every stage passed, exit 0; each stage's count = its --list plan
test-libs: <N> passed, 0 failed, <M> without tests, <A> restrictions audited
language tests: <X> passed, 0 failed    # --target all
docs: <F> fences — <F> checked, 0 skipped, 0 failed
gate: every stage passed — <w> wall, <c> CPU-s (budget 7m30s cold)
```

Counts re-derived from `--list` before ticking (last: 138 cells = 123 + 15, A = 38; 2061 language
cells; 100 fences). Plus every library's CI and pre-commit, vscode-extension `npm test` /
`compiler-check`, meta `hook-integrity` green on remote `feat`.

Closed in 1.0.11: 99, 100, 101, 108, 109, 110, 111, 112, 113, 115, 131, 132, 133 —
[`../1.0.11-beta/00-gate/`](../../1.0.11-beta/00-gate/README.md).

## Fronts

| Front | Priority | State | What | Depends |
|---|---|---|---|---|
| [`114-gate-docs-and-ci/`](./114-gate-docs-and-ci/README.md) | high | partial: steps 1, 2, 4, 5 on feat; 6 box 1, 8 box 2 on `front/114-16s8`; 3 (box 2), 6 (box 2), 7, 8 (boxes 1, 3), 9 open | docs fences, every CI workflow hard and green, and the gate's residue | — |

Open residue (all 114, see its steps 3, 6–9). **Known gaps:** windows row (decision 158); 5-minute
cold target and idle-machine measurements deferred to next milestone (decision 265).

## Handed out

| Item | To |
|---|---|
| `rakun-websocket` `test/limits_test.bp:48` load-dependent (queue 51 vs cap 50 under load; 27 / 0 idle) | `../04-rakun/` (cap enforcement or the test's bound); unowned in `04-rakun/README.md` § Gate stance |
| `docs.md:5`, `build.zig` `test-docs` comment still describe `docs-check: skip` | `../01-compiler/07-residuals` (step 7) · `../01-compiler/26-cli-tooling` (114 § Handed out) |
