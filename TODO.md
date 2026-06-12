# TODO — recorded-gap-sweep (v0.beta.16)

> Task branch `task/recorded-gap-sweep` · spec
> [`tasks/v0.beta.16/specs/recorded-gap-sweep.md`](tasks/v0.beta.16/specs/recorded-gap-sweep.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test.
> Seven file-disjoint sections §A–§G; **§A lands first** (keystone refactor, byte-identical output).

Goal: sweep the deliberately-recorded, deferred gaps into one wave. Each section closes a cited
`AGENTS.md` "KNOWN GAP" / "Recorded gaps" / backend "Remaining gaps" note or a prior spec non-goal.

## §A — annotation-driven-builtins (keystone) — byte-identical output is the bar
- [x] A1 — `Target` enum (capitalised variants) in `builtins.d.bp`; parser folds
      `Target.Erlang` / `.Erlang` into a single annotation arg and `externalTargetMatches`
      compares case-insensitively, so bare `erlang` keeps working (back-compat).
- [x] A2 — keyword-arg form + call template: parser drops `runtime:`/`module:`/`method:`
      labels (Form B normalises to Form A); 2-arg shorthand (`@external(Target.Node, "sym")`)
      means "emit prototype directly, no host module"; `ast.parseExternalCallTemplate` splits
      `"sym(arg, self)"` into `(symbol, ordered arg names incl. self)`; bare symbol ⇒ decl order.
- [x] A3 — return types from the `fn` signature: `primMethodReturnTypeFromIface` walks
      the receiver's primitive interface (+`extends` chain), reads the method's declared
      `returnType` and resolves it via `resolveTypeRefInContext` with `Self`/`T`/method
      generics substituted; `val length: T` is read as a property (intrinsic) and the
      `len`/`size` aliases route to the same field. Hardcoded `primMethodReturnType` table
      deleted; output byte-identical (zero snapshot diff).
- [x] A4 — node: drive `commonJS.zig` native emission from `@external(Target.Node, "X")`.
      `primitives.d.bp` carries the 2-arg annotation on every primitive method whose JS
      counterpart is a native prototype method (rename or same-name skip);
      `isNativeProtoMethod` deleted (the loop now skips a method when its annotation has
      an empty module — single skip-rule); `jsStringMethodRename` deleted (inference's
      `primMethodNodeRename` walks the receiver's interface + `extends` chain and records
      a per-loc rename, type-directed); `jsBuiltinMethodName` replaced by the emitter's
      `prim_node_renames` map (built from interface annotations with a record-method
      collision filter; seeded with the three known-safe pairs so `emitFnJs`'s standalone
      path used by comptime template eval picks them up too). Output byte-identical
      (zero snapshot diff); `jsMethodRenames` and `jsPrototypeOwner` kept as the per-loc
      type-directed channel and JS-constructor map respectively.
- [ ] A5 — erlang/beam: replace `emitPrimMethod` switches with `@external(Target.Erlang,…)` lookup
      + template arg order; irreducible cases → small explicit inline allow-list.
- [ ] A6 — migrate every current case; **byte-identical** output (empty snapshot diff).
- [ ] A7 — docs (`libs/std/AGENTS.md` + `codegen/AGENTS.md` + `comptime/AGENTS.md`) + a test that
      adds a new primitive method via one `.d.bp` annotation, lowering on all backends with no `.zig` edit.

## §B — generic-inference
- [ ] B1 — resolve `Self`'s primitive kind inside interface `default fn` bodies (instance_lowering).
- [ ] B2 — instantiate callee generic vars before `unifyAt` so generic inline `test { … }` works;
      fold external `*_test.bp` back to inline.
- [ ] B3 — fix `variable 'B' is unbound` codegen bug (erika LINQ pipeline).
- [ ] B4 — emit primitive interfaces' instance `default fn`s on erlang/beam (merge-order w/ parity-tail E).
- [ ] B5 — drop generic-module inline-test caveat in `libs/std/AGENTS.md`; add inference unit tests.

## §C — wasm-aggregates (after backends-parity-tail W)
- [ ] C1 — record field layout (stable 4-byte slot offsets; construction stores at offset).
- [ ] C2 — `recv.field`/`self.field` loads `base+offset`; field assign stores.
- [ ] C3 — `?.` guards base against null, reads slot; remove short-circuit.
- [ ] C4 — keep wasm single-module note (no linking).
- [ ] C5 — update `codegen/AGENTS.md`; add wat snapshots.

## §D — cross-backend-feature-parity (after §A)
- [ ] D1 — `console.log` + `new Error(…)` declared `@external`, lowered by consulting annotation.
- [ ] D2 — cross-module fn imports → remote call into owner module (erlang first, then beam).
- [ ] D3 — typed-value method dispatch (`p.parse(x)` → `'Parser_parse'(P, X)`).
- [ ] D4 — `*fn` async/`await` on erlang/beam, or scope to follow-up + record the boundary.
- [ ] D5 — update beam/erlang AGENTS "Remaining gaps"; snapshots on both backends.

## §E — lsp-definition-tail (after v0.beta.15)
- [ ] E1 — tuple-field `recv._N` → Nth element decl.
- [ ] E2 — interface associated-function dispatch → `default fn` decl in interface source.
- [ ] E3 — note paths in `language-server/AGENTS.md` + `docs.md`; regression tests.

## §F — typescript-dts-templates
- [ ] F1 — skip `@Expr<…>`/`@ExprCustom<…>` return fns when emitting `.d.ts`; never render `@expr`/`@code`.
- [ ] F2 — remove KNOWN GAP note in `codegen/AGENTS.md`; `.d.ts` snapshot asserting no `Expr<>`.

## §G — erika-dsl-extensions
- [ ] G1 — lower `${expr}` interpolations (`q.parts()` Text/Interp); tests.
- [ ] G2 — string form resolves `var` (generic comptime scope-snapshot; no erika coupling in core).
- [ ] G3 — update `libs/erika/AGENTS.md` "Recorded gaps"; `.bp` tests for both forms.

## Done gate (whole version)
- [ ] §A single-edit-site; switches gone; output byte-identical (snapshots unchanged).
- [ ] §B erika green on erlang under `zig build test-libs`; generic stdlib modules inline tests.
- [ ] §C `self.field` r/w right slot on wasm; `?.` guards; gap notes removed.
- [ ] §D erlang+beam parity snapshots; `*fn` lowered or boundary recorded.
- [ ] §E `p._0` + interface assoc resolve without regressing v0.beta.15.
- [ ] §F `.d.ts` no template fns.
- [ ] §G interpolation woven; `var` string form resolves.
- [ ] `zig build test` + `botopink-lib-test` + `zig build test-libs` green; touched AGENTS.md updated same commit.
