# Fronts — 1.0.4-beta: who owned what

A closed milestone has no schedule. What this file kept from the scheduling tool it used to be is the
part that stays useful: **which front owned which files**, the items no front owned and what closed
them, and the map from the old front numbers the carried deep dives cite.

A front was one worktree (`.tasks/<name>`), one branch, one `todo.md`, one owner. Two fronts could
run at the same time only when they shared **no source file and no snapshot directory** — the rule
that produced the ownership table below, and the reason the two fronts that owned
`modules/compiler-core/src/**` wholesale (12, then 06) each ran alone.

Paths are relative to `repository/botopink-lang/modules/compiler-core/` unless a row says otherwise;
`cli/`, `modules/`, `libs/`, `scripts/`, `build.zig` and `.github/` are relative to
`repository/botopink-lang/`, and `repository/<lib>` names a sibling repository.

## Ownership

| Front | Source it owned | Snapshots it owned |
|---|---|---|
| **01** [`backend-residuals`](./01-backend-residuals/README.md) | `src/codegen/beam_asm.zig`, `src/codegen/beam/**`, `src/codegen/erlang.zig`, `src/codegen/wat.zig`, `src/codegen/wat/**`, `src/codegen/commonJS.zig`, `src/codegen/typescript.zig`, `src/codegen/js/**`, `src/codegen/runtime.zig` (note 2) · the `KNOWN` notes and new fixtures of its rows in `src/codegen/tests/**` (carve-out) | `snapshots/codegen/{beam,erlang,wasm,commonJS}/` |
| **05** [`cli-residuals`](./05-cli-residuals/README.md) | `modules/compiler-cli/**`, `modules/lib-test-runner/**`, `build.zig`, `.github/workflows/**`, `scripts/**` except `scripts/snap_audit.sh` | — |
| **06** [`checker`](./06-checker/README.md) | `src/comptime/{infer,types,env,unify,transform,eval,error}.zig` · `src/parser/{decls,exprs,patterns}.zig` · `src/lexer.zig` and `src/lexer/**` | `snapshots/comptime/**`, and it could move **all four** codegen directories and the LSP completion snapshots |
| **07** [`comptime-dedup`](./07-comptime-dedup/README.md) | `src/comptime/snapshot.zig`, `src/comptime/tests/helpers.zig` | `snapshots/comptime/**` (layout) |
| **08** [`review-backlog`](./08-review-backlog/README.md) | `src/utils/snap.zig`, `scripts/snap_audit.sh`, `src/codegen/tests/**`, `src/comptime/tests/**`, `src/parser/tests/**`, `modules/language-server/src/tests/**` (minus the carve-outs of 01 and 07) · the status lines of the 1.0.1-beta reports (meta repo) · the decision references | — (moves a snapshot only by renaming its test) |
| **09** [`hygiene`](./09-hygiene/README.md) | `src/comptime/runtime/persistent_erl.zig` · `modules/lib-test-runner/build.zig` + `.zon`, `build.zig`'s `test-vscode` step · `libs/std/botopink.json`, `libs/std/AGENTS.md` · `examples/**`, `README.md`, `docs.md`, every `AGENTS.md`, comments (after their owners) | — |
| **10** [`library-repos`](./10-library-repos/README.md) | `repository/erika/**`, `repository/emilia/**`, the `BOTOPINK_LANG_REF` line in `repository/{jhonstart,onze}/.github/workflows/test.yml` | — |
| **11** [`dead-keywords-residual`](./11-dead-keywords-residual/README.md) | `repository/jhonstart/src/{router,server}.d.bp` and their call sites · `repository/vscode-extension/syntaxes/botopink.tmLanguage.json` (the keyword pattern only) | — |
| **12** [`surface-cutover`](./12-surface-cutover/README.md) | `modules/compiler-core/src/**`, `modules/language-server/src/**` (compile-level), `cli/resolver.zig`, `libs/std/**`, `examples/**` | `modules/compiler-core/snapshots/**`, LSP snapshots |
| **13** [`ecosystem-migration`](./13-ecosystem-migration/README.md) | `repository/{emilia,erika,jhonstart,onze,rakun}/**`; their meta submodule pointers | the libraries' own test outputs |
| **14** [`tooling-and-docs`](./14-tooling-and-docs/README.md) | `modules/language-server/src/**` (user-facing texts, completions, symbol kinds, completion in a non-compiling file, the project graph's own diagnostics), `repository/vscode-extension/**` | LSP hover/completion/symbol snapshots |
| **15** [`language-tests`](./15-language-tests/README.md) | `tests/language/**` (new) · the `test-language` step in `build.zig` · its stage in `scripts/gate.sh` | — |
| **17** [`language-test-expansion`](./17-language-test-expansion/README.md) | `tests/language/**` (the new cells) · the lines it added to `tests/language/expected-failures.txt` | — |
| **20** [`cli-residuals-ii`](./20-cli-residuals-ii/README.md) | `modules/compiler-cli/**` **except** `src/cli/{build,run}.zig` · `modules/lib-test-runner/**` where a fix needed it | — |

Two carve-outs and one hand-off shaped most of the boundaries, and they are worth keeping:

1. **`src/codegen/runtime.zig` was 01's.** A change to it bumps `HARNESS_VERSION` in the same commit.
2. **08 owned the test sources** that 01, 06 and 07 add fixtures to; 01's `KNOWN` notes were carved
   out of it, and 07 edited `comptime/tests/helpers.zig` first.
3. **`libs/std/**` had no owner until 12.** A fix that needed a `libs/std` edit stopped and reported,
   and the maintainer assigned it per case — std-split `c8c2541` was one. From 12 onwards it is
   ordinary owned source.

`scripts/known-red-libs.txt` is empty and each library's `scripts/known-broken-examples.txt` is
empty: no cell and no example is carried red.

## Order, as it ran

The milestone was planned as 01–10, then 12–14. The maintainer reordered it once, on 2026-09-17, to
run **12 before 06** — so the checker wrote its rules on the unified AST once instead of porting them
twice, and 12's decision-8 source migration moved to 06's step 9.

```
01 steps 1–4 · 05 · 10 · 11 ─── first
12 surface-cutover (alone on compiler-core/src, libs/std, examples)
        │                       09 fix/hygiene-build beside it
        ▼
15 language-tests ──► 13 ecosystem-migration · 14 tooling-and-docs · 17 language-test-expansion
        │
        ▼
06 checker ── the five groups that landed · 20 cli-residuals-ii beside it
        │
        └─► 09's three comment sweeps, each after the front that owned the swept file
```

01's steps 5–6, 07 and 08's two waves never opened; they are 1.0.5-beta's.

<a id="unowned-items"></a>

## Unowned items closed during 1.0.4-beta

Each was found by a front and owned by none, and each needed the maintainer to assign it. These are
the ones that closed.

| Item | Found by | Closed by |
|---|---|---|
| `Array.chunked` / `Array.sliding` were written with `while`, which checked code rejects as not in scope — **decided 2026-09-17: rewrite them with `loop (condition)`** | 1.0.4-beta erlang | 06 G0, `cab0bf7` — both are `loop (0..n)` now |
| `delegate` and `new` stop being keywords (`throw Error(…)`, not `throw new Error(…)`); the unmapped `.@"const"` token variant is deleted; the VS Code grammar stops highlighting them — **decided 2026-09-17** | 1.0.4-beta 11 | 06 N27, `cab0bf7` (lexer/parser) + vscode-extension `a1216f5` (grammar) |
| `hover_interface_method` — should the hover footer name the declaring interface or the receiver's? | 1.0.2-beta review-tooling (report 3.12) | 14, `dfc34a9`: `*from `behavior Signed` (via I32)*`, and `*from `behavior Array`*` when the declaring behavior is the receiver's |
| A missing dependency (`:171`) and an unreadable `files` entry (`:210`) swallowed by the language server with `catch continue` | 1.0.2-beta library-repos, re-confirmed by 05 | 14, `84e493a`: both are diagnostics on the manifest that declares the entry, with the CLI's wording |
| `libs/std`: `String.split("")` on erlang, and the `builtins.d.bp` `@print` doc | 1.0.4-beta erlang | std-split `c8c2541`, a one-off `libs/std` edit the maintainer assigned |
| rakun's records are not exported (`exports.Rakun`) | 1.0.2-beta library-repos | 1.0.4-beta js-bridges `aa02bb4`, verified by 10 step 4 |
| `$0` versus `$self` in `#[@External…]` templates | 1.0.2-beta std-surface | [decision 5](./08-review-backlog/semantics-decisions.md#decision-5), implemented by 12 step 3 (`c5b156a`) |
| **`MissingExternalTarget` has no location and no function name** — the CLI printed only the error name | 13's erlang-cells investigation | 06 C13, `7b1db40`: it names the function, the backend and the call site, and the module fails alone instead of aborting the build |
| **A library cannot ship an erlang host module** (`.erl`), only `.mjs` sidecars | 13's erlang-cells investigation | 20 step 3, `c01695f` — `libs.shipErlSidecars`, wired into `botopink test` |
| **Labels are lost when a generic labeled return is instantiated** — `fn ref<T>() -> #(current: T)`, then `r.current` | 13 jhonstart migration | 06 N24, `174e0e4`: `instantiateType` carries `n.labels` |
| **A tuple label of function type called as a method** (`#(value: i32, set: fn(…))`, `c.set(9)`) is not rewritten to positional | erlang-calls fix | 06 N24, `174e0e4`: `inferTupleLabelCall`, lowered on commonJS, erlang and beam |
| **A tuple label does not resolve on a lambda parameter or an array element** | 13 erika migration | **struck by probe** with 06 N24: both check at that base. The spelling `#(a: i32, b: string)[]` does not parse — the array-suffix grammar, carried |
| **erlang: a host-backed `declare fn` with an inline template, used from another module, has nothing to call** — kept onze and rakun red on erlang | erlang-calls fix, 2026-09-17 | `84a944b` (`063e16b`): the owner emits a wrapper with the template applied to its own parameters |
| Erlang cells after the 2026-09-17 investigation | 13 | emilia 17/17 (`8f93475`, CI `e30228f`), erika 31/31 as a hard cell (`81e1f1c`), onze green (`4707c83`, `c4098c3`), jhonstart 8/8 (`4b85b43`). rakun's cell is still skipped, for its own reason |

## Unowned items still open

They leave with the milestone. **1.0.5-beta's `fronts.md` carries them**, each against the front that
now owns the file — the checker's rows in `01-checker`, the run-time rows split per backend across
`02-erlang` / `03-beam` / `04-js` / `05-wasm`, the test-source rows in `07-review-backlog`, the sweeps
in `08-hygiene`, the library re-tests in `09-ecosystem-residuals`, the CLI rows in `10-cli-residuals`,
and the language-server and Test Explorer rows in `11-tooling`. Each front's own
**"What it left, and where"** section names the ones it found.

<a id="old-front-numbers"></a>

## Old front numbers

The carried deep dives cite fronts by their old numbers. Map them here.

| Old | Name | In 1.0.4-beta |
|---|---|---|
| 1.0.2-beta F1 | comptime-dispatch | **delivered** (steps 1, 2; the beam half of step 2 with 1.0.4-beta beam); step 3 → 06 N1, carried |
| 1.0.2-beta F2 | cli-gate | **delivered**; residuals → [`05-cli-residuals`](./05-cli-residuals/README.md), **delivered** |
| 1.0.2-beta F3 | std-surface | **delivered**; its backend residuals delivered with 1.0.4-beta beam, erlang, js-bridges; 05 step 5; its `external-annotations.md` → [`06-checker`](./06-checker/external-annotations.md) |
| 1.0.2-beta F4 | beam | = 1.0.4-beta first 01 beam, **delivered** `a743955` |
| 1.0.2-beta F5 | erlang | = 1.0.4-beta 02 erlang, **delivered** `42429dc` |
| 1.0.2-beta F6 | wasm | = 1.0.4-beta 03 wasm, **delivered** `ed15323` |
| 1.0.2-beta F7 | checker | [`06-checker`](./06-checker/README.md) — five groups delivered, the rest → 1.0.5-beta `01-checker` |
| 1.0.2-beta F8 | js-bridges | = 1.0.4-beta 04 js-bridges, **delivered** `bd7836c` |
| 1.0.2-beta F9 | review-tooling | steps 1–3 **delivered**; step 4 → [`08-review-backlog`](./08-review-backlog/README.md), carried |
| 1.0.2-beta F10 | comptime-dedup | [`07-comptime-dedup`](./07-comptime-dedup/README.md) — never started → 1.0.5-beta `06-comptime-dedup` |
| 1.0.2-beta F11 | hygiene | [`09-hygiene`](./09-hygiene/README.md), **delivered** |
| 1.0.2-beta F12 | library-repos | [`10-library-repos`](./10-library-repos/README.md), **delivered** |
| 1.0.4-beta 01–04 (until 2026-09-17) | beam, erlang, wasm, js-bridges | **delivered**; the handoff ids (`B…`, `E…`, `W…`, `C…`, `JS-…`, `H…`) the carried documents cite are closed unless [`01-backend-residuals`](./01-backend-residuals/README.md) names them (`BR5`, the `D8-…` rows) |
| 1.0.3-beta F1 | dead-keywords | **delivered** (compiler half `ecac19d`, then [`11-dead-keywords-residual`](./11-dead-keywords-residual/README.md)) |
| 1.0.3-beta F2 | surface-cutover | [`12-surface-cutover`](./12-surface-cutover/README.md), **delivered** |
| 1.0.3-beta F3 | ecosystem-migration | [`13-ecosystem-migration`](./13-ecosystem-migration/README.md), **delivered** |
| 1.0.3-beta F4 | tooling-and-docs | [`14-tooling-and-docs`](./14-tooling-and-docs/README.md), **delivered** |

## Rules a front ran under

Kept because the carried documents assume them.

- One worktree under `.tasks/<front>`, one branch `fix/<front>`, a git-ignored `todo.md` at its root
  carrying the steps, the owned and forbidden paths, and the exit gate.
- **A front never edits a file it does not own.** If a fix needs one, it stops and reports.
- The gate before landing: `scripts/gate.sh --cold` (zig build, cold `zig build test`, `test-cli`,
  `test-libs`, `test-language`, `test-docs`) green in the front's own worktree.
- Landing: merge into `feat`, gate green in the main checkout, push, submodule bump in the meta repo
  — for a front that commits in a sibling repository, push that repository in the same sweep — then
  delete the worktree and the branch.
- A refactor front lands **snapshot-byte-identical**; a fix front re-records only values it verified
  by running the program.
