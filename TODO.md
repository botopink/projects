# TODO — annotation-processors (the lib-agnostic core)

> Task branch `task/annotation-processors` · spec
> [`tasks/v0.beta.7/specs/annotation-processors.md`](../../tasks/v0.beta.7/specs/annotation-processors.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test.
>
> **Indivisible spec:** the generic mechanism AND the removal of every non-std lib
> footprint live here — one branch, sequential phases. `std` is the allowed
> coupled exception; the gate binds rakun/jhonstart/future frameworks.

## P0 — generic package loader (de-lib the core; std excepted)
- [x] `from "<lib>"` resolves any external **non-std** lib by name through one
      lib-agnostic mechanism; no per-lib `@embedFile`, no `rakun_pkg_modules`, no
      `registerRakunLib`. `std` keeps its embedded-prelude path. Core: non-std lib
      `.bp` sources resolve `from "<lib>"` through the shared import registry. CLI
      driver: `compiler-cli/src/cli/libs.zig` discovers `libs/<name>/` on disk via
      `botopink.json` deps and feeds the modules in. PROVEN end-to-end by the
      `erika` port (`import {erika} from "erika"` resolves; `libs/erika` test suite
      green) with zero `modules/compiler-core/src/**` edit.
- [x] Delete every `rakun` reference from `modules/compiler-core/src/**` (incl.
      the `rakunExports`/`rakunTypeDecls` env fields, `registerRakunLib`,
      `markRakunImports`, `buildDelegateType`, `registerRakunTypeDecl`,
      `expandRakunImports`, `isRakunPkgPath`, `rakun_pkg_modules`, the
      `prelude.zig` embeds, and both `build.zig` `@embedFile`s). `validateRakun*`
      never existed (planned-only). Codegen example comments de-named.
- [x] Fold `comptime/tests/jhonstart.zig` into the generic suites — N/A on this
      branch: `grep -riE jhonstart modules/compiler-core/src` already returns
      nothing (the file/comments don't exist here; the earlier scan was wrong).
      So the gate's `jhonstart` half is already satisfied.
- [x] Gate as a test: `grep -riE "rakun|jhonstart" modules/compiler-core/src`
      returns nothing (std exempt). Wired as a `zig build test` step in `build.zig`
      (`lib_agnostic_gate`: `! grep -riIE 'rakun|jhonstart' modules/compiler-core/src`,
      `has_side_effects` so it always re-scans). `libs/rakun (.bp)` tests stay
      green — they compile the lib's own local sources, not an external
      `from "rakun"`.

## P1 — recognition + generic argument validation
- [x] Recognize a decorator by signature: a `pub fn`/`declare fn` whose first param
      is `comptime _: @Decl`; record per importing module (generic registry).
      (`env.decorators` registry, populated in `registerFnSignatures` for both the
      `.fn` and `.delegate` forms; parser now accepts bare `@Decl`.)
- [x] `#[d(args)]` type-checks `args` against the decorator signature (arity +
      types) at any site (record/struct/enum/method/fn). (`validateDecorators`
      pass; arity honors trailing defaults; per-arg lexical kind check.)
      NOTE: field-site + record/struct method-site annotations are a *parser* gap
      (annotations only parse on interface methods today) — addressed when rakun
      migration (P2) needs `#[getMapping]` on controller methods.
- [x] Declare `@Decl` builtin reflection type + `DeclKind` in `builtins.d.bp`.
      (`DeclKind`/`Annotation`/`Param`/`Field`/`Method` + `interface Decl`;
      `TypeRef.isDeclType` recognizes bare `@Decl`.)

## P2 — comptime invocation + diagnostics
- [x] Serialize the annotated declaration to the `@Decl` handle. (`buildHandleJson`
      in infer.zig — kind/name/fields/methods/returnType/annotations, for
      fn/record/struct/enum + their methods.)
- [x] Run the decorator body in the node runtime; surface `fail`/`failAt` as a
      scoped diagnostic. (`decorator_eval.zig` mirrors `template_eval`; `__decl`
      handle + `fail`/`failAt`; `invokeDecorators` runs body-carrying decorators
      after `validateDecorators`, only when `env.templateEval` is set. Diagnostic
      locs are coarse for now — message carries the detail; precise spans = TODO.)
      `@Decl` body type-checks via the `decl_reflection_src` cluster registered in
      `registerStdlib` (scalar `kind`/`name`/`returnType` + `fail`/`failAt`).
- [~] (with `rakun`) decorator placement + arg rules move to lib-side bodies.
      UNBLOCKED: `#[getMapping]` on methods AND `#[inject]`/`#[value]` on fields now
      parse on record/struct bodies and reach `validateDecorators`/`invokeDecorators`.
      REMAINING: write the rakun decorator bodies in `.bp` (lib-side) — pending the
      P3 wiring primitive so they can contribute DI/router entries.

## P3 — wiring contribution (DI graph + router)
- [x] Field-site decorators: parse + reflect annotations on record/struct fields.
      (`RecordField`/`StructField` carry `annotations`; `parseRecordBody`/
      `parseStructBody` attach them; the inference walk reflects fields as
      `DeclKind.Field`. Parser AST snapshots regenerated.)
- [x] `@Decl` exposes the aggregate reflection a wiring decorator iterates:
      `Decl` is now a `struct` with `fields`/`methods`/`annotations` (+ `Field`/
      `Method`/`Param`/`Annotation`/`Span`), so `decl.fields`/`decl.methods` resolve.
- [x] `@compilerError(message)` builtin — the generic compile-time error a comptime
      body raises (decorator or template); lowered to `__compilerError` and thrown
      as the `fail` protocol. Preferred over `decl.fail`/`decl.failAt`.
- [x] A decorator body contributes generated decls via `@emit(source)`: the core
      collects them (`env.contributions`) and `analyzeModule`/`analyzeSource`
      splices them onto the module + re-analyzes it once (`skipDecoratorInvoke`),
      so the generated decls are inferred + emitted like hand-written code. A lib
      builds singletons / DI graph / router as ordinary `.bp` — no wiring logic in
      the core. Test: a decorator emitting a top-level `val` reaches the program.
- [x] Drop comptime-only decorator/`@Decl` fns from codegen (like template fns):
      `transform.zig` Phase-3 decl filter drops a `fn` whose first param is
      `comptime _: @Decl`, so a body's `@emit`/`@compilerError`/`decl.fail`
      (→ `__emit`/`__compilerError`/`__decl`) never reaches real JS. The decls it
      contributed via `@emit` stay (spliced into the module). Test asserts the
      decorator fn is absent from the transformed program.
- [ ] LIB-SIDE (separate `task/rakun-port` worktree — NOT this core branch; the
      gate forbids `rakun` in core): write rakun's decorator bodies in `.bp` —
      `#[service]`/`#[getMapping]` placement + arg rules via `@Decl`/`@compilerError`,
      DI graph + router + `Rakun.run` via `@emit`. Core fully UNBLOCKS this.

## Done gate
- [x] `zig build && zig build test` green; the `grep` gate test passes (the
      `lib_agnostic_gate` build step; every commit through pre-commit).
- [x] `comptime/AGENTS.md` + `codegen/AGENTS.md` + `libs/std/AGENTS.md` updated
      (decorator recognition/invocation/wiring + `@Decl`/`@compilerError`/`@emit`
      + the codegen drop).
