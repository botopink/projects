# frente-a-compiler — backend correctness, codegen parity, deprecated-surface deletes

**Slug**: frente-a-compiler
**Depends on**: nothing (each track inside this frente has its own internal
  DAG; the trio of tracks here is parallel-safe at the file level — see
  "Internal ordering" below)
**Files**: `modules/compiler-core/src/{lexer,parser,ast,comptime,codegen,runtime}.zig`
  · `libs/std/src/{builtins,primitives}.d.bp` · `codegen/wat.zig` ·
  `modules/compiler-cli/src/cli/test_cmd.zig` (the wasm test gate at §C2) ·
  `libs/erika/src/erika.bp` · all touched `AGENTS.md`s + `CHANGELOG.md`
**Touches docs**: `modules/compiler-core/AGENTS.md` ·
  `modules/compiler-core/src/codegen/AGENTS.md` ·
  `modules/compiler-core/src/comptime/AGENTS.md` · `libs/std/AGENTS.md` ·
  `libs/erika/AGENTS.md`
**Status**: pending

## Background

Three prior sets left compiler-side tail items recorded:

- **v0.beta.14 — `backends-parity-tail`**: spec authored, branch merged, but
  the worktree's `TODO.md` was an accidental copy of `package-default-dsl`'s,
  so **W** (wasm wat refactor + wasm test runner + wasm `?.`), **E**
  (erika-LINQ on erlang/beam, blocker = generic inference), **F3**
  (erlang/beam carry `from "std"` imports) and **B** (beam inline-fun array
  methods: `join`/`indexOf`/`at`/2-arg `slice`/string `contains`/`startsWith`)
  never got ticked. Part of W maps onto v16 §C, part of E onto v16 §B; F3 and
  B have no later owner.
- **v0.beta.16 — `recorded-gap-sweep`**: §A's keystone refactor landed for
  A1–A5 (last commit `0a37fbe §A5 inline flag`). **§A6 + §A7** + **§B/§C/§D/§G**
  remain open. (§E/§F belong to Frente B; §H–§K belong to Frente C.)
- **v0.beta.12 — `effect-annotations`**: `*fn` was replaced by `#[@<effect>]`
  byte-identically. Every `.bp` / `.d.bp` in `repository/` is migrated; what
  remains is the **compiler internals** — lexer/parser/AST still accept `*fn`,
  `EffectKind.fromStarReturn` derives the effect from a `*fn`-prefixed body,
  Zig test fixtures in `codegen/tests/js_*.zig` author `*fn` literals.
- **Live audit (2026-06-13)**: 15 standalone fns + 8 `@<tag>` markers in
  `libs/std/src/builtins.d.bp` have **zero authored callers** anywhere in
  `repository/**.bp` + `repository/**.d.bp` — declared surface area with no
  demand.

This frente owns all the above. Three internal tracks:

| Track | Closes | Description |
|---|---|---|
| **§A–§D + §G** (codegen tail) | v14 W/E/F3/B + v16 §A6/§A7/§B/§C/§D/§G | The recorded codegen gaps consolidated under one track |
| **§S** (`*fn` removal) | v12 cleanup | Delete the `*fn` prefix lexer/parser/AST path + rewrite `\\*fn` test fixtures |
| **§U** (unused-builtin removal) | live audit | Delete every builtin declaration in `builtins.d.bp` with zero authored callers, plus its comptime handler |

## Internal ordering

```text
§A (keystone)  ──▶  §B  ──▶  §D
§A             ──▶  §C  (independent of §B; both can land after §A)
§A             ──▶  §G  (erika DSL extensions, file-disjoint)

§S (*fn removal)         — parallel with everything above; touches lexer/parser/AST
§U (unused-builtin sweep) — parallel; touches builtins.d.bp + comptime handlers
```

- **§A lands first** (byte-identical refactor that §B + §D consume).
- **§B/§C/§D parallelise** after §A; **§G** is file-disjoint and can land any
  time.
- **§S and §U** are file-disjoint from every other track. Schedule courtesy:
  if §S and §U both touch `codegen/tests/js_*.zig` fixtures (§S rewrites
  `*fn` literals; §U may remove builtin calls from fixtures), land them
  sequentially to avoid mechanical merge churn — not a true dependency.

---

## §A — annotation-driven-builtins tail (close v0.beta.16 §A6 + §A7)

