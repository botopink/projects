# Front 12 — Surface cutover (`type`, `behavior`, labeled tuples, separators)

**Status:** **delivered** 2026-09-17 (`botopink-lang` merge on `feat`, steps 1–4: `431f9bf` … `6a43124`, cold gate green with 7 library cells known-red, owner 13). **Reordered 2026-09-17 by the maintainer: 12 runs now, before 06.** 06 then writes its rules on the new AST instead of porting them twice. **Scope moved out:** the source migration that needs the checker to accept decision 8's forms — `Self<T>`, `#[@result] … -> @Result<T, E>`, annotations on `[]` that would fall to `unknown`, `while` → `loop (condition)`, `Display` for `Dict` — is [`../06-checker/`](../06-checker/README.md) step 9. Tuple labels (T1–T7) and decision 5's markers stay here. Carried from 1.0.3-beta front 02, amended by the maintainer's decisions of
2026-09-17: [decision 5](../08-review-backlog/semantics-decisions.md#decision-5) (positional template
markers), [decision 8](../08-review-backlog/decision-8-language.md) (tuple labels, `Self<T>`,
`@Result<T, E>`, `loop (condition)`, the source migration of `unknown`-falling declarations), and the
step-1 choices below (`DeclKind` `Type`/`Behavior` with no aliases, `InstanceLowering.type_`). Counts
and `file:line` were measured at `botopink-lang` `41981e3` and re-measured at `4eadb70` in [`remeasure.md`](./remeasure.md) — counts barely moved, but the
backend fronts added ~22 consumer sites step 1 must port and the document lists twelve risks (R1–R12)
the steps below do not yet cover; fold them in before step 1.

