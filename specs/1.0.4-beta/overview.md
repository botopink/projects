# Specs — 1.0.4-beta

Two milestones folded into one. **First, the correctness work 1.0.2-beta left open**: four backend
fronts (in flight since 2026-09-16), the checker, the comptime snapshot layout, the review backlog,
hygiene, and the CLI and library residuals. **Then the 1.0.3-beta surface cutover**: `record`/`enum`
become `type`, `interface` becomes `behavior`, the anonymous record becomes a labeled tuple, and the
dead keywords' last traces leave the ecosystem. 1.0.3-beta's entry criterion — "1.0.2-beta is
closed" — carries over as **fronts 01–10 are closed before 11–14 start**: the cutover rewrites the
source of ~700 snapshots and touches every file the correctness fronts own.

The work is cut into **fourteen fronts**, numbered in execution order. [`fronts.md`](./fronts.md)
holds the ownership table, the conflict matrix, the items no front owns, and the map from the old
front numbers the carried deep dives cite.

**Naming.** "1.0.2 surface" and "1.0.3 surface" in the carried cutover documents
([`EXAMPLES.md`](./EXAMPLES.md), [`MIGRATION.md`](./MIGRATION.md), fronts 11–14) name the old and the
new syntax. Both milestones ship as 1.0.4-beta.

## Delivered before this milestone

Verified 2026-09-16 against `botopink-lang` `origin/feat` = `0552e32`. Not to redo; what each left is
carried into the front named.

| Was | Delivered | Left, and where it went |
|---|---|---|
| 1.0.2-beta **comptime-dispatch** | steps 1–2: primitive methods reachable from template and decorator bodies through a dispatch shim built from the typed table; mutation through a method inside a closure threads out on erlang | step 3 (trailing defaults, never executed) → [`06-checker`](./06-checker/README.md) N1; the beam half of step 2 → [`01-beam`](./01-beam/README.md) H3 |
| 1.0.2-beta **cli-gate** | `build`/`check`/`test` fail on a module that does not compile; contract C1–C14 written and tested; `zig build test-cli`; `scripts/gate.sh [--cold] [--staged]`; `scripts/install-hooks.sh`; `test-libs` over every checked-out library with `scripts/known-red-libs.txt`; a CI libs job; the mutation matrix run | the execute flag, diagnostics through `codegenEmit`, located parse/lex errors, the decorator-test tightening, hook installation, `test-bpmp` and `lib-test-runner` in the gate → [`05-cli-residuals`](./05-cli-residuals/README.md) |
| 1.0.2-beta **std-surface** | all seven steps: `pick` shadowing, `./gleam_stdlib.mjs` removed (interface methods bound to native JS, slice helpers as inline templates; no helper mechanism yet), template-only imports, `string:suffix/2`, the manifest, `reflect.bp`/`types.bp` deleted, `primitives.bp`'s tests in `libs/std/test/primitives_test.bp` + `primitives_gaps_test.bp` (each gap named) | `Signed.abs` from an `i32` → 01 H7, 02 H6; `String.charAt` helper and cross-module template exports → 04 H3/H4; the `files` diagnostic → 05 step 5; the `$0`/`$self` naming → [`fronts.md` § unowned items](./fronts.md#unowned-items); `external-annotations.md` → 06 |
| 1.0.2-beta **review-tooling** | steps 1–2 (`BOTOPINK_SNAP_TRACE`, `snap_audit.sh --mode=orphans\|review`; 0 orphans of 2451); step 3 — the four semantics decisions, **decided 2026-09-16, every recommendation accepted**; step 4 for reports 3.3, 3.6, 3.11, 3.12 | reports 3.1, 3.2, 3.4, 3.5, 3.7–3.10 → [`08-review-backlog`](./08-review-backlog/README.md); each decision's implementation → the handoffs named in [`semantics-decisions.md`](./08-review-backlog/semantics-decisions.md) |
| 1.0.2-beta **hygiene** | step 1: the comptime frame protocol (logger off `standard_io`, own group leader, 16 MiB frame cap, `erl.stderr.log` as a write-only debug log, the server built in a hashed dir and renamed into place; `meta:erl_crash.dump` deleted) | steps 2–6 → [`09-hygiene`](./09-hygiene/README.md) |
| 1.0.2-beta **library-repos** | 7a rakun (vendored http transport, 17/17), 7e/7f/7g vscode-extension, 7h bpmp (108/108) | erika 7b/7c, emilia 7d, two `BOTOPINK_LANG_REF` defaults, rakun's exports → [`10-library-repos`](./10-library-repos/README.md) |
| 1.0.3-beta **dead-keywords** | the compiler side, `botopink-lang` `ecac19d` | jhonstart's accessors and the VS Code grammar — their commits were never pushed → [`11-dead-keywords-residual`](./11-dead-keywords-residual/README.md) |