**Files**: every `.d.bp` that declares a primitive method ·
`codegen/{commonJS,erlang,beam_asm}.zig` · `comptime/infer.zig` ·
`libs/std/AGENTS.md` · `comptime/AGENTS.md` · `codegen/AGENTS.md` ·
`tests/codegen/primitive_methods_byte_identical.zig` (new)

The keystone refactor (A1–A5) made the emitters consult `#[@external]`
annotations instead of hardcoded switches. A6 finishes the migration; A7
proves the single-source-of-truth invariant.

- [ ] **A6** — Migrate every remaining primitive method that still relies on a
      hardcoded entry: re-grep `repository/botopink-lang/modules/compiler-core/src/codegen/`
      for the surviving `prim_*` switches / fallback arms and either author the
      annotation in `primitives.d.bp` + delete the switch arm, or document the
      *irreducible* allow-list (BEAM `++` ops, list-cons, BIF aliases,
      atom-arg `split`, register-juggling `slice`, inline funs — already
      stable). Acceptance bar: `zig build test` snapshot diff is empty against
      `feat` HEAD before this section.
- [ ] **A7** — `tests/codegen/primitive_methods_byte_identical.zig` adds a
      *new* primitive method (e.g. `Array.zip<U>(self, other: U[]) -> [T, U][]`)
      via **one** `#[@external(...)]` annotation in `primitives.d.bp`. The
      test compiles a fixture using it on all four targets and asserts the
      emitted code without editing any `.zig`. Update `libs/std/AGENTS.md`,
      `comptime/AGENTS.md`, `codegen/AGENTS.md` to declare the contract.

## §B — generic-inference (close v0.beta.14 E + v0.beta.16 §B)

**Files**: `comptime/{infer,unify,types}.zig` · `libs/std/AGENTS.md` ·
`libs/std/src/{order,sets,dict,queue}.bp` (re-fold external inline tests)

The blocker pinned in `project_generic_inference_gap`: inline `test { … }` in
generic stdlib modules fails with `.generic TypeError`; same machinery blocks
erika-LINQ's `default fn` bodies (`self.forEach`/`self.length` on `Self =
array`) from emitting on erlang/beam.

- [ ] **B1** — Resolve `Self`'s primitive kind inside an interface
      `default fn` body. In `comptime/infer.zig` `instance_lowering`, when the
      enclosing interface is a primitive (Array/string/numeric/Bool — known
      via `primitiveInterfaceName`), substitute `Self`'s kind from the call-site
      receiver before re-typing the body. Records `instance_lowerings` so §D's
      instance default fn emission on erlang/beam can pick them up.
- [ ] **B2** — Instantiate callee generic vars before `unifyAt` so a generic
      inline `test { … }` re-uses the module's `<T>` for the test's local
      bindings. Then fold the externalised `*_test.bp` shadow files back to
      inline `test` blocks inside `order.bp` / `sets.bp` / `dict.bp` /
      `queue.bp`.
- [ ] **B3** — Fix the `variable 'B' is unbound` codegen bug surfaced by the
      LINQ pipeline. Trace the generic var through `lowerLinqPipeline` →
      emitter and ensure the `B`-binding lambda's free vars are captured.
- [ ] **B4** — Once B1+B3 land, emit each primitive interface's **instance**
      `default fn`s on erlang and beam (mangled like the associated ones).
      erika's commonJS test set must stay green; the pre-existing erlang LINQ
      red flips to green.
- [ ] **B5** — Drop the generic-module inline-test caveat in
      `libs/std/AGENTS.md`; add inference unit tests for B1/B2 in
      `modules/compiler-core/src/comptime/tests/`.

## §C — wasm-aggregates + wat stack-discipline (close v0.beta.14 W + v0.beta.16 §C)

**Files**: `codegen/wat.zig` · `modules/compiler-cli/src/cli/test_cmd.zig` ·
`codegen/AGENTS.md` · `snapshots/codegen/wat/` (new fixtures)

`wat.zig` is currently the only backend that can't run a typical test fixture:
the emitter is untyped, void builtins underflow the stack, and named
record-field access stubs to `i32.const 0`.

- [ ] **C1 (was v14 W)** — Track per-expression "produces a value" in the wat
      emitter. Classifier: `@print`/`@panic`/`@todo`/void-returning calls
      produce nothing; everything else produces one i32. Drop only
      value-producing statement-exprs; for a **void** function
      (`f.returnType == null`) the last statement is not the return, so drop
      its value too. Thread `returns_value` into `emitBody`.
- [ ] **C2 (was v14 W)** — Once C1 lands, wire `botopink test --target wasm`.
      `test_cmd.zig:46` currently gates to commonJS/erlang only; wasm
      test-mode codegen must emit the `__bp_run_tests` entry and the CLI must
      invoke it via `wasmtime` (single-module gate is fine — see C5).
- [ ] **C3 (v16 §C1+§C2)** — Record field layout: stable 4-byte slot offsets
      per declared field order; constructor stores at offset; `recv.field` /
      `self.field` load `base + offset`; field assign stores.
- [ ] **C4 (v16 §C3)** — `?.` on wasm: guards the base against null, reads the
      slot. Remove the JS-style short-circuit stub.
- [ ] **C5 (v16 §C4)** — Keep the wasm single-module rule on record in
      `codegen/AGENTS.md`. Cross-module linking is out of scope for v0.beta.19.
- [ ] **C6 (v16 §C5)** — Update `codegen/AGENTS.md`; add `.wat` snapshots
      asserting field layout + `?.` byte sequences.

## §D — cross-backend feature parity (close v0.beta.14 F3+B + v0.beta.16 §D)

**Files**: `codegen/{erlang,beam_asm,commonJS}.zig` ·
`libs/std/src/builtins.d.bp` (add `console.log` / `new Error` `#[@external]`) ·
`libs/std/src/primitives.d.bp` (add missing BEAM annotations) ·
`codegen/AGENTS.md` (erlang+beam "Remaining gaps")

