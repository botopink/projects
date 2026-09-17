# Specs — 1.0.4-beta

Two milestones folded into one. **First, the correctness work 1.0.2-beta left open**: the backend
residuals, the checker, the comptime snapshot layout, the review backlog, hygiene, and the CLI and
library residuals. **Then the 1.0.3-beta surface cutover**: `record`/`enum` become `type`,
`interface` becomes `behavior`, the anonymous record becomes a tuple, and the dead keywords' last
traces leave the ecosystem. 1.0.3-beta's entry criterion — "1.0.2-beta is closed" — carries over as
**fronts 01–10 are closed before 12–14 start**: the cutover rewrites the source of ~700 snapshots and
touches every file the correctness fronts own.

**[Decision 8](./08-review-backlog/decision-8-language.md)** (2026-09-17) is the language design both
halves implement: written generic types carry all their arguments (`Self<T>` included), the
`unknown` and union types, `is` testing values, `case` arms as `Pattern { n -> … }` with `when`
guards, tuple labels as compile-time names, one source-shaped formatter per type, `#[@result] …
-> @Result<T, E>`, and `loop (condition)` instead of `while`. The checker half is
[`06-checker`](./06-checker/README.md) N18–N26, the run-time half
[`01-backend-residuals`](./01-backend-residuals/README.md) step 6, the source migration 12 and 13.

The work was cut into **eleven fronts**, numbered in execution order: 01 and 05–14. Fronts 02–04
landed with the first 01 and their numbers are retired. **05, 10 and 11 are delivered**; 01 is
delivered except two steps that run after 06.
[`fronts.md`](./fronts.md) holds the ownership table, the conflict matrix, the items no front owns,
and the map from the old front numbers the carried deep dives cite.

**Naming.** "1.0.2 surface" and "1.0.3 surface" in the carried cutover documents
([`EXAMPLES.md`](./EXAMPLES.md), [`MIGRATION.md`](./MIGRATION.md), fronts 11–14) name the old and the
new syntax. Both milestones ship as 1.0.4-beta.

## Delivered before this milestone

Verified against `botopink-lang` `origin/feat`: the 1.0.2-beta and 1.0.3-beta rows at `0552e32`
(2026-09-16), the four 1.0.4-beta backend rows at `ed15323`, and the rows landed later on 2026-09-17 at
`b4cf700`. Not to redo; what each left is carried into the front named.

