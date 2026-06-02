# Static extension dispatch

**Branch**: `feat/extension-dispatch`
**Phase**: F6
**Depends on**: `feat/import-rework` (activation `*`) + `feat/implement-extend-decls` (Impl/ExtendDecl) — ✅ ambas já em `feat`

> **Situação (2026-06-02): 🟡 implementada (F6) nesta branch, ainda NÃO mesclada em `feat`.**
> Commit `fb43ef2`. Inferência completa + codegen CommonJS; reescrita de call-site
> Erlang/BEAM/WAT/TS é follow-up. As dependências já estão em `feat` (`3746eae`);
> falta integrar esta branch (atenção: a suíte de snapshots não está ligada ao
> `zig build test` aqui — root = `root.zig`).
**Status**: implemented ✅ (não integrada em `feat`)

## Model (Rust/C# — Model Y)

`obj.m()` only resolves if the impl/extension is **activated** (`X*` in import or `X*;`)
in the file. Otherwise: error with hint, or qualified call `Sym.m(obj)`.

```bp
import {Pato, PatoNada*, PatoExtra*} from "ducks";
val donald = new Pato();
donald.swim();    // ✓ PatoNada* activated
donald.quack();   // ✓ PatoExtra* activated

import {Pato, PatoNada};        // no *
donald.swim();                  // ✗ error: method not active; hint: use `PatoNada*`
PatoNada.swim(donald);          // ✓ qualified call needs no activation
```

### Resolution of `obj.m(args)`
1. **Inherent** — `m` on the type (or inline `implement`). Always available.
2. **Activated** — `Name implement T for TypeOf(obj)` or `Name extend TypeOf(obj)` with `m`, and `Name` activated.
3. Otherwise → error + hint. Ambiguity (two activated) → error, require `Name.m(obj)`.

## Status — implemented ✅

**Syntax**: `import { A, X*, B as C } [from "m"];`, bare `Name*;` activation,
and `val Name = extend Target { … }` are lexed/parsed/formatted. New lexer token
`extend`; new `DeclKind.import/extend/activate`; `ImportPath.{activate, alias}`.

**Inference** (`comptime/infer.zig` + `comptime/env.zig`): all 8 steps below.
Activation set, extension table (`env.extensions`), and inherent-method table
are built in a pre-pass (`registerExtensions`). `obj.m()` resolves
inherent → activated → error, with qualified `Sym.m(obj)` bypassing activation.
External-dispatch rewrites are recorded loc-keyed in `env.dispatchRewrites` and
threaded through `comptime.compile` → `OkData.dispatch_rewrites` → codegen.

**Codegen**: CommonJS fully lowers external dispatch — `implement`/`extend`
blocks emit as namespace objects (`const Sym = { m(self){…} }`, no monkey-patch)
and activated `obj.m(args)` lowers to `Sym.m(obj, args)`. Erlang/BEAM/WAT/TS
handle the new decls structurally (compile-clean); their call-site external
rewrite is follow-up.

> Note: the snapshot suite (`src/test_root.zig`) is not wired into
> `zig build test` in this branch (root module is `root.zig`); the inference
> snapshots under `snapshots/comptime/**` were generated and verified by running
> the suite directly.

### Inference (`comptime/infer.zig`)  — done
1. ✅ Per-file set of **activations** (symbols with `*` in import + `X*;`)
2. ✅ Tables: `env.extensions` (name → {target, isExtend, interfaces, methods}) + inherent-method table
3. ✅ `obj.m(args)`: apply rules 1–3, considering only activated ones
4. ✅ Error: method not active → hint with `Sym*`
5. ✅ Error: two ambiguous activations → require `Sym.m(obj)`
6. ✅ Error: `Sym*` where `Sym` is not an impl/extend (bare `Name*;` form)
7. ✅ Error: method in impl not declared in interface; required method missing
8. ✅ Qualified call `Sym.m(obj)` resolves without activation

### Codegen — external dispatch (no monkey-patch)
9. ✅ CommonJS: activated `obj.m()` → `Sym.m(obj)`; impl/extend → namespace object
10. ⏳ Erlang: `sym:m(Obj)` — decls handled; call rewrite is follow-up
11. ⏳ BEAM ASM: tagged tuple / module call — decls handled; call rewrite follow-up
12. ⏳ WAT: function table entry per impl/extend — decls handled; follow-up
13. ⏳ TypeScript: external dispatch or `declare module` augmentation — follow-up

## Test scenarios

```
infer   ---- donald.swim() with PatoNada* (pass)
infer   ---- donald.swim() imported but no * (error + hint)
infer   ---- donald.quack() with PatoExtra* (pass)
infer   ---- two activated impls same method (error + qualify)
infer   ---- PatoNada.swim(donald) qualified, no * needed (pass)
infer   ---- inherent method always available (pass)
infer   ---- impl extra/missing method vs interface (error)
codegen ---- donald.swim() activated → PatoNada.swim(donald)   (CommonJS external)
codegen ---- extend method → external dispatch
```

## Open points
- **P2 orphan rule**: allow `implement T for X` where `T` and `X` come from external packages? Rust forbids it.
- **P3 re-export**: does `pub import {X*} from "m";` re-export name + activation?
- **P4 scope**: does `X*` in import apply file-wide; does `X*;` inside a fn apply only to the fn? Or always file-level?