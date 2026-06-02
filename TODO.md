# Stdlib — `@Result` / `@Option`

**Branch**: `task/stdlib-result`
**Depends on**: nothing (independent)
**Status**: done (não integrada em `feat`)
**File**: `builtins.d.bp`

> **Situação (2026-06-02): 🟡 implementada nesta branch (`5f279b5`), ainda NÃO mesclada em `feat`.**
> CommonJS e Erlang emitem a forma inline correta; **BEAM e WASM emitem stub** (sem runtime
> de `Result`/`Option` ainda). `feat` == `origin/feat` == `3746eae`; falta integrar (a antiga
> worktree de integração `_integrate-stdlib-result` foi descartada — a feature segue preservada aqui).

## Steps

- [x] `@Result.map(fn(D) -> D2)` — transform the Ok value
- [x] `@Result.flatMap(fn(D) -> @Result<D2, E>)` — chain fallible operations
- [x] `@Result.unwrapOr(default: D)` — extract Ok or use the default
- [x] `@Result.isOk()` / `@Result.isError()` — boolean predicates
- [x] `@Option.map` / `@Option.flatMap` / `@Option.unwrapOr` — mirror the Result API

## Implementation notes

The method calls themselves did not previously exist in the language, so this
landed a small method-call subsystem alongside the stdlib API:

- **Parser**: `CallExpr.receiver` is now an expression (`?*Expr`), enabling
  method chains (`a().map(f).unwrapOr(0)`) and zero-arg method calls (`r.isOk()`).
- **Inference** (`comptime/infer.zig`): `@Result<R,E>` / `@Option<T>` (the latter
  normalised from `?T`) method calls are type-checked and recorded in
  `Env.method_lowerings` (keyed by source loc). Qualified constructor calls
  (`Color.Rgb(..)`) keep resolving as constructors.
- **Transform** (`comptime/transform.zig`): rewrites each recorded call into a
  `__bp_<domain>_<op>(receiver, args…)` builtin call.
- **Codegen**: `commonJS` and `erlang` emit the correct inline form
  (tag match for Result, presence check for Option). `beam` and `wasm` emit a
  documented stub (no Result runtime representation / higher-order inlining yet).
- `builtins.d.bp` documents the full method API.

## Examples

```bp
fn parseAge(s: string) -> @Result<i32, string> { todo; }

fn main() {
    val r = parseAge("42")
        .map({ n -> n + 1 })                      // @Result<i32, string>
        .flatMap({ n -> validate(n) })            // @Result<i32, string>
        .unwrapOr(0);                             // i32

    val ok = parseAge("42").isOk();               // bool
}

fn firstName(p: Person) -> @Option<string> { todo; }
fn greet(p: Person) -> string {
    return firstName(p)
        .map({ n -> "Hello " + n })
        .unwrapOr("Hello stranger");
}
```

**Expected output (CommonJS):**
```javascript
// .map: applies only on Ok, propagates Error
// _r.tag === "Ok" ? Ok(f(_r.data)) : _r
```

## Test scenarios

```
stdlib ---- Result.map transforms Ok, propagates Error intact
stdlib ---- Result.map on Error does not call the function
stdlib ---- Result.flatMap chains, flattens @Result<@Result<..>>
stdlib ---- Result.flatMap on Error short-circuits
stdlib ---- Result.unwrapOr returns data on Ok, default on Error
stdlib ---- Result.isOk / isError correct predicates
stdlib ---- Option.map / flatMap / unwrapOr mirror Result
stdlib ---- Option.map on None does not call the function
stdlib ---- chain map().flatMap().unwrapOr() types correctly
```