Library gate on that commit (`zig build test-libs`): emilia, onze, rakun pass; known-red erika
commonJS + erlang and jhonstart commonJS (02), `libs/std` commonJS (04) and erlang (02).

## Fronts

| Front | Priority | State | What |
|---|---|---|---|
| [`01-beam`](./01-beam/README.md) | high | **in flight** | 58 of 128 fixtures disagree; an unresolvable identifier becomes an atom of its own name. Plus `__bp_print/1`, fatal `assert`, closure-mutation threading, imported-enum arms, `Signed.abs` |
| [`02-erlang`](./02-erlang/README.md) | high | **in flight** | Record destructuring, binary segments, imported enum variants, `return` in a narrowed arm, the `raw` rows. Plus `__bp_print/1` on both paths, fatal `assert`, and the erika/jhonstart/std erlang library reds |
| [`03-wasm`](./03-wasm/README.md) | high | **in flight** | `emitWat` never receives `instance_lowerings`; the `executeWat` decision; the `?T` carrier (now decided: boxed) |
| [`04-js-bridges`](./04-js-bridges/README.md) | high | **in flight** | The bridges that emit illegal JS, three lowering bugs. Plus the std commonJS red, `.d.ts` surface, `charAt`, cross-module template exports, and four runtime defects the 1.0.3 examples found |
| [`05-cli-residuals`](./05-cli-residuals/README.md) | medium | not started | `generate` still executes what it compiles; diagnostics lost in `codegenEmit` and unlocated parse/lex errors; blind decorator tests; the gate installed and covering bpmp and test-less libraries |
| [`06-checker`](./06-checker/README.md) | high | not started | C1–C13: the checker accepts wrong programs. Plus trailing defaults, decision 2's enforcement, and seven rows found since |
| [`07-comptime-dedup`](./07-comptime-dedup/README.md) | medium | not started | Four byte-identical copies per comptime slug; a renderer that prints `?` and `"id": 0` |
| [`08-review-backlog`](./08-review-backlog/README.md) | medium | not started | The per-report residuals of the 1.0.1-beta snapshot review, in two waves |
| [`09-hygiene`](./09-hygiene/README.md) | low | step 1 delivered | The removed WAT runtime's leftovers, build files that lie, retired vocabulary, license and meta gate decisions |
| [`10-library-repos`](./10-library-repos/README.md) | medium | partly delivered | erika's loop and docs, emilia's gate, two CI defaults, rakun's exports |
| [`11-dead-keywords-residual`](./11-dead-keywords-residual/README.md) | low | compiler half delivered | jhonstart's `get` accessors become methods; the VS Code grammar drops the seven words |
| [`12-surface-cutover`](./12-surface-cutover/README.md) | critical | not started | `type`, `behavior`, labeled tuples and separators through the whole compiler, `libs/std`, every test source and snapshot |
| [`13-ecosystem-migration`](./13-ecosystem-migration/README.md) | high | not started | emilia, erika, jhonstart, onze, rakun migrated to the new surface |
| [`14-tooling-and-docs`](./14-tooling-and-docs/README.md) | high | not started | Language-server texts and completions, VS Code grammar and snippets, user docs |

Cutover references: [`EXAMPLES.md`](./EXAMPLES.md) (before/after programs, compiled at
`botopink-lang` `41981e3`), [`MIGRATION.md`](./MIGRATION.md) (the user-facing migration guide).

## Surface cutover decisions (fronts 11–14)

Carried from 1.0.3-beta unchanged. The language keeps its expressive power — named fields, variants
with payloads, sections, generics, `implement`, methods — with fewer keywords and one way to write
each thing.

