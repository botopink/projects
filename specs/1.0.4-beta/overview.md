# Specs — 1.0.4-beta (closed)

Two milestones folded into one, and both shipped. **First, the correctness work 1.0.2-beta left
open**: the backend residuals, the checker, the review backlog, hygiene, and the CLI and library
residuals. **Then the 1.0.3-beta surface cutover**: `record`/`enum` became `type`, `interface` became
`behavior`, the anonymous record became a tuple, and the dead keywords' last traces left the
ecosystem.

**[Decision 8](./08-review-backlog/decision-8-language.md)** (2026-09-17) is the language design both
halves implement: written generic types carry all their arguments (`Self<T>` included), the `unknown`
and union types, `is` testing values, `case` arms as `Pattern { n -> … }` with `when` guards, tuple
labels as compile-time names, one source-shaped formatter per type, `#[@result] … -> @Result<T, E>`,
and `loop (condition)` instead of `while`. 1.0.4-beta shipped its **surface** (fronts 12 and 14), its
**grammar** and about half of its **checker** (front 06), and **the tests that pin it** (fronts 15
and 17, 68 cells). Its **run time** — the four backends and the formatter — is 1.0.5-beta's.

**Naming.** "1.0.2 surface" and "1.0.3 surface" in the carried documents
([`EXAMPLES.md`](./EXAMPLES.md), [`MIGRATION.md`](./MIGRATION.md), fronts 11–14) name the old and the
new syntax. Both milestones shipped as 1.0.4-beta.

[`fronts.md`](./fronts.md) holds the ownership record, the unowned items 1.0.4-beta closed, and the
map from the old front numbers the carried deep dives cite.

## What the milestone measured, at its close

| | Reading |
|---|---|
| `zig build test-libs` | **11 passed, 0 failed, 1 skipped** — the skip is rakun's erlang cell; `scripts/known-red-libs.txt` has no line, and every library's `scripts/known-broken-examples.txt` is empty |
| `zig build test-language` | **205 passed, 54 expected failures, 0 failed** (`botopink-lang` `c2dd780`, node v25.8.0, OTP 29), over 68 cells (plus three smoke files) on commonJS, erlang and — for `run/` and `modules/` — wasm |
| `zig build test-docs` | 36 fences in `docs.md`, 32 checked, 2 skipped, 0 failed |
| `scripts/beam_export_audit.sh` | every emitted module assembles |
| Gate | `scripts/gate.sh --cold`: zig build, cold `zig build test`, `test-cli`, `test-libs`, `test-language`, `test-docs`. Every commit of the milestone paid it through the pre-commit hook; no `--no-verify` |

## Delivered

Verified against `botopink-lang` `origin/feat` at `c2dd780` and the meta repository's history. Rows
above the rule were delivered before this milestone opened and are not to redo; rows below it are
1.0.4-beta's own.