| Was | Delivered | Left, and where it went |
|---|---|---|
| 1.0.2-beta **comptime-dispatch** | steps 1–2: primitive methods reachable from template and decorator bodies through a dispatch shim built from the typed table; mutation through a method inside a closure threads out on erlang | step 3 (trailing defaults, never executed) → [`06-checker`](./06-checker/README.md) N1; the beam half of step 2 — delivered with 1.0.4-beta beam |
| 1.0.2-beta **cli-gate** | `build`/`check`/`test` fail on a module that does not compile; contract C1–C14 written and tested; `zig build test-cli`; `scripts/gate.sh [--cold] [--staged]`; `scripts/install-hooks.sh`; `test-libs` over every checked-out library with `scripts/known-red-libs.txt`; a CI libs job; the mutation matrix run | the execute flag, diagnostics through `codegenEmit`, located parse/lex errors, the decorator-test tightening, hook installation, `test-bpmp` and `lib-test-runner` in the gate → [`05-cli-residuals`](./05-cli-residuals/README.md) |
| 1.0.2-beta **std-surface** | all seven steps: `pick` shadowing, `./gleam_stdlib.mjs` removed (interface methods bound to native JS, slice helpers as inline templates; no helper mechanism yet), template-only imports, `string:suffix/2`, the manifest, `reflect.bp`/`types.bp` deleted, `primitives.bp`'s tests in `libs/std/test/primitives_test.bp` + `primitives_gaps_test.bp` (each gap named) | `Signed.abs` from an `i32`, the `String.charAt` helper, cross-module template exports — delivered with 1.0.4-beta beam, erlang, js-bridges; the `files` diagnostic → 05 step 5; the `$0`/`$self` naming → [`fronts.md` § unowned items](./fronts.md#unowned-items); `external-annotations.md` → 06 |
| 1.0.2-beta **review-tooling** | steps 1–2 (`BOTOPINK_SNAP_TRACE`, `snap_audit.sh --mode=orphans\|review`; 0 orphans of 2451); step 3 — the four semantics decisions, **decided 2026-09-16, every recommendation accepted**; step 4 for reports 3.3, 3.6, 3.11, 3.12 | reports 3.1, 3.2, 3.4, 3.5, 3.7–3.10 → [`08-review-backlog`](./08-review-backlog/README.md); each decision's implementation → the handoffs named in [`semantics-decisions.md`](./08-review-backlog/semantics-decisions.md) |
| 1.0.2-beta **hygiene** | step 1: the comptime frame protocol (logger off `standard_io`, own group leader, 16 MiB frame cap, `erl.stderr.log` as a write-only debug log, the server built in a hashed dir and renamed into place; `meta:erl_crash.dump` deleted) | steps 2–6 → [`09-hygiene`](./09-hygiene/README.md) |
| 1.0.2-beta **library-repos** | 7a rakun (vendored http transport, 17/17), 7e/7f/7g vscode-extension, 7h bpmp (108/108) | erika 7b/7c, emilia 7d, two `BOTOPINK_LANG_REF` defaults, rakun's exports → [`10-library-repos`](./10-library-repos/README.md) |
| 1.0.4-beta **erlang** (first 02) | merge `42429dc`: E1 map patterns, E2 `__bp_text/1`, E4 `try`/`catch`, E5 + the 7 value `raw` sites, E6, E7, steps 8–9; decisions 1 and 4; erika 7b; closure var threading; std erlang green; operand-proven `+`, float `/`, `Signed.abs` | E8 (`#[@result]` wrap) → [`06-checker`](./06-checker/README.md#step-0--rows-added-in-104-beta) N10; methods on associated-fn results → 06 N15; `String.split("")`, the `builtins.d.bp` `@print` doc, `chunked`/`sliding` → [`fronts.md` § unowned items](./fronts.md#unowned-items) |
| 1.0.4-beta **js-bridges** (first 04) | merge `bd7836c`: `node --check` block, C3–C5, JS-1/2/3/5/6, `while` lowering, `pub` template externals, on-demand helpers (`charAt`), `externals.zig` off `gleam_stdlib.mjs`, `.d.ts` surface, decision 4 | range start, open range, `break` comprehensions, the four 1.0.3-beta example rows (unclaimed) → [`01-backend-residuals`](./01-backend-residuals/README.md) step 3; JS-4 → 06 N11; value-less `if` and `loop_break_with_value` → 06 N6/N12 |
| 1.0.4-beta **beam** (first 01) | merge `a743955`: B1–B9, B11, B12, `beam_export_audit.sh` 290/290, the `.S` preamble through the emitter, decisions 1 and 4, register clobbering, loop/`forEach` threading, enum tag tests, `Signed.abs` | closure/loop/untyped-`+` fixtures and the `__bp_erl_eval` review → 01 step 1; the audit in the gate → [`05-cli-residuals`](./05-cli-residuals/README.md) step 6; unbound names, folded arrays, `run`/`use effect` arity → 06 N13, N5, N14 |
| 1.0.4-beta **wasm** (first 03) | merge `ed15323`: trap block, W1 (unresolved calls 59 → 3), **`executeWat` executes**, W2–W11 (W7 per decision 3), `Module.externs`/`emitFnWat` deleted, decision 4; 143 snapshots gained a real RUN LOG | closure/loop/untyped-`+`, the tuple printer, 3 unresolved calls → 01 step 2; stale comments outside its files → [`09-hygiene`](./09-hygiene/README.md) step 2 |
| 1.0.3-beta **dead-keywords** | the compiler side, `botopink-lang` `ecac19d` | jhonstart's accessors and the VS Code grammar → delivered with 1.0.4-beta 11 |
| 1.0.4-beta **01 backend-residuals**, steps 1–4 | merges `00b8975` beam (BR1–BR3, BR4 reviewed, audit 295/295), `4eadb70` wasm (WR1–WR3, WR5), `dbe2863` commonJS (CR1, CR2, CR4; CR3 struck), `b4cf700` step 4 (decision 1a on commonJS, erlang, wasm) | BR5 (beam compiles `@External.Erlang` templates at build time) → 01 step 5, after 06; decision 8's run time, including the beam formatter → 01 step 6, after 06 |
| **std-split** (unowned item) | `c8c2541`: `String.split("")` answers every character on erlang; `builtins.d.bp` documents `__bp_print/1`; the three known-red library cells deleted | `Array.chunked`/`sliding` rewritten with `loop` → [`fronts.md` § unowned items](./fronts.md#unowned-items) |
| 1.0.4-beta **05 cli-residuals** | merge `440a1d3`: the execute flag, a failed module carries its diagnostic in `ModuleOutput`, located lex/parse errors, the decorator mutation matrix, a missing `files` entry located, `test-bpmp` + `beam_export_audit.sh` + lib-test-runner units in the gate, the self-contained hook (`core.hooksPath scripts/git-hooks`), `gate.sh` clears `GIT_DIR` | the language-server half of the missing dependency → [`fronts.md` § unowned items](./fronts.md#unowned-items); `helpers.zig` reading the failed-module diagnostic → [`08-review-backlog`](./08-review-backlog/README.md) |
| 1.0.4-beta **09 hygiene**, step 3 + decisions | merge `e98a5da` (dead module build files and root test stubs deleted, `erl.stderr.log` documented); `meta:build.zig` deleted; 5.5a (no meta gate — its dangling hook deleted), 5.5b (a self-contained hook per repo), 5.9 (MIT, `LICENSE` in the seven code repos, `botopink-lang` `af9b5b6`) | steps 2, 4, 5 and 5.4 → [`09-hygiene`](./09-hygiene/README.md) |
| 1.0.4-beta **10 library-repos** | erika `051cd97` (7b verified, 7c), emilia `321981d` (hook + CI), jhonstart `8668c40` and onze `2fcf860` (`BOTOPINK_LANG_REF` → `feat`), rakun's `exports.Rakun` verified; then every library builds its examples in its gate (erika `17728e3`, emilia `a167c06`, jhonstart `6c807d1`, onze `cda9d01`, rakun `d5ca84b`; jhonstart's `jonhstar` leftover deleted) | the examples listed in each `scripts/known-broken-examples.txt` (emilia `emilia-card`; jhonstart `-counter`, `-html`, `-todo`) → [`13-ecosystem-migration`](./13-ecosystem-migration/README.md) |
| 1.0.4-beta **11 dead-keywords-residual** | jhonstart `bf868ca` (`get` accessors are methods), vscode-extension `eb870ac` (the grammar drops the seven words) | `delegate`, `new`, `.@"const"` stop being keywords → [`06-checker`](./06-checker/README.md) + [`14-tooling-and-docs`](./14-tooling-and-docs/README.md) |

Library gate at `botopink-lang` `b4cf700` (`zig build test-libs`): every checked-out library cell
passes, `scripts/known-red-libs.txt` has no line. Each library's own hook and CI also build its
examples; the ones that do not compile are listed in its `scripts/known-broken-examples.txt` until 13.

## Fronts

| Front | Priority | State | What |
|---|---|---|---|
| [`01-backend-residuals`](./01-backend-residuals/README.md) | medium | steps 1–4 **delivered**; 5–6 after 06 | Open: step 5 — beam compiles `@External.Erlang` templates at build time (BR5; a partial start in `.tasks/beam-templates`); step 6 — [decision 8](./08-review-backlog/decision-8-language.md) at run time on the four backends (`is`, `unknown`/unions, `case` arms, tuple labels, the formatter, `loop (condition)`) |
| [`05-cli-residuals`](./05-cli-residuals/README.md) | medium | **delivered** | — |
| [`06-checker`](./06-checker/README.md) | high | after 12 | C1–C13: the checker accepts wrong programs. Plus trailing defaults, decision 2, the `#[@result]` wrap, binding patterns, and the rows found since (N1–N26), including decision 8's checker half, `while`, `new`/`delegate` |
| [`07-comptime-dedup`](./07-comptime-dedup/README.md) | medium | not started | Four byte-identical copies per comptime slug; a renderer that prints `?` and `"id": 0` |
| [`08-review-backlog`](./08-review-backlog/README.md) | medium | steps 1–3 delivered; decisions 1–8 taken | The per-report residuals of the 1.0.1-beta snapshot review, in two waves |
| [`09-hygiene`](./09-hygiene/README.md) | low | steps 1, 3 (except 5.4) and 6 delivered | The removed WAT runtime's leftovers (step 2), `libs/std`'s declared surface (4), retired vocabulary (5), `test-vscode` (5.4), the lib-test-runner build files |
| [`10-library-repos`](./10-library-repos/README.md) | medium | **delivered** | — |
| [`11-dead-keywords-residual`](./11-dead-keywords-residual/README.md) | low | **delivered** | — |
| [`12-surface-cutover`](./12-surface-cutover/README.md) | critical | **delivered** | `type`, `behavior`, tuples and separators through the whole compiler, `libs/std`, every test source and snapshot; decision 5's markers and decision 8's source migration |
| [`13-ecosystem-migration`](./13-ecosystem-migration/README.md) | high | not started | emilia, erika, jhonstart, onze, rakun migrated to the new surface and to decision 8; the known-broken examples fixed |
| [`14-tooling-and-docs`](./14-tooling-and-docs/README.md) | high | not started | Language-server texts and completions (including completion in a file that does not compile), VS Code grammar and snippets, user docs |
| [`15-language-tests`](./15-language-tests/README.md) | high | **delivered** | botopink tests pinning decision 8's `case`/patterns, tuples and labels, and `loop`, with an expected-failures list owned by 12, 06 and 01 step 6 |

Cutover references: [`EXAMPLES.md`](./EXAMPLES.md) (before/after programs; the "before" side compiled
at `botopink-lang` `41981e3`), [`MIGRATION.md`](./MIGRATION.md) (the user-facing migration guide) —
both follow decision 8.

## Surface cutover decisions (fronts 12–14)

Carried from 1.0.3-beta, **amended by [decision 8](./08-review-backlog/decision-8-language.md)** where a row says so. The language keeps its expressive power — named fields, variants
with payloads, sections, generics, `implement`, methods — with fewer keywords and one way to write
each thing.

| Topic | Decision |
|---|---|
| Records | `type Name<G>(fields) implement B { methods }` — fields in parentheses, the declaration mirrors construction `Name(x: 1)`. One form only; no `constructor` keyword. Body optional. |
| Enums | `type Name<G> { Variant, Variant(f: T), Section { … }, methods }` — a body with at least one variant or section. |
| Record with no fields | `type Name { methods }` — a body with no variant. |
| Field list | Shared by record declarations and variant payloads: annotations, comments, defaults, trailing comma. No `val` prefix — values are immutable. |
| Anonymous record | A tuple. Decision 8 §6: construction has no labels (`#("SP", 12)`; a variable element lends its name — `#(name, pop)`), a written type may carry them (`#(name: string, pop: i32)`), `row.pop` is a compile-time index, labels never reach run time or type comparison. Replaces `record { … }` literals and the `{ x: T }` type. |
| Interfaces | `behavior Name { … }`. Same semantics. |
| Separators | `,` separates data items (fields, variants, tuple elements, arguments); no trailing comma → compact on one line, trailing comma → one item per line; a `fn` definition is always open. Members are not comma-separated: a bodyless `fn` or a `val` field ends with `;`, a member that ends with `}` takes nothing. |
| Generics | Decision 8 §1: a written generic type carries all its arguments, `Self<T>` included in generic types and behaviors; explicit type arguments at a use (`Option<i32>.None`, `first<string>([])`); `unknown` and union types (§2–§3). |
| Patterns | Decision 8 §5: `case x { i32 { n -> … } Option.Some(v) when (…) { … } _ { … } }`; tuple patterns positional; `..`; `.Variant`. |
| Effects | Decision 8 §9: `#[@result] fn f() -> @Result<T, E>` (and the other effect wrappers). |
| Loops | Decision 8 §10: `loop (xs)`, `loop (0..n)`, `loop (condition)`, `loop { … break; }`; no `while`. |
| Template markers | Decision 5: positional `$0`, `$1`, … over the declared parameters, `self` included; no `$self`. |
| Dead keywords | `auto`, `derive`, `get`, `macro`, `opaque`, `private`, `set` are identifiers (landed with 11); `delegate` and `new` follow (06, 14) — `throw Error(…)`, not `throw new Error(…)`. |
| Migration | Hard cutover, no deprecation window. Migration is manual (beta phase). Removed keywords get a targeted diagnostic. |
| Runtime | Unchanged for named records, enums and behaviors. Anonymous records change from map/object to tuple. |

## Order

```
01 steps 1–4 · 05 · 10 · 11 ─── delivered
09 hygiene ───────── steps 2/4/5 after the owner of each file · closes last of 01–10
        │
06 checker (alone, next) ──► 01 steps 5–6 (decision 8 at run time) ──┐
        │                                                           │
        └──► 07 comptime-dedup ──► 08 review-backlog (wave A after 06, wave B after 07)
                                                                    │
                                   01–10 closed ────────────────────┘
                                        ▼
                     12 surface-cutover (alone) ──► 13 ecosystem-migration · 14 tooling-and-docs (in parallel)
```

06 goes first because everything after it re-records what it re-records: it moves the typed AST all
four backends consume, and decision 8's run-time half (01 step 6) needs that typed AST before it can
lower a single `is`. 01 step 6 re-records all four codegen directories, so it runs before 08's wave A
reads them. The surface cutover waits for all of 01–10 because it rewrites every file they own.

## Rules carried forward

- **A backend builds a model, an emitter renders it.** When the model cannot express a construct,
  extend the model.
- **The gate is a cold runtime cache** — `scripts/gate.sh --cold` decides a merge.
- **A snapshot is evidence, not a baseline** — re-record only a value verified by running the
  program; a fixture that pins known-wrong output says so in the test.
- **Erlang is not the oracle** — every cross-backend assertion is written against what the program
  means ([`01-backend-residuals/measurement.md`](./01-backend-residuals/measurement.md#erlang-is-not-the-oracle)).
- **A decided semantics question is not reopened by a front** —
  [`semantics-decisions.md`](./08-review-backlog/semantics-decisions.md) (decisions 1–5) and
  [`decision-8-language.md`](./08-review-backlog/decision-8-language.md) are the reference.
- **A front never edits a file it does not own** — it stops and reports.
- **Every commit is green.** Each repo's pre-commit hook (`git config core.hooksPath scripts/git-hooks`) runs its gate; no `--no-verify`.
- **A re-recorded snapshot is classified, not bulk-accepted** (fronts 12–14): source-only diffs
  (parser ids, typed-AST keys) apart from output diffs, and a changed `RUN LOG` or diagnostic
  explained in the commit message.
- **Landing a sibling-repository commit includes pushing it and bumping the meta pointer in the same
  sweep** — 1.0.3-beta's jhonstart and vscode-extension commits were lost at exactly that step.
- **Carried deep dives are evidence from the commit they were written against.** Their `file:line`
  and counts drift; re-locate by symbol, re-measure before quoting. Each says where it came from.
