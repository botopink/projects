# v0.beta.20 — close every v0.beta.19 deferral

> v0.beta.19 closed every recorded gap from v0.beta.12 through v0.beta.18
> and shipped `ci-pipelines-green` — which repaired every red workflow in
> the org by walking five layers of pre-existing reds (mlugg/setup-zig v1
> → v2, action @v4 → @v5, vscode-extension `--test` glob, erlang +
> wasmtime install, OTP 27 → 28, `runtime.zig` host-independent RUN LOG,
> wasmtime tarball pin, lib `allow_fail` matrix shapes). The investigation
> uncovered four explicitly-deferred reds and four transitional CI shims
> that need a follow-up pass; alongside, frente-a-compiler shipped a
> partial sweep (§G1+§D1+§D2(BEAM partial)+§B3+§S+§U+§A6) and deferred
> every other section as recorded gaps. v0.beta.20 closes both of these
> tails.

## Scope

| Spec | Slug | Tracks | Files |
|---|---|---|---|
| [frente-a-compiler-tail](specs/frente-a-compiler-tail.md) | `frente-a-compiler-tail` | seven file-disjoint tracks consolidating every v0.beta.19 frente-a-compiler deferral: §B-foundation (generic-inference foundation — Self primitive kind resolution + generic-var instantiation pre-unify) · §B-emit (emit primitive interface instance default fns as bare locals on erlang/beam) · §C-wat-refactor (wat stack-discipline + record field layout + ?. + snapshots) · §C-wasm-test-runner (wire `botopink test --target wasm` once C-wat lands) · §A7-instance-templates (extend codegen on each backend to consume instance template marker) · §D3-D5 (cross-backend parity tail) · §G2 (erika runtime-string DSL form) | `modules/compiler-core/src/comptime/{infer,unify,types,transform}.zig` · `modules/compiler-core/src/codegen/{wat,erlang,beam_asm,commonJS,typescript}.zig` · `modules/compiler-cli/src/cli/test_cmd.zig` · `libs/std/src/primitives.d.bp` · `libs/erika/src/erika.bp` · all touched `AGENTS.md` + `CHANGELOG.md` |
| [ci-pipelines-green-tail](specs/ci-pipelines-green-tail.md) | `ci-pipelines-green-tail` | F0 verify OTP 28 closes the residual snap mismatch · F1 drop the diagnostic `Upload snap .new files` artifact step · F2 drop the now-redundant `ERL_AFLAGS` env on bot-lang test.yml + meta hook-integrity.yml · F3 decide and document the `runtime.zig` stdout-only contract (vs. the legacy `combineOutput` shape) · F4 docs roll (v0.beta.19 status.md `ci-pipelines-green` row → done; this set's status.md gains the row) | `repository/botopink-lang/.github/workflows/test.yml` · `repository/botopink-lang/modules/compiler-core/src/codegen/runtime.zig` · `.github/workflows/hook-integrity.yml` · `tasks/v0.beta.19/status.md` · `tasks/v0.beta.20/{README.md,status.md}` |
| [backends-parity-erlang](specs/backends-parity-erlang.md) | `backends-parity-erlang` | The erlang/beam matrix axes across erika/jhonstart/onze/rakun + bot-lang's own `codegen/erlang/erlang/*.snap.md` are red because the codegen emits user-defined functions whose names shadow auto-imported BIFs (`abs/1`, `length/1`, etc.) — newer OTP erlc treats this as a compile error. Emit `-compile({no_auto_import,[...]}).` for any shadowing function. Remove the lib workflows' `allow_fail: true` on erlang/beam axes once green. Memory: `project_stdlib_backends_parity`. | `repository/botopink-lang/modules/compiler-core/src/codegen/erlang.zig` (emit the directive) · `repository/botopink-lang/modules/compiler-core/src/codegen/beam_asm.zig` (parity) · regenerate every `codegen/erlang/erlang/*.snap.md` + `codegen/beam_asm/beam/*.snap.md` that gains the prelude · each sibling lib's `.github/workflows/test.yml` (drop the erlang + beam allow_fail rows) · meta `tasks/v0.beta.20/status.md` |
| [backends-parity-windows](specs/backends-parity-windows.md) | `backends-parity-windows` | windows-2022 axes are red for two independent reasons: (1) the sibling lib workflows' `run:` step uses the POSIX `${LIB_NAME}` shell-var expansion that PowerShell (windows-2022 default) does not interpret, so the actual command line is `botopink-lib-test --lib  --target commonJS` (empty `--lib`); (2) bot-lang's own `test (windows-2022)` job carries CRLF + path-separator drift in 763 snapshot tests under `compiler-core/parser/tests`, `comptime/tests`, `codegen/tests`. Both fix paths live in the same windows-2022 spec because the snapshot framework's normalisation is the central blocker. | each sibling lib's `.github/workflows/test.yml` (pin `shell: bash` on the lib-test step or pass `LIB_NAME` via `env:` instead of inline) · `repository/botopink-lang/.github/workflows/test.yml` (drop `windows-2022` allow_fail once snapshots normalise) · `repository/botopink-lang/modules/compiler-core/src/utils/snap.zig` (LF-normalise + path-separator normalise before compare) · audit + regenerate any snapshot recorded on a windows host · meta `tasks/v0.beta.20/status.md` |
| [test-libs-consolidation](specs/test-libs-consolidation.md) | `test-libs-consolidation` | After ci-pipelines-green, `scripts/test-libs.sh` now lives in BOTH the meta workspace (`<meta>/scripts/test-libs.sh`) AND inside the bot-lang submodule (`<bot-lang>/scripts/test-libs.sh`). Both copies are byte-identical today but will drift the next time the script is touched. Pick one source of truth (recommended: bot-lang) and update every meta caller + AGENTS.md note that documents the path. | `scripts/test-libs.sh` (delete the meta copy) · `scripts/AGENTS.md` (path note) · every meta entry point that shells out to the wrapper (`grep -rn 'scripts/test-libs.sh'` to enumerate) · meta `tasks/v0.beta.20/status.md` |

## Order

```text
frente-a-compiler-tail    ─▶ independent of every CI spec below.
                              Seven file-disjoint tracks (§B-foundation,
                              §B-emit, §C-wat-refactor, §C-wasm-test-runner,
                              §A7-instance-templates, §D3-D5, §G2).
                              §B-foundation keystones §B-emit and §D3;
                              everything else parallelises freely.

ci-pipelines-green-tail   ─▶ runs first among the CI specs (cleanup of the
                              v0.beta.19 spec's transitional shims; passive
                              on F0 — just wait for the OTP 28 run to land
                              — then F1–F3 are file-disjoint single-line
                              edits).

backends-parity-erlang    ─▶ independent of every other v0.beta.20 spec
                              (touches codegen/erlang.zig + codegen/
                              beam_asm.zig + snapshot regeneration + each
                              sibling lib workflow's allow_fail rows).
                              Cleanest landing pattern: codegen change +
                              snapshot regen in one bot-lang commit; meta
                              sweep the 4 sibling lib pointers + drop the
                              allow_fail rows in one meta commit.

backends-parity-windows   ─▶ independent of every other v0.beta.20 spec.
                              Two halves: (1) sibling-lib shell-var fix is
                              a 4-repo workflow YAML edit landing as 4
                              sibling commits + 1 meta sweep; (2) bot-lang
                              windows snapshot drift is a `snap.zig`
                              normalisation pass + a regen sweep — slower,
                              more files touched, lands separately.

test-libs-consolidation   ─▶ independent of every other v0.beta.20 spec.
                              Single meta commit deleting `<meta>/scripts/
                              test-libs.sh` + the AGENTS.md note update +
                              any meta caller updates. No bot-lang changes
                              (bot-lang already carries the canonical copy).
```

## Goal

After this set lands:

- `ci-pipelines-green-tail` closes: bot-lang `test` + meta `hook-integrity`
  go green on `feat` with **no** diagnostic shims, **no** transitional
  env vars, and the `runtime.zig` contract documented.
- `backends-parity-erlang` closes: every sibling lib's erlang + beam
  matrix axis is green on `feat`; bot-lang's own `codegen/erlang/erlang/*`
  snapshots match without the `allow_fail` markers.
- `backends-parity-windows` closes: every sibling lib's windows-2022
  commonJS axis is green; bot-lang's `test (windows-2022)` axis is green
  without `continue-on-error`.
- `test-libs-consolidation` closes: a single source of truth for the
  test-libs wrapper, no drift risk.
- `gh run list --workflow test --branch feat --limit 1` on every repo
  + `gh run list --workflow hook-integrity --branch feat --limit 1` on
  meta all report `success` **without** any `allow_fail` carve-outs.

## Non-goals (explicit)

- **No new language surface.** Every spec here is a CI / build / codegen
  fix — they close gaps that ci-pipelines-green's investigation phase
  uncovered or formally deferred.
- **No re-architecture of the snapshot framework.** `backends-parity-windows`
  adds normalisation hooks to `snap.zig`; it does not redesign the
  capture/compare contract.
- **No new lib.** test-libs-consolidation moves an existing file; it
  does not introduce a third home for it.
- **No bumping OTP further.** Pin OTP 28 stands. If a future OTP
  tightens the BIF-shadowing diagnostic to an error again, the fix is
  the codegen `-compile({no_auto_import,…})` directive (which
  `backends-parity-erlang` is already authoring), not pinning a
  different OTP version.

## What's NOT in v0.beta.20 (already tracked elsewhere)

For full visibility, these gaps are recorded under other specs / sets
and do not belong in this milestone:

- **frente-a-compiler §A7/§B/§C/§D2-D5/§G2 deferreds** — Frente A
  partial-sweep follow-ups, tracked in `tasks/v0.beta.19/specs/
  frente-a-compiler.md` (open) + the relevant `codegen/AGENTS.md`
  Remaining-gaps rows. v0.beta.20 specs may unblock some of these
  (the erlang BIF directive in particular is a prerequisite for any
  Frente A erlang work), but the closeout commits belong to Frente A.
- **frente-b-rules-tooling Rules track** — effect-annotation ruleset
  (§1/§1F/§1I/§1C/§1G), `tasks/v0.beta.19/specs/frente-b-rules-tooling.md`.
- **std-expansion-tail's 12 deferred std modules** —
  `tasks/v0.beta.19/specs/std-expansion-tail.md` (in progress on its own
  worktree).
- **prim-op-annotation BEAM/commonJS/wat tails** —
  `tasks/v0.beta.19/specs/prim-op-annotation.md` (partial).
- **bpmp §H8 DNS redirect ops step / module-auto-tag J2 fork smoke** —
  deferred to maintainer per the frente-c-distribution closeout (memory:
  `project_v0beta19_frente_c_done`).
- **Generic inference gap** — `project_generic_inference_gap` memory;
  out-of-scope for backends-parity work.

## Set state at kick-off

`ci-pipelines-green` (v0.beta.19) is **substantially landed** but not
yet flipped to `done` — `tasks/v0.beta.19/status.md` carries the
`pending F4 (meta pointer bumps) + F5 (verify)` framing from an earlier
seed. The state at kickoff of v0.beta.20:

- meta `origin/feat` ← `53456cf` (+ a pending follow-up commit bumping
  bot-lang to b6afe7c with OTP 28 — the kickoff commit of this set).
- bot-lang `origin/feat` ← `b6afe7c` (OTP 28 + diagnostic v2 shim still
  present; F1 drops the shim in the first commit of
  `ci-pipelines-green-tail`).
- erika `origin/feat` ← `b26c22f` (allow_fail markers).
- jhonstart `origin/feat` ← `7b87a59`.
- onze `origin/feat` ← `641e344`.
- rakun `origin/feat` ← `d7582cc`.
- vscode-extension `origin/feat` ← `227bc2f`.