| Was | Delivered | What it left |
|---|---|---|
| 1.0.2-beta **comptime-dispatch** | steps 1–2: primitive methods reachable from template and decorator bodies through a dispatch shim built from the typed table; mutation through a method inside a closure threads out on erlang | step 3 (trailing defaults, never executed) → 06 N1, carried |
| 1.0.2-beta **cli-gate** | `build`/`check`/`test` fail on a module that does not compile; contract C1–C14 written and tested; `zig build test-cli`; `scripts/gate.sh [--cold] [--staged]`; `test-libs` over every checked-out library; a CI libs job; the mutation matrix run | the execute flag, located parse/lex errors, the decorator-test tightening, hook installation, `test-bpmp` and the beam audit in the gate → 05, **delivered** |
| 1.0.2-beta **std-surface** | all seven steps: `pick` shadowing, `./gleam_stdlib.mjs` removed, template-only imports, `string:suffix/2`, the manifest, `reflect.bp`/`types.bp` deleted, `primitives.bp`'s tests split out with each gap named | the `files` diagnostic → 05 step 5, **delivered**; the `$0`/`$self` naming → decision 5, **delivered** by 12; `external-annotations.md` → 06, carried |
| 1.0.2-beta **review-tooling** | steps 1–2 (`BOTOPINK_SNAP_TRACE`, `snap_audit.sh --mode=orphans\|review`; 0 orphans of 2451); step 3 — the four semantics decisions, **decided 2026-09-16, every recommendation accepted**; step 4 for reports 3.3, 3.6, 3.11, 3.12 | reports 3.1, 3.2, 3.4, 3.5, 3.7–3.10 → 08, carried |
| 1.0.2-beta **hygiene** | step 1: the comptime frame protocol (logger off `standard_io`, own group leader, 16 MiB frame cap, `erl.stderr.log` as a write-only debug log, the server built in a hashed dir and renamed into place) | steps 2–6 → 09, **delivered** |
| 1.0.2-beta **library-repos** | 7a rakun (vendored http transport, 17/17), 7e/7f/7g vscode-extension, 7h bpmp (108/108) | erika 7b/7c, emilia 7d, two `BOTOPINK_LANG_REF` defaults, rakun's exports → 10, **delivered** |
| 1.0.3-beta **dead-keywords** | the compiler side, `botopink-lang` `ecac19d` | jhonstart's accessors and the VS Code grammar → 11, **delivered** |
| — | — | — |
| **04 js-bridges** | merge `bd7836c`: `node --check` block, C3–C5, JS-1/2/3/5/6, `while` lowering, `pub` template externals, on-demand helpers (`charAt`), `externals.zig` off `gleam_stdlib.mjs`, the `.d.ts` surface, decision 4, every pub enum and record exported | range start, open range, `break` comprehensions → 01 step 3; JS-4 → 06 N11, carried |
| **02 erlang** | merge `42429dc`: E1 map patterns, E2 `__bp_text/1`, E4 `try`/`catch`, E5 + the 7 value `raw` sites, E6, E7, steps 8–9; decisions 1 and 4; erika 7b; closure var threading; std erlang green; operand-proven `+`, float `/`, `Signed.abs` | E8 → 06 N10, carried; methods on associated-fn results → 06 N15, carried |
| **01 beam** (first) | merge `a743955`: B1–B9, B11, B12, `beam_export_audit.sh` 290/290, the `.S` preamble through the emitter, decisions 1 and 4, register clobbering, loop/`forEach` threading, enum tag tests, `Signed.abs` | closure/loop/untyped-`+` fixtures → 01 step 1; the audit in the gate → 05 step 6; unbound names, folded arrays, `run`/`use effect` arity → 06 N13/N5/N14 |
| **03 wasm** | merge `ed15323`: trap block, W1 (unresolved calls 59 → 3), **`executeWat` executes**, W2–W11 (W7 per decision 3), `Module.externs`/`emitFnWat` deleted, decision 4; 143 snapshots gained a real RUN LOG | closure/loop/untyped-`+`, the tuple printer → 01 step 2; stale comments → 09 step 2, **delivered** |
| **01 backend-residuals**, steps 1–4 | merges `00b8975` beam (BR1–BR3, BR4 reviewed, audit 295/295), `4eadb70` wasm (WR1–WR3, WR5), `dbe2863` commonJS (CR1, CR2, CR4), `b4cf700` step 4 (decision 1a on commonJS, erlang and wasm). The three cross-backend fixtures print what the program means on all four backends | BR5 and decision 8's run time → 1.0.5-beta, split per backend |
| **std-split** (unowned) | `c8c2541`: `String.split("")` answers every character on erlang; `builtins.d.bp` documents `__bp_print/1`; the three known-red library cells deleted | — |
| **05 cli-residuals** | merge `440a1d3`: the execute flag, a failed module carries its diagnostic in `ModuleOutput`, located lex/parse errors, the decorator mutation matrix, a missing `files` entry located, `test-bpmp` + `beam_export_audit.sh` + lib-test-runner units in the gate, the self-contained hook (`core.hooksPath scripts/git-hooks`), `gate.sh` clears `GIT_DIR` | `tests/helpers.zig` reading the failed-module diagnostic → 08, carried |
| **09 hygiene** | `e98a5da` + `8887865` (dead module build files, root test stubs, `meta:build.zig`, the lib-test-runner's standalone build pair); decisions 5.5a, 5.5b, 5.9 (MIT in the seven code repos, `af9b5b6`); the three comment sweeps `2997a5b`, `02709dd`, `594e262` | the tail of each sweep in files another front still owned — 19 `primitives.d.bp` comments, one `wat_runtime` mention |
| **10 library-repos** | erika `051cd97`, emilia `321981d`, jhonstart `8668c40`, onze `2fcf860`, rakun's export verified; then every library builds its examples in its gate (erika `17728e3`, emilia `a167c06`, jhonstart `6c807d1`, onze `cda9d01`, rakun `d5ca84b`) | the broken examples → 13, **delivered** |
| **11 dead-keywords-residual** | jhonstart `bf868ca` (`get` accessors are methods), vscode-extension `eb870ac` (the grammar drops the seven words) | `delegate`, `new`, `.@"const"` → 06 N27 + 14, **both delivered** |
| **12 surface-cutover** | merge `ed575b5`, steps 1–4 (`431f9bf` … `6a43124`): one `TypeDecl`/`BehaviorDecl` AST, the dual grammar, the source migration, then the old surface removed — `type`, `behavior`, labeled tuples with compile-time labels, the separator rule, decision 5's positional template markers. 2442 snapshot files classified by hand | decision 8's source migration (`Self<T>`, the effect wrappers) → 06 step 9, carried; the formatter's trivia limits |
| **15 language-tests** | `7dbe1ea`: the harness, `expected-failures.txt`, `zig build test-language` as gate stage 8 and a CI step, and 34 files pinning decision 8's `case`, tuples and `loop` — 63 pass, 33 expected failures at landing. Plus the phase-2 gap analysis (four documents) that front 17 executed | `crash/`, area directories → 1.0.5-beta |
| **13 ecosystem-migration** | all five libraries on the 1.0.3 surface — emilia `63f62d1`, erika `4a75280`, jhonstart `f2bf0e8`, onze `557fd9f`, rakun `0814492` — every example building, and the erlang cells green: emilia 17/17, erika 31/31 hard, jhonstart 8/8, onze green | `format --check` on erika and jhonstart, decision 8's library items, rakun's skipped erlang cell |
| **14 tooling-and-docs** | `26d4fdc` (hover and `renderType` in the 1.0.3 surface), `dfc34a9` (completion while the file does not compile; the hover footer names the declaring behavior), `758dae4` (the user docs and `zig build test-docs`), `84e493a` + `63dd882` (project-graph diagnostics, enum sections in the outline, `type`/`behavior` completion, the variant-on-a-value fix); vscode-extension `e6abeb3`, `1753104`, `b7c74c8` — 37/37 green | the `record { … }` type name `infer.zig` builds, the `case` snippet's arms, `SymbolKind.Method` |
| **17 language-test-expansion** | merge `2f44b30` + `8433086`: 37 cells for effects, comptime and templates, decorators, host externals, generics and `behavior` dispatch, closures, optionals, modules and the §7 formatter; a `modules/` kind (`f699517`); wasm as a third executable target and beam measured and refused (`89f3761`) | its 54 expected-failure lines name 1.0.4-beta rows and must be re-pointed |
| **06 checker** | G0 (`13f61fa`), G1 (`9b61ecf` … `1c9b60c`), C5 + C12 + N25 (`62d4865`, `d2b468d`, `3e7cd62`), C9 + N24 (`c2dd780`), C3 + C13's located `MissingExternalTarget` (`f6d8ce6`, `7b1db40`), and decision 8's **grammar** — `unknown`, unions, `is`, `case` arms (`d0c27f6`) | the whole `comptime/**` tail — see [`06-checker`](./06-checker/README.md#what-it-left-and-where) |
| **20 cli-residuals-ii** | `de4aa87`: `botopink new` scaffolds a program that prints. `c01695f`: a library ships its erlang host module (`shipErlSidecars`). The CLI half of the swallowed project-graph diagnostics verified closed | defect A (an `import` naming nothing) implemented and parked, blocked on a `docs.md` fence |

## Fronts

| Front | State | What it delivered |
|---|---|---|
| [`01-backend-residuals`](./01-backend-residuals/README.md) | **delivered** (steps 1–4) | Closure and loop threading, indexed loop starts, open ranges, operand-proven `+` and float `/`, wasm closure captures and string `+`, commonJS record/enum/behavior methods and `pair.0`, and decision 1a's array/tuple print text on three backends |
| [`05-cli-residuals`](./05-cli-residuals/README.md) | **delivered** | The execute flag, diagnostics that survive to the CLI, located lex/parse errors, decorator tests that prove their lowering, and a gate that is installed and covers what ships |
| [`06-checker`](./06-checker/README.md) | **delivered** — five groups and decision 8's grammar | G0, G1, C5, C10+N30, C12, N25, C9, N24, C3, C13's located `MissingExternalTarget`; `unknown`, union types, `is` and `case` arms as grammar |
| [`08-review-backlog`](./08-review-backlog/README.md) | **delivered** — the decisions | [Decision 8](./08-review-backlog/decision-8-language.md), the language design the whole milestone implements, and the four semantics decisions of 2026-09-16. Both `lsp.md` rows closed |
| [`09-hygiene`](./09-hygiene/README.md) | **delivered** | The frame protocol, the build files that lied, `libs/std`'s declared surface, the retired vocabulary, the three comment sweeps, MIT in the seven repos and a self-contained hook per repo |
| [`10-library-repos`](./10-library-repos/README.md) | **delivered** | erika 7b/7c, emilia's gate, the last two `BOTOPINK_LANG_REF` defaults, rakun's exports — and every library's gate building its examples |
| [`11-dead-keywords-residual`](./11-dead-keywords-residual/README.md) | **delivered** | jhonstart's `get` accessors become methods; the VS Code grammar drops the seven dead keywords |
| [`12-surface-cutover`](./12-surface-cutover/README.md) | **delivered** | `type`, `behavior`, tuples and separators through the whole compiler, `libs/std`, every test source and every snapshot; decision 5's positional markers |
| [`13-ecosystem-migration`](./13-ecosystem-migration/README.md) | **delivered** | emilia, erika, jhonstart, onze and rakun migrated; every example building; four of the five erlang cells green |
| [`14-tooling-and-docs`](./14-tooling-and-docs/README.md) | **delivered** | Language-server texts, completions and symbol kinds (including completion in a file that does not compile and the project graph's own diagnostics), the VS Code grammar and snippets, and user docs whose every fence the gate compiles |
| [`15-language-tests`](./15-language-tests/README.md) | **delivered** | The botopink-level test harness, its gate stage, and the cells that pin decision 8's `case`, tuples and `loop` |
| [`17-language-test-expansion`](./17-language-test-expansion/README.md) | **delivered** | 37 cells for the rest of the language, a `modules/` kind, and wasm as a third executable target |
| [`20-cli-residuals-ii`](./20-cli-residuals-ii/README.md) | **delivered** (defects B, C, D) | A scaffold that prints, a library that can ship an erlang host module, and the CLI half of the swallowed project-graph diagnostics verified |

## Carried into 1.0.5-beta

Everything 1.0.4-beta did not deliver moves to `specs/1.0.5-beta/`, renumbered. Each front above
names its own residuals in a **"What it left, and where"** section; this is the map.

| 1.0.5-beta front | Came from |
|---|---|
| `01-checker` | The whole `comptime/**` tail of [`06-checker`](./06-checker/README.md): rows N1–N3, N5–N7, N9–N15, N18, the inference halves of N19–N22, N29, C6's residual and C13's 212-file `.withLoc` sweep; steps 6–9 (the parser gaps, types as values, narrowing, decision 8 in the sources); and the handoffs from 13, 14 and 09 |
| `02-erlang` · `03-beam` · `04-js` · `05-wasm` | [`01-backend-residuals`](./01-backend-residuals/README.md) steps 5 and 6, **split one front per backend**: BR5 (beam compiles `@External.Erlang` templates at build time) and decision 8's run time — `is` by value, `unknown` and unions, `case` arms, `row.label` as an index, and the §7 formatter that replaces the decision-1a printers. Plus JS-4's codegen half, the dead block-as-value lowerings, and commonJS's `require("../module")` |
| `06-comptime-dedup` | Front **07**, never started: four byte-identical copies per comptime slug (1009 files for 306 unique paths), and a typed-AST renderer that prints `?` and `"id": 0`. Its directory and `renderer.md` carry the measurement |
| `07-review-backlog` | [`08-review-backlog`](./08-review-backlog/README.md)'s wave A (reports 3.1, 3.2, 3.4, 3.5, 3.3's `:70`) and wave B (3.7–3.10), the five remaining `uncertain` rows, and the test-source items 05 and 09 handed over |
| `08-hygiene` | [`09-hygiene`](./09-hygiene/README.md)'s sweep tail: 19 comments still naming `primitives.d.bp`, one `wat_runtime` mention, 5.13's fixture rewrite, the comptime transport-error diagnostic, and the `docs-check` directive on `docs.md:78` that unblocks `10-cli-residuals` |
| `09-ecosystem-residuals` | [`13-ecosystem-migration`](./13-ecosystem-migration/README.md)'s `format --check` on erika and jhonstart, emilia's `format` reordering `Token`, decision 8's library items, and rakun's skipped erlang cell |
| `10-cli-residuals` | [`20-cli-residuals-ii`](./20-cli-residuals-ii/README.md)'s defect A — implemented and parked as `stash@{0}` on `fix/cli` — plus the flat `test/` suite's silent unresolved imports and the `shipErlSidecars` call site in `cli/build.zig` |
| `11-tooling` | [`14-tooling-and-docs`](./14-tooling-and-docs/README.md)'s residuals: the `case` snippet's arms (after `01-checker` N22), `SymbolKind.Function` → `Method` across both repositories, and `loadSrcTree`'s third `catch continue` in `project_graph.zig` |
| `12-language-tests` | [`17-language-test-expansion`](./17-language-test-expansion/README.md)'s tail: re-pointing all 54 `expected-failures.txt` owner rows at their new fronts, the `crash/` kind, area directories, and the shapes that do not parse |
| `13-module-identity` | Fronts **16** and **19**, neither started, merged into one: the erlang/BEAM module atom is the source path's basename, so two modules with the same file name collide silently and eleven `libs/std` modules shadow an OTP module — an `@`-joined path atom, a `__t__`/`__b__` qualifier, and policy 3 (every `type` and `behavior` gets its own BEAM module); plus the run-time type identity a value needs to know its own type, which is the same question seen from the other end |
| `14-comptime-on-beam` | Front **18**, never started |

1.0.5-beta's own `fronts.md` carries the unowned items that are still open, each against the front
that now owns the file.

## The surface, as it shipped

Carried from 1.0.3-beta, amended by [decision 8](./08-review-backlog/decision-8-language.md) where a
row says so. The language kept its expressive power — named fields, variants with payloads, sections,
generics, `implement`, methods — with fewer keywords and one way to write each thing. A row marked
**checker carried** parses and is written this way everywhere, but the rule is not yet enforced.

| Topic | Decision |
|---|---|
| Records | `type Name<G>(fields) implement B { methods }` — fields in parentheses, the declaration mirrors construction `Name(x: 1)`. One form only; no `constructor` keyword. Body optional. |
| Enums | `type Name<G> { Variant, Variant(f: T), Section { … }, methods }` — a body with at least one variant or section. A section is a type named by its path (`Token.Text`) |
| Record with no fields | `type Name { methods }` — a body with no variant. |
| Field list | Shared by record declarations and variant payloads: annotations, comments, defaults, trailing comma. No `val` prefix — values are immutable. |
| Anonymous record | A tuple. Decision 8 §6: construction has no labels (`#("SP", 12)`; a variable element lends its name — `#(name, pop)`), a written type may carry them (`#(name: string, pop: i32)`), `row.pop` is a compile-time index, labels never reach run time or type comparison. Replaces `record { … }` literals and the `{ x: T }` type |
| Interfaces | `behavior Name { … }`. Same semantics. |
| Separators | `,` separates data items (fields, variants, tuple elements, arguments); no trailing comma → compact on one line, trailing comma → one item per line; a `fn` definition is always open. Members are not comma-separated: a bodyless `fn` or a `val` field ends with `;`, a member that ends with `}` takes nothing. |
| Generics | Decision 8 §1 — **checker carried**: a written generic type carries all its arguments, `Self<T>` included; explicit type arguments at a use; `unknown` and union types are in the grammar |
| Patterns | Decision 8 §5: `case x { i32 { n -> … } Option.Some(v) when (…) { … } _ { … } }`, tuple patterns positional, `..`, `.Variant`, the inclusive range `A...B` — **the grammar shipped; arm binding, exhaustiveness and narrowing are checker carried** |
| Effects | Decision 8 §9: `#[@result] fn f() -> @Result<T, E>`, enforced; `val assert Ok(n) = …` takes no `catch` and its pattern binds |
| Loops | Decision 8 §10: `loop (xs)`, `loop (0..n)`, `loop (condition)`, `loop { … break; }`; `while` is refused with a located message, on all four backends |
| Template markers | Decision 5: positional `$0`, `$1`, … over the declared parameters, `self` included; no `$self` |
| Dead keywords | `auto`, `derive`, `get`, `macro`, `opaque`, `private`, `set`, `delegate` and `new` are identifiers — `throw Error(…)`, not `throw new Error(…)` |
| Printing | Decision 8 §7: one derived formatter per type, source-shaped, the same on every backend — **carried whole to 1.0.5-beta**. What shipped is decision 1a's array/tuple text on commonJS, erlang and wasm |
| Migration | Hard cutover, no deprecation window. Migration is manual (beta phase). Removed keywords get a targeted diagnostic |
| Runtime | Unchanged for named records, enums and behaviors. Anonymous records changed from map/object to tuple |

Cutover references: [`EXAMPLES.md`](./EXAMPLES.md) (before/after programs; the "before" side compiled
at `botopink-lang` `41981e3`), [`MIGRATION.md`](./MIGRATION.md) (the user-facing migration guide).

## Rules the milestone ran under

Kept because the carried documents assume them.

- **A backend builds a model, an emitter renders it.** When the model cannot express a construct,
  extend the model.
- **The gate is a cold runtime cache** — `scripts/gate.sh --cold` decides a merge.
- **A snapshot is evidence, not a baseline** — re-record only a value verified by running the
  program; a fixture that pins known-wrong output says so in the test.
- **Erlang is not the oracle** — every cross-backend assertion is written against what the program
  means ([`01-backend-residuals/measurement.md`](./01-backend-residuals/measurement.md#erlang-is-not-the-oracle)).
- **A decided semantics question is not reopened by a front** —
  [`semantics-decisions.md`](./08-review-backlog/semantics-decisions.md) and
  [`decision-8-language.md`](./08-review-backlog/decision-8-language.md) are the reference.
- **A front never edits a file it does not own** — it stops and reports.
- **Every commit is green.** Each repo's pre-commit hook (`git config core.hooksPath
  scripts/git-hooks`) runs its gate; no `--no-verify`.
- **A re-recorded snapshot is classified, not bulk-accepted**: source-only diffs (parser ids,
  typed-AST keys) apart from output diffs, and a changed `RUN LOG` or diagnostic explained in the
  commit message.
- **Landing a sibling-repository commit includes pushing it and bumping the meta pointer in the same
  sweep** — 1.0.3-beta's jhonstart and vscode-extension commits were lost at exactly that step.
- **Carried deep dives are evidence from the commit they were written against.** Their `file:line`
  and counts drift; re-locate by symbol, re-measure before quoting. Each says where it came from.