After §A makes emitters annotation-driven, the cross-backend gaps are *wiring*,
not new switches.

- [ ] **D1 (v16 §D-D1)** — `console.log` + `new Error(…)` declared as host
      forms via `#[@external]`, lowered by reading the annotation in each
      emitter. (`print` already lowers — extend, don't fork.)
- [ ] **D2 (v16 §D-D2 + v14 F3)** — Cross-module fn imports lower to remote
      call into the owner module on erlang first, then beam. Same change
      unblocks "erlang/beam resolve `from "std"` imports" — once
      cross-module fn-call is correct, std modules load identically to node.
- [ ] **D3 (v16 §D-D3)** — Typed-value method dispatch: `p.parse(x)` where
      `p: Parser` lowers to `'Parser_parse'(P, X)` (the mangled associated-fn
      form) on erlang and beam, not the bare-call fall-through.
- [ ] **D4 (v16 §D-D4)** — `#[@future]` lowering on erlang/beam: spawn the
      body as a process, return a `Future` handle whose `await` joins.
      **Surface contract for `@Future<T, E>` is authored by Frente B**
      (`frente-b-rules-tooling §1F`); this section implements the
      erlang/beam side. If too large for v0.beta.19, **explicitly scope to a
      follow-up** and update `codegen/AGENTS.md` "Remaining gaps" with a
      one-line "future emitter pending" note.
- [ ] **D5 (v14 B)** — BEAM inline-fun array/string methods: emit `join`
      (`iolist_to_binary∘lists:join` + per-element stringify fun), `indexOf`,
      `at` (bounds-safe `lists:nth`), 2-arg `slice` (`lists:sublist` with
      `start+1`/`end-start` arithmetic), string `contains`/`startsWith`. Each
      needs an emitted helper fun or arity arithmetic on BEAM — mirror the
      erlang `emitPrimMethod` shapes already in `erlang.zig`.
- [ ] **D6 (v16 §D-D5)** — Update beam + erlang AGENTS "Remaining gaps"
      sections; add cross-backend snapshots for D1–D3 + D5; sweep the
      `negation_in_expression gc_bif Live count` note pinned in
      `codegen/AGENTS.md:57`.

## §G — erika DSL extensions (close v0.beta.16 §G)

**Files**: `libs/erika/src/erika.bp` · `comptime/transform.zig` (the existing
`q.parts()` / `q.lookup()` plumbing) · `libs/erika/AGENTS.md`

`erika "select … ${value} …"` and the `var` string form (DSL via a runtime
string) are both recorded as deferred in `libs/erika/AGENTS.md` "Recorded gaps".

- [ ] **G1 (v16 §G1)** — Lower `${expr}` interpolations inside an `erika`
      template literal. Use the existing `Part.Interp` machinery in
      `@Expr<string>`; emit each `Text` / `Interp` segment into the runtime
      query builder. The string holes follow the language's `+` coercion (no
      new operator).
