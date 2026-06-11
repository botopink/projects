# generic-loader-binding — `from "<lib>"` binds bare values + template fns, not just the namespace

**Slug**: generic-loader-binding
**Depends on**: nothing
**Files**: `modules/compiler-core/src/comptime.zig` (`resolveImports`), `modules/compiler-core/src/comptime/infer.zig` (import binding), `modules/compiler-core/src/comptime/template_eval.zig` (template-fn rehydration)
**Touches docs**: `modules/compiler-core/src/comptime/AGENTS.md`
**Status**: pending

> Generic, std-exempt core work — **no** lib name enters `compiler-core`. This is
> the keystone of v0.beta.8: it unblocks the bare-import call form for **every**
> non-std lib (`erika "…"`, jhonstart's `html "…"`, any future template-fn lib),
> so it lands first and the lib specs build on it.

## Intent

The generic `from "<lib>"` loader (shipped by v0.beta.7 `annotation-processors`)
resolves a library off disk and binds its **namespace** — `Lib.member` works. But
a **bare** imported binding does not reach value scope:

```bp
import {html} from "jhonstart";   // resolves the lib, binds the `jhonstart` namespace
val page = html """…""";          // ❌ bare `html` is UNBOUND (only `jhonstart.html` is)
```

The same gap blocks `erika "…"` after `import {erika} from "erika"` (recorded in
v0.beta.7 erika as its one open item) and jhonstart's `html "…"` (v0.beta.7
jhonstart F2, deferred).

**Scoped by the erika-linq example (2026-06-10).** Bare imports of ordinary
**values/fns** from a disk lib *already work* — `import {of} from "erika"; of(xs)…`
type-checks **and** runs (proven by `examples/erika-linq`, 4 green tests). The
binding that is still missing is specifically the **bare template fn**
(`comptime _: @Expr<…>`): `import {erika}…; erika "…"` / `import {html}…; html "…"`
leave the bare symbol unbound. A second, related gap surfaced: the **namespace**
member form `Lib.member(...)` for a disk lib does **not codegen** (`erika.of(...)`
runs as `erika is not defined` — the namespace object is never emitted), so a
consumer must use the bare form today. Both are generic (no lib name in core); std
already binds both.

This spec closes them generically: an `import {name, …} from "<lib>"` makes each
named symbol usable in the importing module — **(1)** rehydrate a bare imported
**template fn** via `registerImportedTemplateFn` so `name "…"` / `name """…"""`
expands (the disk-loader mirror of the same-project path + `registerImportedDecorator`),
and **(2)** emit the disk lib's **namespace object** so `Lib.member(...)` resolves
at runtime too — bringing disk-loaded libs to the parity `std` already has.

## Examples

### already works — bare value/fn binding (the baseline)
```bp
import {of} from "erika";
val s = of([1, 2, 3]).where({ n -> n > 1 }).toArray().join(",");   // "2,3" — runs today
```

### gap 1 — bare template-fn binding (the call form that is unbound)
```bp
import {html} from "jhonstart";
val page = html """<p>hello</p>""";   // ❌ bare `html` unbound → rehydrate via registerImportedTemplateFn
```
Mirrors the `template_registry` / `registerImportedTemplateFn` path already used
for same-project template-fn imports; this extends it across the disk loader.

### gap 2 — namespace member codegen for a disk lib
```bp
import {erika} from "erika";
val xs = erika.of([1, 2]).toArray();   // ❌ `erika is not defined` at runtime — emit the namespace object
```

## Steps

### F0 — pin the two gaps
- [ ] Confirm the baseline (bare value/fn already binds + runs — `examples/erika-linq`)
      and pin the two failing paths: a bare template-fn import, and a `Lib.member(...)`
      namespace call on a disk lib (`resolveImports` in `comptime.zig` + the import
      case in `infer.zig` + the namespace emission in codegen). Add a failing
      `test {}`/example for each.

### F1 — bind bare template fns
- [ ] A bare imported template fn (`comptime _: @Expr<…>`) rehydrates via the
      existing `registerImportedTemplateFn` path so `name "…"` / `name """…"""`
      expands in the importing module — the disk-loader mirror of the
      same-project template-fn import (and of `registerImportedDecorator`).

### F2 — emit the disk lib's namespace object
- [ ] `Lib.member(...)` for a disk-loaded lib resolves at runtime: the codegen
      emits the lib's namespace object in the consumer output (today only the bare
      symbols are emitted, so `erika.of` is `undefined`). Parity with the bare form.

### F3 — close the recorded consumers
- [ ] `erika "…"` after `import {erika} from "erika"` binds + expands (re-enable the
      erika SQL scenario — F1 of [`erika`](erika.md)).
- [ ] The path is ready for jhonstart's `html "…"` (consumed by [`jhonstart-html`](jhonstart-html.md)).

## Test scenarios

```
infer    ---- bare imported value/fn from a disk lib is callable unqualified (baseline — passes today)
infer    ---- bare imported template fn expands: name """…""" works post-import
run      ---- erika "…" after import {erika} from "erika" runs (recorded gap closed)
run      ---- Lib.member(...) on a disk lib runs (namespace object emitted, no "is not defined")
gate     ---- grep -riE "rakun|jhonstart|erika" modules/compiler-core/src returns nothing
```

## Notes

- **Generic only.** No lib name in core; the fix is in the import resolver /
  template-fn rehydration, std-exempt. Memory: [[project_generic_loader_namespace_only]],
  [[feedback_no_lib_specific_in_core]].
- Unblocks `jhonstart-html` (bare `html`) and re-enables the erika call form;
  draw the single DAG edge `generic-loader-binding → jhonstart-html`.
- Keep parity with the three existing import paths: value imports, the
  `template_registry`, and the `decorator_registry` — this is the same shape for
  bare symbols across the disk loader.
