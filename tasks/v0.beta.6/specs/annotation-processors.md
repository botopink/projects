# annotation-processors — decorators as custom comptime functions

**Slug**: annotation-processors
**Depends on**: comptime eval + expr-templates machinery (`template_eval.zig`)
**Files**: `modules/compiler-core/src/comptime/*` (recognition + reflection +
invocation), `libs/std/src/builtins.d.bp` (`@Decl` reflection surface),
consuming libs (`libs/rakun/*` migrate their decorators onto it)
**Touches docs**: `modules/compiler-core/src/comptime/AGENTS.md`,
`libs/std/AGENTS.md`
**Status**: pending

## Hard rule (non-negotiable)

**`modules/compiler-core/src/**` must contain ZERO knowledge of any specific
lib.** Eric, 2026-06-08:

> "modules/compiler-core/src/** deve desconhecer o rakun — a funcionalidade deve
> ser implementada usando o próprio botopink."

Concretely:

- **No lib names in core.** `grep -ri "rakun" modules/compiler-core/src` must
  return nothing. Same for `service`/`getMapping`/`Response`/HTTP verbs or any
  other framework-specific identifier or semantics.
- **Functionality is written in botopink.** rakun (and every framework) is a
  pure-botopink lib. Its decorators, DI container, router and bootstrap are
  implemented in `.bp`, on top of generic language primitives — never as Zig
  passes in the compiler.
- **This deletes the current rakun foundation from core.** The existing
  `registerRakunLib`, `rakunExports`/`rakunTypeDecls`/`rakunImports`,
  `expandRakunImports`, `rakun_pkg_modules`, `isRakunPkgPath`, `markRakunImports`,
  the `rakun.d.bp`/`http.bp` `@embedFile`s (prelude.zig + both build.zig), and the
  interim rakun validation passes (`validateRakunDi`/`validateRakunDecls`/
  `validateRakunAnnotations`) all go away. They are replaced by:
  1. a **generic package loader** — `from "<lib>"` resolves any external lib by
     name through one lib-agnostic path (no per-lib embed, no per-lib registry);
  2. this **generic annotation-processor mechanism**.

## Why

A framework lib (rakun, jhonstart, …) needs to give its `#[decorator]` markers
*meaning* — validate where they sit, type-check their arguments, and contribute
wiring (DI graph, router table). Per the hard rule above, that meaning lives in
the lib, in botopink — never in the core. jhonstart already proves the pattern:
it is built on generic primitives (`@Context`, expr-templates) with no bespoke
core passes.

The generic primitive this spec adds: **a decorator is a custom comptime
function, written in the lib, that the core invokes over the declaration the
annotation is attached to.** Any lib can ship decorators this way; the core only
provides the protocol (recognize → reflect → invoke → apply).

## Model

A decorator is an ordinary comptime function whose **first parameter is the
reflected declaration** it is applied to:

```bp
// in a lib (e.g. libs/rakun) — NOT in the compiler core
pub fn service(comptime decl: @Decl) {
    if (decl.kind != .record) decl.fail("#[service] must annotate a record");
    // (later) contribute a DI registration
}

pub fn getMapping(comptime decl: @Decl, path: string) {
    if (decl.kind != .method) decl.fail("#[getMapping] must annotate a method");
    // (later) contribute a router entry { GET, path, decl.name }
}
```

Applying the decorator is sugar for a comptime call:

```bp
#[service] record UserService { … }          //  ≡  service(reflect(UserService))
#[getMapping("/")] fn index(…) -> Response    //  ≡  getMapping(reflect(index), "/")
```

The annotation arguments (`"/"`) become the trailing call arguments, type-checked
against the function signature — generically, no lib knowledge.

### `@Decl` — the reflection handle (core builtin)

A comptime-only type (like `@Expr`) describing the annotated declaration:

| member | meaning |
| --- | --- |
| `kind` | `DeclKind` enum: `record`/`struct`/`enum`/`fn`/`method`/`field` |
| `name` | declaration name |
| `fields` | `[@Field]` — each `name`, `typeName`, `annotations` |
| `methods` | `[@Method]` — each `name`, `params`, `returnType`, `annotations` |
| `returnType` | for a method/fn: the return type name (or empty) |
| `annotations` | `[@Annotation]` on this declaration |
| `fail(msg)` / `failAt(span, msg)` | emit a scoped diagnostic (reuses the template diagnostic surface) |

Reflection is **read-only data** serialized to the comptime eval runtime exactly
like a template's capture handle (`template.contextJsonAlloc`).

### Invocation

The core, during inference, for every declaration carrying an annotation whose
name resolves to a decorator function:

1. type-checks the trailing arguments against the function signature (generic);
2. serializes the declaration to a `@Decl` JSON handle;
3. runs the function body in the comptime eval runtime (reusing
   `template_eval`), collecting one outcome: `ok`, `fail{message, span}`, or
   (phase 3) `code`/decls to splice as generated wiring.

No lib names, no bespoke passes: the *function body* (in the lib) holds every
rule.

## Phases

### P0 — generic package loader (de-rakun the core)
- [ ] `from "<lib>"` resolves ANY external lib by name through one lib-agnostic
      mechanism (e.g. discover `libs/<name>/` via the project/package manifest),
      with no per-lib `@embedFile`, no `rakun_pkg_modules`, no `registerRakunLib`.
- [ ] Delete every `rakun`/`service`/`Response`/HTTP-verb reference from
      `modules/compiler-core/src/**` (incl. the interim `validateRakun*` passes
      and the `rakunExports`/`rakunTypeDecls`/`rakunImports` env fields).
- [ ] Gate: `grep -ri "rakun" modules/compiler-core/src` returns nothing.

### P1 — recognition + generic argument validation
- [ ] A decorator is recognized by signature: a `pub fn`/`declare fn` whose first
      param is `comptime _: @Decl`. Recorded per importing module (generic
      registry — replaces the rakun-specific `rakunExports`/`rakunImports`).
- [ ] Applying `#[d(args)]` type-checks `args` against the decorator signature
      (arity + types), at any site (record/struct/enum/method/field/fn).
- [ ] `@Decl` builtin reflection type declared in `builtins.d.bp` + `DeclKind`.

### P2 — comptime invocation + diagnostics
- [ ] Serialize the annotated declaration to the `@Decl` handle.
- [ ] Run the decorator body in `template_eval`; surface `fail`/`failAt` as a
      scoped diagnostic at the annotated declaration.
- [ ] rakun migrates `#[service]`/`#[getMapping]`/… placement + arg rules into
      lib-side decorator bodies (deletes the core rakun passes).

### P3 — wiring contribution (DI graph + router)
- [ ] A decorator body may return generated declarations / `@Expr` (reusing
      expr-templates expansion) to contribute singletons, the DI graph, and the
      router table — all lib code.
- [ ] rakun's DI cycle check + router build + `Rakun.run` bootstrap become
      lib-side comptime, driven by the decorators (closes rakun F2/F4/F5).

## Notes

- Reuses the comptime eval runtime + diagnostic surface already built for
  `@Expr` templates; adds no new runtime.
- Language gaps surfaced while porting rakun (as jhonstart did) are recorded
  against this spec, not worked around in core.
- The interim rakun-specific core passes (component scan, DI graph, route
  validation) **and the entire rakun foundation** (registry/embeds/loader) are
  removed by P0 — they are the anti-pattern this spec replaces. The core ends up
  with no lib-specific code at all; rakun lives entirely in `libs/rakun/*.bp`.
