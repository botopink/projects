# extension-discipline — extensions only implement interfaces, and are auto-applied where declared

**Slug**: extension-discipline
**Depends on**: nothing (reworks the existing `interface`/`implement`/`extend` + activation machinery already in `feat`)
**Files**: `modules/compiler-core/src/parser/decls.zig`, `modules/compiler-core/src/comptime/infer.zig`, `modules/compiler-core/src/comptime/env.zig`, `modules/compiler-core/src/comptime/error.zig`, `modules/compiler-core/src/codegen/{typescript,commonJS,erlang,beam_asm,wat}.zig`, `modules/compiler-core/src/ast.zig`
**Touches docs**: `modules/compiler-core/src/parser/AGENTS.md`, `modules/compiler-core/src/comptime/AGENTS.md`
**Status**: done

> Closes two holes the same snippet exposes today. `extend` lets you bolt
> **arbitrary, contract-free methods** onto a type, and the activation operator
> `Name*;` is demanded even for an extension declared **in the same module**. Both
> are wrong: an extension must answer to an interface, and a method you wrote in
> this file is already yours — you should not have to "activate" it.

## Intent

Two rules, one snippet.

**Rule A — extensions only implement interfaces.** Adding methods to a type from
the outside is allowed *only* through `implement <Interface> for <Type>`, whose
methods are checked against the interface by `validateImplement`
(`infer.zig:241-311`: every abstract method covered, qualified prefixes match a
declared interface). The contract-free form `extend <Type> { … }` — registered
today with `isExtend=true` and an empty `interfaces` slice (`infer.zig:584-592`),
and **never validated** — is rejected.

**Rule B — a locally-declared implement is auto-applied in its own module.** The
activation operator `Name*` exists to opt an *imported* extension into scope
(`import { Name* } from "…"`). For an `implement` declared in the current module,
dispatch must find it with **no activation statement at all**. A bare `Name*;`
that names a local symbol is a redundant-activation error.

Net effect on the user's snippet — it stops compiling for *two* independent
reasons (no interface; redundant local `*`), and the corrected form needs neither
`extend` nor `*`.

## Target syntax

### Rejected (today's passing test `codegen/tests/js_dispatch.zig:96`)
```bp
record Pato { id: i32 }
val PatoVoa = extend Pato {          // ERROR A: extend has no interface
    fn fly(self: Self) { return self.id; }
}
PatoVoa*;                            // ERROR B: redundant local activation
fn main() {
    val donald = Pato(7);
    @print(donald.fly());
}
```

### Valid — interface-backed, auto-applied
```bp
val Voador = interface {
    fn fly(self: Self) -> i32;
}
record Pato { id: i32 }
PatoNada implement Voador for Pato {
    fn fly(self: Self) -> i32 { return self.id; }
}
fn main() {
    val donald = Pato(7);
    @print(donald.fly());           // resolves with NO activation statement
}
```

### Where `*` is still required — crossing the module boundary
```bp
// duck.bp
val Voador = interface { fn fly(self: Self) -> i32; }
pub record Pato { id: i32 }
pub PatoNada implement Voador for Pato {
    fn fly(self: Self) -> i32 { return self.id; }
}

// main.bp
import { Pato, PatoNada* } from "./duck";   // `*` opts the imported impl into scope
fn main() { @print(Pato(7).fly()); }
```

## Examples