- [ ] **G2 (v16 §G2)** — The `var s = "select ..."; erika s` form resolves
      `s`'s contents at runtime — pure generic mechanism (no erika-specific
      code in the core; reuses comptime scope-snapshot for the string view).
- [ ] **G3 (v16 §G3)** — Update `libs/erika/AGENTS.md` "Recorded gaps" (remove
      both items); add `.bp` tests under `libs/erika/tests/` for both forms.

## §S — remove the deprecated `*fn` prefix (close v0.beta.12 cleanup)

**Files**: `modules/compiler-core/src/lexer.zig` ·
`modules/compiler-core/src/parser/decls.zig` ·
`modules/compiler-core/src/ast.zig` (`EffectKind.fromStarReturn`, the
`is_star` field, `*fn` docstrings) ·
`modules/compiler-core/src/codegen/{commonJS,erlang,beam_asm,wat}.zig`
(`// *fn …` / `%% *fn …` comment lines) ·
`modules/compiler-core/src/codegen/tests/js_builtins.zig` ·
`modules/compiler-core/src/codegen/tests/js_control_flow.zig` (the `\\*fn …`
fixture literals) · `docs.md` at the workspace root · `CHANGELOG.md`

v0.beta.12 (`d09e4ea`) replaced `*fn` with `#[@<effect>]` markers byte-
identically. `grep -rE '^\s*\*fn\b' repository/ --include='*.bp' --include='*.d.bp'`
returns zero results today (verified). What remains is **inside the compiler**:
lexer, parser, AST, four codegen comment lines, two Zig test files. Hard
delete — no shim, no warning period; v12 was the deprecation window. After
this lands, `*fn` parses as a syntax error.

### Target syntax

```bp
// allowed (after this lands)
#[@result] fn parse(n: i32) -> @Result<i32, string> { … }

// rejected with a clear migration error (after this lands)
*fn parse(n: i32) -> @Result<i32, string> { … }
```

Diagnostic for the rejected form:

