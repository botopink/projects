# Fronts — 1.0.4-beta: what can run at the same time

The fronts say *what* to fix; this says *who may touch what, when*. A front is one worktree
(`.tasks/<name>`), one branch, one `todo.md`, one owner. Two fronts may run at the same time only
when they share **no source file and no snapshot directory**.

Paths are relative to `repository/botopink-lang/modules/compiler-core/` unless a row says otherwise;
`cli/`, `modules/`, `libs/`, `scripts/`, `build.zig` and `.github/` are relative to
`repository/botopink-lang/`, and `repository/<lib>` names a sibling repository.

## Ownership

| Front | Source it owns | Snapshots it owns | State |
|---|---|---|---|
| **01** [`backend-residuals`](./01-backend-residuals/README.md) | `src/codegen/beam_asm.zig`, `src/codegen/beam/**`, `src/codegen/erlang.zig`, `src/codegen/wat.zig`, `src/codegen/wat/**`, `src/codegen/commonJS.zig`, `src/codegen/typescript.zig`, `src/codegen/js/**`, `src/codegen/runtime.zig` (note 2) · the `KNOWN` notes and new fixtures of its rows in `src/codegen/tests/**` (carve-out) | `snapshots/codegen/{beam,erlang,wasm,commonJS}/` | steps 1–4 **delivered**; steps 5 (BR5) and 6 (decision 8 at run time) run **after 06** |
| **05** [`cli-residuals`](./05-cli-residuals/README.md) | `modules/compiler-cli/**`, `modules/lib-test-runner/**`, `build.zig`, `.github/workflows/**`, `scripts/**` except `scripts/snap_audit.sh` | — | **delivered** (`440a1d3`); its files have no open row — a follow-up in them (09's 5.4, the lib-test-runner build files) is 09's |
| **06** [`checker`](./06-checker/README.md) | `src/comptime/{infer,types,env,unify,transform,eval,error}.zig` · `src/parser/{decls,exprs,patterns}.zig` · `src/lexer.zig` and `src/lexer/**` for the `new`/`delegate`/`.@"const"` removal | `snapshots/comptime/**`, and it can move **all four** codegen directories and LSP completion snapshots | not started — after 12 (reordered 2026-09-17) |
| **07** [`comptime-dedup`](./07-comptime-dedup/README.md) | `src/comptime/snapshot.zig`, `src/comptime/tests/helpers.zig` | `snapshots/comptime/**` (layout: 3 of 4 copies deleted) | not started |
| **08** [`review-backlog`](./08-review-backlog/README.md) | `src/utils/snap.zig`, `scripts/snap_audit.sh`, `src/codegen/tests/**`, `src/comptime/tests/**`, `src/parser/tests/**`, `modules/language-server/src/tests/**` (minus the carve-outs of 01 and 07) · status lines of the 1.0.1-beta reports (meta repo) | — (moves a snapshot only by renaming its test) | steps 1–3 delivered as 1.0.2-beta review-tooling; decisions 1–8 taken |
| **09** [`hygiene`](./09-hygiene/README.md) | `src/comptime/runtime/persistent_erl.zig` · `modules/lib-test-runner/build.zig` + `.zon`, `build.zig`'s `test-vscode` step (5.4) · `libs/std/botopink.json`, `libs/std/AGENTS.md` · `examples/**`, `README.md`, `docs.md`, every `AGENTS.md`, comments (after owners) | — | steps 1, 3 (except 5.4) and 6 delivered; 2, 4, 5 open |
| **10** [`library-repos`](./10-library-repos/README.md) | — | — | **delivered** |
| **11** [`dead-keywords-residual`](./11-dead-keywords-residual/README.md) | — | — | **delivered** |
| **12** [`surface-cutover`](./12-surface-cutover/README.md) | `modules/compiler-core/src/**`, `modules/language-server/src/**` (compile-level), `cli/resolver.zig`, `libs/std/**`, `examples/**` | `modules/compiler-core/snapshots/**`, LSP snapshots | **delivered** 2026-09-17 — the old surface is gone; 7 library cells known-red until 13 |
| **13** [`ecosystem-migration`](./13-ecosystem-migration/README.md) | `repository/{emilia,erika,jhonstart,onze,rakun}/**`; their meta submodule pointers | the libraries' own test outputs | not started |
| **14** [`tooling-and-docs`](./14-tooling-and-docs/README.md) | `modules/language-server/src/{engine,server}.zig` (user-facing texts, completions, symbol kinds, completion in a non-compiling file), `repository/vscode-extension/**`, botopink-lang user docs | LSP hover/completion/symbol snapshots | not started |
| **15** [`language-tests`](./15-language-tests/README.md) | `tests/language/**` (new) · the `test-language` step in `build.zig` · its stage in `scripts/gate.sh` | — | **delivered** — gate stage 8; expected failures owned by 06 and 01 step 6 |

`libs/std/**` code has **no owner** until 12. A fix that needs a `libs/std` edit stops and reports;
the maintainer assigns it per case (std-split `c8c2541` was one). `scripts/known-red-libs.txt` is empty;
a front that adds a known-red cell names itself as owner, the front that turns it green deletes the
line. Each library's `scripts/known-broken-examples.txt` is 13's.

## Conflict matrix

Open fronts only. `yes` = may run at the same time · `no` = shares a file or a snapshot directory:
sequence them · `seq` = no shared file, but the milestone orders them. Symmetric; the order is in the
notes and in [Order](#order).

|  | 01 (5–6) | 06 | 07 | 08 | 09 | 12 | 13 | 14 |
|---|---|---|---|---|---|---|---|---|
| **01 (5–6)** | — | no¹ | yes | no⁴ | no⁵ | no⁶ | seq⁷ | seq⁷ |
| **06** | no¹ | — | no³ | no⁴ | no⁵ | no⁶ | seq⁷ | seq⁷ |
| **07** | yes | no³ | — | no⁴ | no⁵ | no⁶ | seq⁷ | seq⁷ |
| **08** | no⁴ | no⁴ | no⁴ | — | no⁵ | no⁶ | seq⁷ | seq⁷ |
| **09** | no⁵ | no⁵ | no⁵ | no⁵ | — | no⁶ | no⁸ | no⁸ |
| **12** | no⁶ | no⁶ | no⁶ | no⁶ | no⁶ | — | no⁸ | no⁸ |
| **13** | seq⁷ | seq⁷ | seq⁷ | seq⁷ | no⁸ | no⁸ | — | yes |
| **14** | seq⁷ | seq⁷ | seq⁷ | seq⁷ | no⁸ | no⁸ | yes | — |

1. **06 before 01 steps 5–6.** 06 moves the typed AST every backend consumes and can re-record all four
   codegen snapshot directories; decision 8's run time (step 6) lowers what 06 types (`is`, unions,
   `case` arms, tuple labels), and BR5 was moved after 06 by the maintainer. 01's open steps start
   when 06 has landed.
2. **`src/codegen/runtime.zig` is 01's.** A change to it bumps `HARNESS_VERSION` in the same commit.
3. **06 × 07 share `snapshots/comptime/**`**: 06 re-records it, 07 restructures it. 06 first.
4. **08 owns the test sources** 01, 06 and 07 add fixtures to, and its rows cite snapshots they
   re-record. Wave A (codegen reports) runs after 01 step 6 — which re-records every print-text RUN
   LOG — and wave B (comptime reports) after 07 step 2. 01's `KNOWN` notes are a carve-out.
5. **09's comment sweeps touch every other front's files.** Each sweep lands after the front that owns
   the swept file, one commit per owning file; its behaviour edits (5.4, the lib-test-runner build
   files, step 4's `libs/std` manifest) run at any time.
6. **12 owns all of `modules/compiler-core/src/**`**, the LSP source, `libs/std/**` and `examples/**`
   — every compiler front's files. It starts after 01–10 close, alone.
7. **13 and 14 need 12's compiler.** The libraries compile only against the new surface; the grammar
   and the language-server texts follow it.
8. **12 × 13** is a compiler dependency; **12 × 14** share `language-server/src/engine.zig`;
   **09 × 13/14** would share library and user docs if a sweep were still open.

## Order

**Reordered 2026-09-17 by the maintainer: 12 runs now, before 06.** 06 then writes its rules on the
unified AST once, and the source migration that needs decision 8's checker moves to 06 step 9.

```
01 steps 1–4 · 05 · 10 · 11 ─── delivered
12 surface-cutover (alone on compiler-core/src, libs/std, examples) ── now
        │                                     09 fix/hygiene-build (build.zig test-vscode, lib-test-runner) beside it
        ▼
06 checker (incl. step 9: decision 8 in the sources) ──► 01 steps 5–6 ──► 08 wave A
        │
        └──► 07 comptime-dedup ──► 08 wave B
09 sweeps after each owner
13 ecosystem-migration ∥ 14 tooling-and-docs — after 12 (13's decision-8 items after 06)
```

**Critical path:** **12** → **06** → 01 step 6 ∥ **07** → 08 → 09's last sweeps; 13 ∥ 14 after 12.
12 and 06 each run alone on their files.

## Rules for a front

- One worktree under `.tasks/<front>`, one branch `fix/<front>`, a `todo.md` at its root carrying
  the steps, the owned and forbidden paths, and the exit gate. `todo.md` is git-ignored.
- **A front never edits a file it does not own.** If a fix needs one, it stops and reports.
- The gate before landing: `scripts/gate.sh --cold` (zig build, cold `zig build test`, `test-cli`,
  `test-libs`) green in the front's own worktree.
- Landing: merge into `feat`, gate green in the main checkout, push, submodule bump in the meta repo
  — for a front that commits in a sibling repository, push that repository in the same sweep —
  then delete the worktree and the branch.
- A refactor front lands **snapshot-byte-identical**; a fix front re-records only values it verified
  by running the program.

<a id="unowned-items"></a>

## Unowned items

Found by a front and owned by none. Each needs the maintainer to assign it (or push it to the next
milestone) before the front that would otherwise meet it closes.

| Item | Where | Found by | Suggested owner |
|---|---|---|---|
| `Array.chunked` / `Array.sliding` are written with `while`, which checked code rejects as not in scope — **decided 2026-09-17: rewrite them with `loop (condition)`** ([decision 8](./08-review-backlog/decision-8-language.md) §10) | `libs/std/src/primitives.bp` | 1.0.4-beta erlang | a one-off `libs/std` edit the maintainer assigns, or 12 step 3 |
| `delegate` and `new` stop being keywords (`throw Error(…)`, not `throw new Error(…)`); the unmapped `.@"const"` token variant is deleted; the VS Code grammar stops highlighting `delegate` and `new` — **decided 2026-09-17** | `src/lexer.zig`, `src/lexer/token.zig`, `src/parser/exprs.zig`; `repository/vscode-extension/syntaxes/botopink.tmLanguage.json` | 1.0.4-beta 11 | 06 (lexer/parser) + 14 (grammar) |
| JS-4's codegen half: once 06 N11 lands, a `ctor` destructuring lowers to a real JS test-plus-destructure and `Pattern.match` goes — [`01-backend-residuals/pattern-binding.md`](./01-backend-residuals/pattern-binding.md) | `src/codegen/commonJS.zig`, `src/codegen/js/**` | 1.0.4-beta js-bridges | 01 step 6 (decision 8's `case` arms reach the same code) |
| **`hover_interface_method`** — **decided 2026-09-17:** `*from behavior Signed (via I32)*` (the vocabulary of 12) | `modules/language-server/src/engine.zig` | 1.0.2-beta review-tooling (report 3.12) | 14 |
| A missing dependency (`:171`) and an unreadable `files` entry (`:210`) swallowed by the language server with `catch continue` — the CLI half landed with 05 step 5 | `modules/language-server/src/project_graph.zig` | 1.0.2-beta library-repos, re-confirmed by 05 | none until 12; a one-line follow-up |
| The block-as-value lowerings left dead in all four backends once 06 enforces decision 2 | `erlang.zig`, `beam_asm.zig`, `commonJS.zig`, `wat.zig` | decision 2 | 01 step 6 |
| `wrong-output` rows that survive 08's wave A after their backend front has closed | the backend files | 08 | the next milestone, by name |
| `src/comptime/template_eval.zig`, `src/comptime/decorator_eval.zig` (owned by 1.0.2-beta comptime-dispatch, landed) | — | — | 06 claims them if types-as-values A4 takes the `erl` path; 09 may take the transport-error one-liner |
| **commonJS: a sibling-module import inside a dependency is emitted as `require("../module")`** — `emilia-card`, `jhonstart-counter`, `jhonstart-todo` build but fail at run time `Cannot find module '../module'` (`jhonstart/hooks.bp`, `emilia/emilia.bp` importing `Element`) | `src/codegen/commonJS.zig` (the require path of a dependency's sibling module) | 13 examples fix, 2026-09-17 | 12 while it holds `codegen/**`, else 01 step 6 |
| **erlang: an imported function is called unqualified** (C1) — `import { twice };` from a sibling module, a package module or `test/` emits `twice(X)` → `function twice/1 undefined`; also an imported record's method (`thenReturn/2` of onze's `OnzeStub`). Blocks the erlang cells of jhonstart and onze | `src/codegen/erlang.zig` `callNode` receiver-less fallback (~`:4223`), `collectImportedTypes` (~`:2565`) ignoring `.@"fn"`; instance-method fallback (~`:4282`) | 13 erlang-cells investigation, 2026-09-17 | 12 while it holds `codegen/**`, else 01 step 6 |
| **erlang: a record field of function type called as a method** (C2) — `c.set(9)` on `{ set: fn(n: i32) }` emits `set(C, 9)` instead of `(maps:get(set, C))(9)`; jhonstart's hooks | `src/codegen/erlang.zig` `callNode` receiver path (~`:4282–4300`) | 13 erlang-cells investigation | 12 while it holds `codegen/**`, else 01 step 6 |
| **`MissingExternalTarget` has no location and no function name** — the CLI prints only the error name | `src/codegen/erlang.zig` (~`:4183`) + the CLI rendering | 13 erlang-cells investigation | 06 (diagnostics) or 01 |
| **A library cannot ship an erlang host module** (`.erl`), only `.mjs` sidecars — prerequisite for any erlang port of rakun's `runtime.mjs` / HTTP server | `modules/compiler-cli/src/cli/libs.zig` (`shipMjsSidecars` has no `.erl` counterpart) | 13 erlang-cells investigation | a CLI follow-up; rakun's erlang cell stays allow-fail until then |
| Erlang cells after the investigation (2026-09-17): emilia **17/17** (`8f93475`), erika 31/31 now a hard cell (`81e1f1c`), onze past `MissingExternalTarget` (`4707c83`) and blocked on C1, jhonstart blocked on C1/C2, rakun needs host modules | the libraries | — | 13 per library once C1/C2 land |
| **Labels are lost when a generic labeled return is instantiated** — `fn ref<T>() -> #(current: T)`; `r.current` → "no element labeled" (jhonstart uses `r.0`) | `src/comptime/infer.zig` (label propagation through instantiation) | 13 jhonstart migration, 2026-09-17 | 06 (N24) |
| **A label access on a lambda parameter inside a template body is not rewritten** — `t.kind` reaches comptime erlang as `maps:get` → `badmap` (jhonstart's html uses `t.0…t.6`) | `src/comptime/infer.zig` / template lowering | 13 jhonstart migration (also 12 step 2's risk) | 06 (N24) |
| **The formatter cannot keep source order and trivia the AST does not record**: payload variants move before sections (emilia's `Token`), an end-of-line comment on a field or array element moves to the next line, blank lines inside `loop` bodies and `if` branches are dropped — `format` output compiles and is stable (`botopink-lang` `6bf0817`), but the parser keeps no member positions or trailing trivia | `src/parser/{decls,exprs}.zig` (positions / trailing comments), then `src/format.zig` | formatter follow-up, 2026-09-17 | 06 (parser files), then a formatter pass |
| **A tuple label does not resolve on a lambda parameter or an array element, even with an annotated type**, and a label access in an untyped comptime body lowers to `maps:get` (`badmap`) — erika reads rows with `val #(a, b) = r` and tokens positionally | `src/comptime/infer.zig`, comptime lowering | 13 erika migration | 06 (N24) |
| **`#[@external(node, "…")]` in lower case passes `check` and binds no host, silently** — only `External.<Target>` matches `FnDecl.isExternal`; it should be a located error | `src/parser/**` (the annotation grammar) | 09 step 5 sweep, 2026-09-17 | 06 |
| **Two tests in `codegen/tests/externals.zig` (`:53`, `:65`) are named for an equivalence the compiler does not implement** — renaming moves snapshots | `src/codegen/tests/externals.zig` | 09 step 5 sweep | 08 |
| `libs/std/**` code, beyond the rows above | — | — | none until 12; stop and report |

Closed on 2026-09-17: `String.split("")` and the `builtins.d.bp` `@print` doc (std-split `c8c2541`);
rakun's `exports.Rakun` (verified by 10 step 4); `$0` vs `$self` ([decision 5](./08-review-backlog/semantics-decisions.md#decision-5),
implemented by 12 step 3). Owned since 1.0.2-beta: `comptime/error.zig`'s `┌─ :L:C` → 06 N9.

<a id="old-front-numbers"></a>

## Old front numbers

The carried deep dives cite fronts by their old numbers. Map them here.

| Old | Name | In 1.0.4-beta |
|---|---|---|
| 1.0.2-beta F1 | comptime-dispatch | **delivered** (steps 1, 2; the beam half of step 2 with 1.0.4-beta beam); step 3 → [`06-checker`](./06-checker/README.md) N1 |
| 1.0.2-beta F2 | cli-gate | **delivered**; residuals → [`05-cli-residuals`](./05-cli-residuals/README.md), **delivered** |
| 1.0.2-beta F3 | std-surface | **delivered**; its backend residuals delivered with 1.0.4-beta beam, erlang, js-bridges; 05 step 5; its `external-annotations.md` → [`06-checker`](./06-checker/external-annotations.md) |
| 1.0.2-beta F4 | beam | = 1.0.4-beta first 01 beam, **delivered** `a743955`; residuals → [`01-backend-residuals`](./01-backend-residuals/README.md) |
| 1.0.2-beta F5 | erlang | = 1.0.4-beta 02 erlang, **delivered** `42429dc`; residuals → [`01-backend-residuals`](./01-backend-residuals/README.md#routed-out) |
| 1.0.2-beta F6 | wasm | = 1.0.4-beta 03 wasm, **delivered** `ed15323`; residuals → [`01-backend-residuals`](./01-backend-residuals/README.md) |
| 1.0.2-beta F7 | checker | [`06-checker`](./06-checker/README.md) |
| 1.0.2-beta F8 | js-bridges | = 1.0.4-beta 04 js-bridges, **delivered** `bd7836c`; residuals → [`01-backend-residuals`](./01-backend-residuals/README.md) |
| 1.0.2-beta F9 | review-tooling | steps 1–3 **delivered**; step 4 → [`08-review-backlog`](./08-review-backlog/README.md) |
| 1.0.2-beta F10 | comptime-dedup | [`07-comptime-dedup`](./07-comptime-dedup/README.md) |
| 1.0.2-beta F11 | hygiene | [`09-hygiene`](./09-hygiene/README.md) (steps 1, 3, 6 **delivered**) |
| 1.0.2-beta F12 | library-repos | [`10-library-repos`](./10-library-repos/README.md), **delivered** |
| 1.0.4-beta 01–04 (until 2026-09-17) | beam, erlang, wasm, js-bridges | **delivered**; handoff ids (`B…`, `E…`, `W…`, `C…`, `JS-…`, `H…`) cited by the carried documents are closed unless [`01-backend-residuals`](./01-backend-residuals/README.md) names them (`BR5`, the `D8-…` rows) |
| 1.0.3-beta F1 | dead-keywords | **delivered** (compiler half, then [`11-dead-keywords-residual`](./11-dead-keywords-residual/README.md)) |
| 1.0.3-beta F2 | surface-cutover | [`12-surface-cutover`](./12-surface-cutover/README.md) |
| 1.0.3-beta F3 | ecosystem-migration | [`13-ecosystem-migration`](./13-ecosystem-migration/README.md) |
| 1.0.3-beta F4 | tooling-and-docs | [`14-tooling-and-docs`](./14-tooling-and-docs/README.md) |
