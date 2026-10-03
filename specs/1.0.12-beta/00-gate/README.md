# Track 00 — the gate: every repository green under its own gate, zero tolerated reds

**Priority:** critical — every later front lands against this baseline.
**Depends on:** nothing. A front of another track that says "`00-gate` green" means the rules below
hold on its tree and its landing is a green `scripts/gate.sh --cold`.

## Goal

The gate is `repository/botopink-lang/scripts/gate.sh` run `--cold`, plus each library repository's
own `test` workflow and pre-commit hook, the vscode-extension's `npm test` / `npm run compiler-check`
and the meta repository's `hook-integrity` workflow. Each is hard, every cell it declares is green,
and nothing lets a red count as green. The rules are the baseline; the residue is front 114's.

## Rules (the gate as it is enforced)

1. **Zero tolerated reds.** A red cell is fixed, or its test is deleted by a decision — never
   allow-listed, pinned, expected, skipped or made soft; no flag, variable or list bypasses a rule
   (decision 67). A cell that prints "skipped" has not passed; a cell that needs an external
   service is not a gate cell — its behaviour is asserted against an in-process double (decision 160).
2. **No ledgers.** `scripts/restricted-targets.txt`, `scripts/known-red-libs.txt`,
   `tests/language/expected-failures.txt`, `scripts/known-broken-examples.txt` and
   `--include-unsupported` do not exist and do not come back (decisions 153, 154, 161).
3. **The manifest's `targets` is the single source of truth.** `test-libs` runs a member on the
   targets its `botopink.json` declares and on no other; a cell that exists is green or the stage
   fails. The compiler, `compiler-cli` and `lib-test-runner` name no library (decision 153). rakun
   is erlang-only (decision 113).
4. **The restriction audit.** A member, a `run/<name>.targets` file or a `modules/<cell>/` manifest
   may exclude a target only when `botopink build --target <t>` refuses it with a host-binding error
   (`has no #[@External.<t>]`, `external_missing`); any other outcome refuses the narrowing itself.
   `test-libs` prints `<A> restrictions audited`; `<X> restrictions not structural` fails the run
   (decision 156).
5. **The stages** (`gate.sh` header): 1 staged files, `zig fmt --check modules` on every run, the
   OTP release · 2 `zig build -Doptimize=ReleaseSafe` · 3 `format-check.sh` · 4 `zig build test` ·
   4b runtime-parity snapshot audit · 5 `test-bpmp` · 6 beam export audit · 7 `test-cli` ·
   8 `test-libs` · 9 `test-language` · 10 `test-docs` · 11 `tsc-check.sh` · 12 `test-web`
   (decision 231). 1–4 run in order; 4b–12 run side by side and report in order. CI builds what the
   gate builds, ReleaseSafe after the unit tests (decision 226).
6. **The cold gate decides every landing.** `--cold` deletes the runtime cache and every root's
   `.botopinkbuild/cache/`, runs everything, writes the passes it ran into the result store and
   never reads it (decision 249). Budget **`budget_cold=450`** (7m30s, decision 265) and
   `budget_warm=60` (decision 229) on 16 cores; over budget is a yellow line, never a red, and no
   coverage is traded for time.
7. **The cell-result store** lives under `.botopinkbuild/cache/results/`. A warm run answers a cell
   from a stored pass only when its full content key is equal: target, runtime version, the SHA-256
   of every byte the cell reads, the compiler's sources partitioned by backend (shared sources in
   every key, a backend's emitter only in its cells' keys) and every library of the roots
   (decisions 229, 249, 246). No dependency analysis decides what to skip; failures always run; no
   runtime process persists across cells or runs. Several `--lib` all run, one report (decision 258).
8. **Every build cache under `<root>/.botopinkbuild/cache/`** (`<root>` the workspace root, else
   the project root): the erlang verdicts, the `.beam` cache, the cell durations, the language
   server's (`cache/lsp/`). Deleting `.botopinkbuild/` leaves nothing in `$HOME`; `botopink clean`
   deletes it whole; the package under test is always compiled from its sources; no closure cache is
   built (decisions 225, 232, 233).
9. **OTP 28, pinned.** One constant (`OTP_RELEASE`, `modules/manifest/src/root.zig`), printed by
   `botopink --version`; `build`/`run`/`test` on erlang or beam refuse another `erl` on `PATH`; a
   manifest's `"otp"` must be a release the compiler supports and agree across a closure; `gate.sh`
   stage 1 and every workflow take the release from the compiler; macOS library rows install
   `erlang@28` (decisions 228, 227).
10. **beam is in `run.sh --target all`** (`commonJS erlang wasm beam`); `run.sh` prints passed and
    failed only — a red language cell is red (decision 154). A std module wasm cannot build is a
    located refusal (decisions 146, 230, 241).
11. **Format.** `scripts/format-check.sh` `TREES` covers every tracked `.bp`: `examples`, `libs/std`
    and the bundled libraries, `compiler-cli/tests`, `manifest/tests`, `tests/language`. The only
    exemptions are structural — hidden directories, `node_modules`, `reject/<n>.bp` beside its
    `<n>.expect`, a `modules/<cell>/` file the cell's `.expect` names that does not lex or parse
    (decision 155). Any `.zig` red under `zig fmt --check modules` fails stage 1.