### A — `extend` without an interface
```bp
val X = extend Pato { fn fly(self: Self) { return self.id; } }
```
→ `TypeError.extendRequiresInterface("Pato")`, with a fix hint: *"use `implement
<Interface> for Pato`; methods added to a type must satisfy an interface."*

### B — redundant local activation
```bp
PatoNada implement Voador for Pato { … }   // local
PatoNada*;                                  // ERROR
```
→ `TypeError.redundantActivation("PatoNada")`: *"extensions are auto-applied in
their declaring module; `*` is only for imports."* Dropping the line compiles.

### B — imported activation stays valid
```bp
import { PatoNada* } from "./duck";   // OK: brings a cross-module impl into scope
```

## Steps

### F0 — reject contract-free `extend` (Rule A)
- [ ] `infer.zig:584-592`: replace the `.extend` registration (which builds an
      un-interfaced `ExtEntry`) with `env.lastError = TypeError.extendRequiresInterface(ex.target)` → `error.TypeError`.
- [ ] `error.zig`: add `extendRequiresInterface(typeName)` with the `implement` fix hint.
- [ ] Keep the parser accepting `extend` (`parser/decls.zig:897-936`) **only** so the
      error carries a precise source location; do not turn it into a raw parse error.
- [ ] Once no path constructs an `isExtend=true` entry, drop `ExtEntry.isExtend`
      and `interfaces.len==0` handling — `env.extensions` now holds only
      interface-backed implements.

### F1 — auto-apply local implements; restrict `*` to imports (Rule B)
- [ ] Mark each `ExtEntry` with `local: bool`, set true when registered from the
      module-under-inference's own `program.decls`, false for impls pulled in by
      `resolveImports`. **Confirm first** where imported impls land in
      `env.extensions` (resolveImports in `comptime.zig`) — F1 hinges on telling
      local from imported apart.
- [ ] Dispatch Rule 2 (`infer.zig:4477-4504`): treat `ext.local == true` as
      activated regardless of `env.activations`; keep requiring `isActivated` for
      imported (`local == false`) entries. Ambiguity check (`ambiguousWith`) unchanged.
- [ ] Activation validation (`infer.zig:599-613`): when `u.activationOnly` (bare
      `Name*;`) names a **local** symbol, raise `TypeError.redundantActivation(nm)`
      instead of accepting it. `import { Name* } from "…"` (not `activationOnly`)
      stays valid.
- [ ] `error.zig`: add `redundantActivation(name)`.

### F2 — codegen + test migration
- [ ] Remove the `extend`-emit branches now that `extend` never type-checks:
      `typescript.zig:205`, `commonJS.zig:1396`, `erlang.zig:2634` (`emitExtend`),
      `beam_asm.zig`, `wat.zig`. Leave `implement` lowering untouched.
- [ ] Migrate the test `js_dispatch.zig:96` ("activated extend method call") to the
      interface-backed, no-`*` form above; assert `fly()` lowers to `PatoNada.fly(donald)`.
- [ ] Update/remove the `extend` parser/format tests that now exercise a rejected
      form: `parser/tests/declarations.zig` (extend shorthand/explicit),
      `format/tests/declarations.zig`, `parser/tests/errors.zig`. Add the two new
      negative infer tests.
- [ ] AGENTS.md in `parser/` and `comptime/`: document that `extend` is rejected and
      local impls auto-apply.

### F3 — library sweep (near-empty)
- [ ] No production `.bp` uses contract-free `extend` — the only `.bp` hit is a
      comment in `libs/onze/src/onze.bp:68` ("extend per type as needed"). Confirm
      with `grep -rn '\bextend\b' libs/` and reword the comment so it doesn't read
      as the now-removed construct.

## Test scenarios

```
infer       ---- `extend Type { … }` with no interface → extendRequiresInterface
infer       ---- `implement Iface for Type` covering every abstract method → ok (unchanged)
infer       ---- local implement: `donald.fly()` resolves with NO activation statement
infer       ---- bare `PatoNada*;` naming a local impl → redundantActivation
infer       ---- `import { PatoNada* } from "./duck"` still activates a cross-module impl
codegen/js  ---- migrated valid snippet lowers `donald.fly()` → `PatoNada.fly(donald)`
```

## Notes

- **Blast radius is compiler tests only.** No library implements anything via
  contract-free `extend`; the migration is the `js_dispatch` test plus the
  parser/format tests that assert the old shape.
- **Open point — keyword fate.** Two ways to honor Rule A: (a) keep the `extend`
  keyword solely to raise `extendRequiresInterface` with a good location (chosen
  above for migration ergonomics), or (b) delete `ExtendDecl` and the keyword
  outright, letting it surface as an unknown-identifier parse error. Prefer (a)
  now, then remove the keyword a version later once no source references it.
- **Crux of F1** is the local-vs-imported distinction in `env.extensions`. If
  imported impls are *not* currently inserted there (only local ones are), Rule B
  collapses to "every entry is local ⇒ always active" and the only remaining work
  is rejecting bare local `Name*;` — verify before sizing F1.
- Rule B narrows, not removes, the activation mechanism: `import { X* }` keeps its
  meaning; only the bare same-module `X*;` becomes an error.