| Topic | Decision |
|---|---|
| Records | `type Name<G>(fields) implement B { methods }` — fields in parentheses, the declaration mirrors construction `Name(x: 1)`. One form only; no `constructor` keyword. Body optional. |
| Enums | `type Name<G> { Variant, Variant(f: T), Section { … }, methods }` — a body with at least one variant or section. |
| Record with no fields | `type Name { methods }` — a body with no variant. |
| Field list | Shared by record declarations and variant payloads: annotations, comments, defaults, trailing comma. No `val` prefix — values are immutable. |
| Anonymous record | Labeled tuple `#(x: 10, y: 20)`, type `#(x: i32, y: i32)`. Labels live in the type only; the runtime value **is** a tuple. Replaces `record { … }` literals and the `{ x: T }` type. |
| Interfaces | `behavior Name { … }`. Same semantics. |
| Separators | `,` separates data items (fields, variants, tuple elements, arguments); no trailing comma → compact on one line, trailing comma → one item per line; a `fn` definition is always open. Members are not comma-separated: a bodyless `fn` or a `val` field ends with `;`, a member that ends with `}` takes nothing. |
| Dead keywords | `auto`, `derive`, `get`, `macro`, `opaque`, `private`, `set` become identifiers (compiler side landed; residual is front 11). |
| Migration | Hard cutover, no deprecation window. Migration is manual (beta phase). Removed keywords get a targeted diagnostic. |
| Runtime | Unchanged for named records, enums and behaviors. Anonymous records change from map/object to tuple. |

## Order

```
01 beam · 02 erlang · 03 wasm · 04 js-bridges        in flight — 4 in parallel
05 cli-residuals ── steps 1, 3–6 beside them; step 2 after all four
        │
        └──► 06 checker (alone) ──► 07 comptime-dedup ──► 08 review-backlog (wave A after 06, wave B after 07)
10 library-repos ── erika after 02 · emilia after 09's decision 5.5 · before 06's emilia migration
09 hygiene ─────── decisions now · each sweep after the owner of the file · closes last of 01–10
        │
        ▼  01–10 closed
11 dead-keywords-residual ─┐
12 surface-cutover (alone) ┴──► 13 ecosystem-migration · 14 tooling-and-docs   (2 in parallel)
```

The four backend fronts go first because they are already running, and because everything after
them re-records what they re-record: the checker moves the typed AST all four consume, and the
review backlog re-derives rows against their snapshots. The checker waits for `05`'s `codegenEmit`
commit so that commit can be proven byte-identical before anything is re-recorded. The surface
cutover waits for all of 01–10 because it rewrites every file they own and needs a library gate that
means something — today five of its cells are known-red for reasons 02 and 04 close.

## Rules carried forward

- **A backend builds a model, an emitter renders it.** When the model cannot express a construct,
  extend the model.
- **The gate is a cold runtime cache** — `scripts/gate.sh --cold` decides a merge.
- **A snapshot is evidence, not a baseline** — re-record only a value verified by running the
  program; a fixture that pins known-wrong output says so in the test.
- **Erlang is not the oracle** — every cross-backend assertion is written against what the program
  means ([`02-erlang/causes.md`](./02-erlang/causes.md#erlang-is-not-the-oracle)).
- **A decided semantics question is not reopened by a front** —
  [`semantics-decisions.md`](./08-review-backlog/semantics-decisions.md) is the reference.
- **A front never edits a file it does not own** — it stops and reports.
- **Every commit is green.** The pre-commit hook runs the gate; no `--no-verify`.
- **A re-recorded snapshot is classified, not bulk-accepted** (fronts 12–14): source-only diffs
  (parser ids, typed-AST keys) apart from output diffs, and a changed `RUN LOG` or diagnostic
  explained in the commit message.
- **Landing a sibling-repository commit includes pushing it and bumping the meta pointer in the same
  sweep** — 1.0.3-beta's jhonstart and vscode-extension commits were lost at exactly that step.
- **Carried deep dives are evidence from the commit they were written against.** Their `file:line`
  and counts drift; re-locate by symbol, re-measure before quoting. Each says where it came from.
