# Front 134 — builtins-declared: every builtin declared in `builtins.d.bp`, and held to it

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [144-botopink-lang](../README.md): s2 box 4 → B-06 · s2 boxes 1, 2, 3, 6 → B-16 · s6 → B-17 · s2 box 5 → B-18. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high · **State:** partial: steps 1, 3, 4 and 5 done; step 2 partial (calls, `@Result`'s
methods, the mirrored types and `@is` held; std's `Type` declared with `pick` / `omit`, `Decl.fields`'
`Type.Field<unknown>` open; `?T` methods and the `result` namespace removed under 330); step 6 (354, 357)
partial: boxes 1, 2, 3, 5 (357), 6 (the codemod), the measurement and 4b (388: a component is a lambda over
a `RenderScope`, with 389's edges; erlang, beam, commonJS — wasm refuses, 354-wasm) done, 4b as a patch
(`front/render-scope-388`) that lands with `05-jhonstart/26` step 14 (414)
**Depends on:** step 6: backend fronts 02–05 and 18 for each lowering of 388's lambda · answered: `134-f` → 354, 134-e → 329, 330, 134-d → 322, 134-a → 267, 134-b → 268, 134-c → 269
**Owns:** `libs/std/src/builtins.d.bp`, `libs/std/src/builtins_fns.d.bp` (with 130 for the `Decl`
surface) · compiler's builtin table and the check tying it to the declarations
(`modules/compiler-core/src/comptime/builtins.zig`, `Env.builtinDecls`, `comptime.zig`
`registerBuiltinDecls`, `infer.zig` `checkBuiltinArguments`) · `docs.md` § Builtins ·
`tests/language/reject/` cells for declaration-refused builtin calls · `AGENTS.md` of each touched dir
**Does not touch:** what a builtin does on any backend (its owner's) · decorator outputs (130)

## Goal

Decision 252: every builtin a program reaches (`@name(…)` call, `@name` type or value, builtin type
with static members) declared in `builtins.d.bp` (or `builtins_fns.d.bp`); a unit test holds the
implementation to the declarations; `docs.md` documents each from its declaration.

## Decisions

`134-g` → 388 (a component is a lambda over a `RenderScope`, run by the render library); `134-i` → 387, replaced by 388.

Answered: `134-f` → 354 (contexts), 329, 330 (`134-e`: a namespace type, `?T` methodless, `result` deleted,
`Type.Field<T>` associated — step 2), 322 (`@is` refused, step 2), 267 (step 4), 268 (step 5), 269 (step 6).

**Gate:** standard (fronts.md § Gate) + `zig build test-language`, `test-docs`, `test-libs`, `tsc-check` green