12. **Docs.** Every `botopink` fence of `docs.md` and `README.md` is compiled; a refusal claim is a
    `reject <expectation>` fence, a dependency is a `project` fence, a table or grammar is
    ```` ```text ````; `skip` does not exist; nine synthetic fences are judged first (decision 157).
13. **botopink-lang CI** (`test.yml`): rows `[ubuntu-22.04, macos-14]`, every row runs every step,
    no `allow_fail` / `continue-on-error`. The binary's glibc pin is 2.35 (`build.zig`
    `libcResolvedTarget`; `objdump -T` lists nothing newer — decision 219). No windows row until
    the snapshot capture normalises CRLF and path separators (decision 158).
14. **Library CI** (emilia, erika, jhonstart, onze, rakun): rows = the manifests' targets ×
    {`ubuntu-24.04`, `macos-14`}, every row hard, no row for a target `botopink test` cannot run;
    one `botopink-lib-test --target <t> --strict` from a scratch directory with
    `BOTOPINK_LIB_ROOTS` naming the repository, every member and every example through discovery;
    then the hook's other stages (decision 162).
15. **Library pre-commit — one text.** `scripts/git-hooks/pre-commit` and
    `scripts/git-hooks/lib/runner-standalone.sh` are byte-identical in the five libraries. The hook
    refuses when the compiler is absent or `BOTOPINK_BIN` is not executable, refuses a staged
    `*.snap.new` / `*.snap.md.new` or a conflict marker, and runs `botopink test --target <t>` in
    every member on every declared target, `botopink build` of every example on every declared
    target and every `refusals/*/` case, listing every red. `.gitignore` names both candidate
    patterns. `scripts/git-hooks/repository-stages.sh` runs in a child whose exit status is all the
    runner reads: it can add a red, never remove a stage (decision 161).
16. **Meta `hook-integrity`** (`.github/workflows/hook-integrity.yml`, the meta `AGENTS.md` § CI),
    five hard checks: (1) every submodule pointer is on its remote `feat`; (2) every § Layout path
    exists; (3) no tracked `*.snap.new`, `*.snap.md.new` or `todo.md` in the meta repo or any
    submodule; (4) the five libraries' hook and runner byte-identical, `.gitignore` guards present,
    no `known-broken-examples.txt`, `AGENTS.md` names `core.hooksPath`; (5)
    `scripts/language-gap-markers.sh` exits 0.
17. **The language rules the libraries were migrated to:** `if` is not an operand, parentheses
    included (decision 159).

### Exit check

```
$ scripts/gate.sh --cold                # every stage passed, exit 0; each stage's count = its --list plan
test-libs: <N> passed, 0 failed, <M> without tests, <A> restrictions audited
language tests: <X> passed, 0 failed    # --target all
docs: <F> fences — <F> checked, 0 skipped, 0 failed
gate: every stage passed — <w> wall, <c> CPU-s (budget 7m30s cold)
```

Counts are re-derived from `--list` before a box is ticked (last counted: 138 cells = 123 + 15,
A = 38; 2061 language cells; 100 fences). Each library's own CI and pre-commit green on its remote
`feat`, vscode-extension's `npm test` and `compiler-check` green, meta `hook-integrity` green.

Closed in 1.0.11: 99, 100, 101, 108, 109, 110, 111, 112, 113, 115, 131, 132, 133 — history in
[`../1.0.11-beta/00-gate/`](../../1.0.11-beta/00-gate/README.md).

## Fronts

| Front | Priority | State | What | Depends |
|---|---|---|---|---|
| [`114-gate-docs-and-ci/`](./114-gate-docs-and-ci/README.md) | high | partial: steps 1, 2, 4 on feat; 3 (box 2), 5–8 open | docs fences, every CI workflow hard and green, and the gate's residue | — |

The open residue, all front 114's:

- Step 3 — botopink-lang's `test` workflow green on GitHub on `feat` (the fixes are on feat; only a
  green run remains); windows row restored only after the CRLF / path-separator normalisation.
- Step 5 — `scripts/gate.sh` still says `budget_cold=300`; decision 265 says 450.
- Step 6 — vscode-extension's `test.yml` installs distro Erlang on ubuntu-22.04 (OTP 24, not 28).
- Step 7 — no cold-gate run recorded on a tree containing `gate-integration-7…14`.
- Step 8 — 133's emitted modules not yet diffed; rakun's workflow comment still cites the glibc
  2.38 pin (decision 219 made it 2.35).

**Known gaps.** The windows row stays deleted until the snapshot capture normalises CRLF (decision
158). The 5-minute cold target and its idle-machine measurements are deferred to the next milestone
(decision 265).

## Handed out

| Item | To |
|---|---|
| `rakun-websocket` `test/limits_test.bp:48` is load-dependent (an outbound queue of 51 against a cap of 50 under load; 27 / 0 idle) — a red the gate can meet | `../04-rakun/` (the cap's enforcement in the websocket runtime, or the test's bound); no 04-rakun front carries it yet |
| `docs.md:5` and the `build.zig` `test-docs` comment still describe `docs-check: skip` | `../01-compiler/08-hygiene` · `../01-compiler/26-cli-tooling` (114 § Handed out) |