```
error[deprecated-star-fn]: the `*fn` prefix was removed in v0.beta.19.
  --> file.bp:3:1
   |
 3 | *fn parse(n: i32) -> @Result<i32, string> { … }
   | ^^ use a `#[@<effect>]` annotation instead.
   |
   = note: the effect was inferred from the return wrapper (@Result → #[@result]).
   = help: rewrite as: #[@result] fn parse(n: i32) -> @Result<i32, string> { … }
```

Parser-level (not "missing token" gibberish). The help line names the effect
the legacy `EffectKind.fromStarReturn` would have derived, so a user
migrating from an old codebase can do the rewrite mechanically.

### Steps

- [ ] **S0** — `git grep -nE '\*fn\b' repository/` captures the surface for
      the commit message. Expected: lexer, parser/decls, ast, 4 codegen
      comments, 2 test files. `git grep -nE '\*fn\b' repository/botopink-lang/libs repository/erika repository/jhonstart repository/onze repository/rakun` sanity-checks zero hits in authored `.bp` / `.d.bp` — abort if any.
- [ ] **S1** — `lexer.zig`: drop the `*` lookahead path. `parser/decls.zig`:
      at the fn-decl entry, replace the `is_star = true` block with the
      `deprecated-star-fn` diagnostic. The diagnostic references
      `EffectKind.fromStarReturn(...)` so the migration help line can name
      the effect.
- [ ] **S2** — `ast.zig`: delete `EffectKind.fromStarReturn` (around lines
      1626–1647) and `FnDecl.is_star` if it exists separately from `effect`.
      Update docstrings (`EffectKind`, `FnDecl.effect`, `FnDecl.effectAnnotation`,
      `FnDecl.returnsResult`) to drop the "(deprecated `*fn`)" halves. If
      `effect` and `effectAnnotation` agree post-deletion, collapse
      `effectAnnotation` into `return this.effect`.
- [ ] **S3** — Codegen comment lines:
      - `codegen/commonJS.zig` lines around 702 / 1658 / 2139 / 2252: rewrite
        `*fn` mentions as `#[@iterator]` / `#[@generator]`.
      - `codegen/erlang.zig:867` and `codegen/beam_asm.zig:852`:
        `"%% *fn (async/generator) — eager lowering\n"` →
        `"%% #[@future] / #[@asyncGenerator] — eager lowering\n"`.
      - `codegen/wat.zig`: no `*fn` mentions today — re-grep at commit time.
- [ ] **S4** — Test fixtures: `codegen/tests/js_builtins.zig` (5 `\\*fn`
      literals) and `codegen/tests/js_control_flow.zig` (~30 `\\*fn`
      literals). Each line `\\*fn …` becomes two: `\\#[@result]` then
      `\\fn …`. Re-run `zig build test` after each file's rewrite — emitted
      output must stay **byte-identical** (v12's migration promise covers
      this).
- [ ] **S5** — Docs + AGENTS: `modules/compiler-core/AGENTS.md` drops `*fn`
      mentions; `libs/std/AGENTS.md` effect-annotations subsection drops
      "(replaces the deprecated `*fn` prefix)"; `CHANGELOG.md` adds one
      `BREAKING:` line.
- [ ] **S6** — Green gate: `git grep -nE '\*fn' repository/` yields only the
      CHANGELOG line. `zig build test` + `botopink-lib-test` green. An
      end-to-end test under `modules/compiler-core/src/parser/tests/`
      asserts the `deprecated-star-fn` diagnostic text exactly.

### Notes — §S

- **Hard delete, no warning period.** v0.beta.12 was the warning. No
  authored `.bp` in `repository/` uses `*fn` today; keeping the parser path
  around just rots.
- **Diagnostic before deletion.** Don't delete `EffectKind.fromStarReturn`
  before the parser diagnostic ships, or `*fn` typers see an inscrutable
  "expected `fn`" error.

## §U — remove unused stdlib builtins (live audit)

**Files**: `libs/std/src/builtins.d.bp` (delete the unused fn declarations) ·
`modules/compiler-core/src/comptime/{builtins,infer,transform}.zig` (delete
handlers) ·
`modules/compiler-core/src/codegen/{commonJS,erlang,beam_asm,wat,typescript}.zig`
(delete any per-backend lowering) · `libs/std/AGENTS.md` ·
`modules/compiler-core/AGENTS.md` · `CHANGELOG.md`

A grep across `repository/**.bp` + `repository/**.d.bp` (executed 2026-06-13)
finds **15 fns + 8 tags** with **zero authored callers**. Declared surface
area with no demand. Delete them. The grep evidence + handler removal travel
in one commit per builtin.

### Survey (2026-06-13 — re-grep at execution time)

**Standalone fns (15)**

| fn | Declaration | Compiler handler hits | Authored callers |
|---|---|---|---|
| `typeOf<T>(val: T) type` | `builtins.d.bp:4` | 1 | 0 |
| `typeName(comptime T: type) string` | `:5` | 1 | 0 |
| `sizeOf(comptime T: type) i32` | `:6` | 2 | 0 |
| `alignOf(comptime T: type) i32` | `:7` | 1 | 0 |
| `hasField(comptime T, comptime name: string) bool` | `:8` | 0 | 0 |
| `hasDecl(comptime T, comptime name: string) bool` | `:9` | 0 | 0 |
| `tagName<T>(val: T) string` | `:11` | 1 | 0 |
| `min<T>(a: T, b: T) T` | `:32` | 1 | 0 |
| `max<T>(a: T, b: T) T` | `:33` | 2 | 0 |
| `abs<T>(val: T) T` | `:34` | 4 | 0 |
| `block<T>(body: fn() -> T) T` | `:136` | 8 | 0 |
| `src() string` | `:142` | 1 | 0 |
| `compilerError(message: string) noreturn` | `:149` | 2 | 0 |
| `embedFile(comptime path: string) string` | `:166` | 1 | 0 |
| `root() module` | `:161` | 0 | 0 |

**`@<tag>` markers (8)**: `@AsyncIterable`, `@trap` (capture-tag only —
`trap()` itself has 1 use), `@src`, `@root`, `@module` (capture-tag only —
`module()` itself has 8 uses), `@embedFile`, `@compilerError`, `@as`.

**KEEP** (non-trivial demand): `field` (2 callers), `trap` (1), `module` (8),
`external` (115), `panic` (many via `@panic`), `emit` (many via `@emit`), all
6 effect annotations (kept by Frente B), the `Yield`/`AsyncIterator`/
`Generator`/`Iterable`/`Future` interface declarations.

### Steps

- [ ] **U0** — Re-run the candidate grep at execution time. Update the
      survey if any candidate now has a caller — abort that candidate.
      Capture the final counts in the commit body so the audit is
      self-contained.
- [ ] **U1** — Per confirmed-unused fn: delete the declaration; delete the
      handler in `comptime/{builtins,infer,transform}.zig`; delete any
      per-backend lowering; update `libs/std/AGENTS.md` +
      `modules/compiler-core/AGENTS.md` rows. One commit per candidate:
      `refactor(std): remove unused builtin '<name>'`.
- [ ] **U2** — For each unused `@<tag>`: same as U1, except the removal site
      is the comptime tag registry. The six effect tags (`@result`,
      `@future`, `@generator`, `@iterator`, `@asyncGenerator`, `@context`)
      are explicitly **KEPT**.
- [ ] **U3** — Sweep `builtins.d.bp` comment-block headers (`// ── numeric
      ──` etc.); delete orphaned subsections.
- [ ] **U4** — `CHANGELOG.md`: one grouped `BREAKING:` line listing every
      removed name.
- [ ] **U5** — Gate: `zig build test` + `zig build test-libs` +
      `botopink-lib-test` green. Final audit: a fresh `git grep` finds each
      deleted symbol only in CHANGELOG.md.

### Notes — §U

- **Why hard delete vs soft deprecation.** Zero callers = zero evidence the
  design is right = remove. Re-adding takes 5 minutes; carrying half-
  implemented behaviour is not free.
- **`compilerError` looks load-bearing** but it's redundant with
  `q.fail()` / `decl.fail()` (handle methods, many callers). Delete; if a
  no-handle context needs it, re-add.
- **`@module` tag vs `module()` fn**: the fn `module()` stays (8 callers);
  the `@module` *capture-tag* goes (zero authored uses).

---

## Test scenarios (whole frente)

```
A6      ---- existing snapshot suite green; surviving prim switches all justified in AGENTS
A7      ---- new prim method 'Array.zip' lowers on commonJS+erlang+beam with zero .zig edits
B1      ---- erika instance default fn for Array typechecks under inference; commonJS still green
B4      ---- erika test-libs row flips from red→green on erlang and beam
C2      ---- botopink test --target wasm runs a 1-test fixture under wasmtime → exit 0, 1/1 pass
C3      ---- self.id reads the right slot under a stable record layout (snapshot)
D2      ---- a fixture that calls `from "std"` order.bp lowers on erlang+beam (was red)
D5      ---- BEAM emitPrimMethod handles xs.join(", "), xs.at(2), s.contains("foo")
G1      ---- `erika "select * from u where id = ${uid}"` lowers the interp segment
S1      ---- `*fn foo() -> @Result<…>` reds with `deprecated-star-fn` + the migration help line
S4      ---- both js_*.zig tests pass with the rewritten `#[@<effect>]` fixtures; emitted output byte-identical
S6      ---- `grep -nE '\*fn' repository/` yields only the CHANGELOG line
U0      ---- live grep reports zero callers for every confirmed-delete candidate
U1+U2   ---- per-candidate commit: declaration + handler removed; snapshots unchanged
U5      ---- a fresh `git grep` finds each deleted symbol only in CHANGELOG.md
gate    ---- `zig build test` + `zig build test-libs` + `botopink-lib-test` all green
docs    ---- every touched AGENTS.md updated in the same commit (memory rule)
```

## Notes

- **Coordination with Frente B.** §D-D4 (`#[@future]` erlang/beam) consumes
  the surface contract authored by Frente B's `frente-b-rules-tooling §1F`.
  Schedule: Frente B's `effect-annotation-rules` block lands first; §D-D4
  reads it. §S's deletion of `*fn` is parallel — Frente B doesn't depend on
  the `*fn` path still existing.
- **No `--no-verify` ever.** Pre-commit gate must stay green at every commit.
- **AGENTS.md in the same commit as the code it documents.** Memory rule.
- **Per-memory:** SSH for all git remote ops; worktree paths for Read/Edit;
  commit messages in English; functions in camelCase; implement in `.bp`
  when possible.