**Priority:** critical — the milestone's change. Four keywords (`record`, `enum`, `interface`, plus
the `record { }` literal) become two (`type`, `behavior`) and a tuple form, with one separator rule.
**Depends on:** nothing open — reordered ahead of 06, 07, 08, 01 steps 5–6 and 09's sweeps, which then work on the new surface. Nothing else touches `modules/compiler-core/src/**`, `libs/std/**` or `examples/**` while it runs (09's `fix/hygiene-build` is limited to `build.zig`'s `test-vscode` step and the lib-test-runner build files). [`../11-dead-keywords-residual/`](../11-dead-keywords-residual/README.md)
is delivered
**Owns:** `modules/compiler-core/src/**` (lexer, parser, `ast.zig`, `comptime.zig` and its embedded
prelude, `comptime/**` (the `.bp` prelude sources are `libs/std/src/*` embedded through `build.zig`, which is not this front's — [`remeasure.md`](./remeasure.md) R8), `format.zig`, `codegen/**` including
`crossModule.zig`, every Zig test source) · `modules/compiler-core/snapshots/**` ·
`modules/language-server/src/**` (compile-level changes, LSP snapshots) ·
`modules/compiler-cli/src/cli/resolver.zig` · `libs/std/**` · `examples/**` · `AGENTS.md` of every
directory touched
**Does not touch:** `repository/{emilia,erika,jhonstart,onze,rakun}/**` ([`../13-ecosystem-migration/`](../13-ecosystem-migration/README.md))
· language-server user-facing texts, `repository/vscode-extension/**`, user docs
([`../14-tooling-and-docs/`](../14-tooling-and-docs/README.md))

Deep dives:
- [`type-grammar.md`](./type-grammar.md) — the `type` declaration, shape resolution, field list, removed-keyword diagnostics, AST
- [`labeled-tuples.md`](./labeled-tuples.md) — `#(…)` replaces anonymous records; **its label rules are superseded by [decision 8](../08-review-backlog/decision-8-language.md) §6 (T1–T7): construction has no labels, written types may, `row.label` is a compile-time index**
- [`behavior.md`](./behavior.md) — `interface` → `behavior`
- [`separators.md`](./separators.md) — the comma rule and the formatter's canonical output
- [`remeasure.md`](./remeasure.md) — counts, drifted citations and risks at `4eadb70`

---

## Problem

Records and enums share nearly all of their structure — name, generics, `implement`, methods
stored as `InterfaceMethod`, construction by call — and differ only by body shape. Anonymous
records duplicate what tuples already are, with a second literal, a second type syntax and a second
runtime representation. Interface members accept three separator styles. The surface pays four
keywords and several spellings for things one rule can express.

## Why one front

`DeclKind` is a Zig tagged union (`ast.zig:1621`). Removing `.record`, `.@"enum"` or `.interface`
stops every `switch` and field access on them from compiling, including those behind `else =>`.
`zig build test` compiles compiler-core, language-server and compiler-cli together
(`build.zig:141–191`), so a worktree where only the parser moved does not build. Consumers of the
three variants, measured:

| File | Decl arms + type refs |
|---|---|
| `ast.zig`, `parser.zig`, `parser/decls.zig`, `lexer.zig` | 9 · 3 · 15 · 3 |
| `comptime/infer.zig`, `comptime/env.zig`, `comptime.zig`, `comptime/snapshot.zig` | ~36 · 4 · 13 · 3 |
| `format.zig` | 12 |
| `codegen/commonJS.zig`, `typescript.zig`, `erlang.zig`, `beam_asm.zig`, `wat.zig`, `crossModule.zig` | 10 · 6 · ~24 · ~22 · 5 · 2 |
| `language-server/src/engine.zig`, `project_index.zig` | ~20 (+ ~30 keyword-token uses) · 3 |
| `compiler-cli/src/cli/resolver.zig` | 3 |

The formatter reads only `ast.zig`; the backends read the untyped `ast.Program` after comptime's
transform. None of them depends on a comptime change — they depend on the AST node. So the front is
not cut by layer; it is cut into **commits**, each green under the pre-commit hook.

## Steps (one commit each, every commit green)

### Step 1 — Unified AST, old surface

Introduce `TypeDecl`/`TypeShape`/`Field`, `BehaviorDecl`/`BehaviorField`/`BehaviorMethod`,
`DeclKind.type_`/`.behavior` ([`type-grammar.md`](./type-grammar.md#ast),
[`behavior.md`](./behavior.md#scope)). The parser still accepts only the 1.0.2 surface and builds
the new nodes from it. Every consumer in the table above moves to the new nodes in this commit.

Decided 2026-09-17 by the maintainer, for this step:
- **The prelude's `DeclKind` becomes `Type` / `Behavior`** — no temporary `Record`/`Enum`/`Interface`
  aliases. Library comptime code that reads the old variants stops compiling here: rakun's 15
  `DeclKind.Record` checks (`src/decorators.bp`). Its `test-libs` cell is registered in
  `scripts/known-red-libs.txt` in this commit, owner [`../13-ecosystem-migration/`](../13-ecosystem-migration/README.md),
  and the line is deleted when 13 migrates rakun. The check rakun makes ("a type with fields") must
  stay expressible on the new `DeclKind`/`TypeShape` — verify before the commit.
- **The compiler's internal `InstanceLowering.record` tag (`comptime/env.zig`) is renamed after the
  new vocabulary — `.type_`** (and `.behavior` if a behavior-receiver arm exists or is split out), so
  the step's textual check reaches zero without an exception.

**Acceptance:**
- [ ] `RecordDecl`, `EnumDecl`, `InterfaceDecl`, `DeclKind.record/.@"enum"/.interface` no longer exist; `InstanceLowering` has no `.record` tag; the prelude's `DeclKind` names `Type`/`Behavior` only
- [ ] Generated code, diagnostics and `RUN LOG`s are unchanged; snapshot diffs limited to parser ids (`record_N`/`enum_N` → `type_N`, `interface_N` → `behavior_N`) and typed-AST JSON keys
- [ ] `zig build test` green

### Step 2 — Dual grammar (transitional, never released)

The parser accepts the 1.0.3 surface **alongside** the 1.0.2 surface, both producing the same nodes:
`type` with shape resolution and the shared field list, `behavior`, labeled tuples `#(x: 1)` and
`#(x: T)`, and the separator rule for the new keywords only (old `interface` bodies keep their
lenient separators until step 4). `record { }` literals and `{ x: T }` types keep their old runtime
in this commit; labeled tuples get the tuple runtime ([`labeled-tuples.md`](./labeled-tuples.md)).
The formatter prints **only** the 1.0.3 surface.

**Acceptance:**
- [ ] Every parser acceptance case in [`type-grammar.md`](./type-grammar.md#parser-acceptance-cases) that does not involve a removed keyword passes
- [ ] Every acceptance item in [`labeled-tuples.md`](./labeled-tuples.md#acceptance) passes on the four backends
- [ ] Every acceptance item in [`behavior.md`](./behavior.md#acceptance) and [`separators.md`](./separators.md#acceptance) except the removed-keyword ones passes
- [ ] Old-surface snapshots unchanged

### Step 3 — Migrate the sources

Migrate manually (beta phase — no automated codemod):
- every Zig test source in `modules/compiler-core/src` and `modules/language-server/src`: about 220 record, 92 enum and 82 interface declarations and 20 literals in `\\` blocks;
- the embedded prelude in `comptime.zig:541–594` and `comptime/stdlib/*.bp`;
- `libs/std/**` (22 records, 11 enums, 24 interfaces; `types.bp`/`reflect.bp` doc comments);
- `examples/**` (yamlconf's `@expr(record { … })`);
- about 25 single-line Zig test strings — edited by hand.
- **template markers** ([decision 5](../08-review-backlog/semantics-decisions.md#decision-5)): every `#[@External…]` template becomes positional-only — `$self` → `$0`, `$N` → `$N+1` on methods (≈55 in `libs/std/src/primitives.bp`, 3 in `builtins.d.bp`, plus the Zig `\\` test sources); the erlang, commonJS and beam renderers drop `$self`; the checker refuses `$self` and an out-of-range `$N` with a location. Scripted, in one commit with the renderers.
- **[Decision 8](../08-review-backlog/decision-8-language.md) in the sources — moved to [06 step 9](../06-checker/README.md) by the 2026-09-17 reorder, except tuple labels (T1–T7, here)**: `Self<T>` in generic declarations (§1.2); `#[@result] … -> @Result<T, E>` (and the other effect wrappers, §9); annotations on the `val`/`var … = []` that would fall to `unknown` (§1.4 — 5 in `libs/std`); `while` → `loop (condition)` (§10); tuple labels per T1–T7 (§6); `Display` for `Dict` (§7). The earlier rule for `Self`: in every generic `type` and `behavior`, `self: Self` → `self: Self<T>` and `-> Self` → `-> Self<T>` (`libs/std`'s `Array<T>` and the other generic primitive interfaces, the Zig test sources); a bare `Self` in a generic declaration is an error from step 4.

Re-run the suite; classify snapshots manually (source-only vs output-changed vs behaviour-changed).

**Acceptance:**
- [ ] No `record`, `enum`, `interface` keyword or `record {` literal left in the owned paths (manual verification)
- [ ] Source-only snapshots (only parser ids and typed-AST keys changed) accepted
- [ ] Output-changed snapshots (codegen changed, `RUN LOG` unchanged) reviewed per backend — expected only for anonymous-record fixtures moving to tuples — and accepted with the review note in the commit message
- [ ] Behaviour-changed snapshots (a `RUN LOG` or a diagnostic changed beyond keyword wording) are empty, or every entry is explained in the commit message
- [ ] No `$self` left; decision 5's acceptance holds (renumbering commit byte-identical in generated code and RUN LOGs)
- [ ] `zig build test` green; `zig build test-libs` std cell green

### Step 4 — Remove the old surface

Delete `record`, `enum`, `interface` from the lexer; delete the `recordLit` and `record_type` paths;
the parser raises the removed-keyword diagnostics
([`type-grammar.md`](./type-grammar.md#removed-keywords)); behavior bodies enforce the separator
rule; the generated comments naming a declaration (`%% interface Name`, `// interface Name`) say
`behavior` — deferred here so step 1 stays byte-identical (decided 2026-09-17). Update `AGENTS.md` of
every directory touched across the four commits.

**Acceptance:**
- [ ] `record P { x: i32 }`, `enum E { A }`, `interface I {}`, `record { x: 1 }`, `fn f(p: { x: i32 })` produce their targeted diagnostic with a location (one error snapshot each)
- [ ] `grep -rE '\b(record|enum|interface)\b'` over the owned `.bp` sources and Zig `\\` blocks matches only the removed-keyword diagnostic tests
- [ ] The 48 snapshots whose only output change is the `%% interface` / `// interface` comment are re-recorded in this commit and classified output-changed (comment only)
- [ ] `zig build test` green

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, at the tip of the front's worktree
- [ ] `zig build test-libs` std cell green (the five library cells are 13's)
- [ ] `botopink format --check` passes on `libs/std/**` and `examples/**`
- [ ] The formatter keeps a declaration's visibility and form: `pub interface Router { … }` does not come back as `val Router = interface { … }` (a bug found by front 11, decided 2026-09-17 — it drops `pub`); a format snapshot pins `pub behavior Router { … }` round-tripping
- [ ] Every commit of the front passed the pre-commit hook (no `--no-verify`)
- [ ] `AGENTS.md` of every directory touched, updated in the commit that touched it
- [ ] Branch `fix/surface-cutover`; no push, no merge

## Blast radius

| What | Count |
|---|---|
| `.bp` declarations in `libs/std` + `examples` | 60 |
| Declarations in Zig `\\` test sources (compiler-core + language-server) | ~423 + ~20 literals |
| Snapshot files (`*.snap.md`) | 2442 total; 688 carry a keyword in `SOURCE CODE`; parser JSON with `"record":` keys 59; typed-AST `record_def`/`enum_def`/`interface_def` 172/104/44 |
| Zig consumer files | ~20 (table above) |

Nothing outside `botopink-lang` changes in this front. The five libraries stop compiling against the
new compiler at step 4 — [`../13-ecosystem-migration/`](../13-ecosystem-migration/README.md) migrates them.

## Notes

- The dual grammar of step 2 exists only inside this branch. It is the tool that keeps every commit
  green; it is never merged without step 4.
- `type` keeps its meaning in type position (`comptime T: type`). Because anonymous record types
  become `#(…)`, no type-position `type {` or `type(` form is introduced and `-> type {` keeps
  parsing as "returns a type, then the body".
