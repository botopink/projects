# jhonstart — de-couple the UI framework into a pure client on the generic mechanism

**Slug**: jhonstart
**Depends on**: [`annotation-processors`](annotation-processors.md) — the generic `from "<lib>"` loader + (P0) the removal of the jhonstart coupling from `compiler-core`; plus the G1–G4 gaps already landed in `feat` (v0.beta.6 `jhonstart-language-gaps`)
**Files**: `libs/jhonstart/src/*.bp` (ALL framework behaviour — promote the declarative `.d.bp` surface to real botopink), `libs/jhonstart/botopink.json`
**Touches docs**: `libs/jhonstart/AGENTS.md`, `libs/jhonstart/docs.md`, `libs/jhonstart/src/AGENTS.md`
**Status**: pending

> **HARD RULE (2026-06-09).** `modules/compiler-core/src/**` must contain **zero**
> knowledge of jhonstart — no jhonstart-named test, no jhonstart comments in
> `infer.zig`, no embed. `annotation-processors` **P0 removes** that coupling
> (folds `comptime/tests/jhonstart.zig` into the generic suites, de-names the
> `Children`-coercion comments, ships the `grep -riE "rakun|jhonstart"` gate). This
> spec is the **lib-side counterpart**: jhonstart must stand up as a **pure
> botopink client** of the generic primitives — resolved through `from "jhonstart"`,
> never embedded — after the core forgets it exists. Every behaviour below is
> implemented in `libs/jhonstart/*.bp`, not the compiler.

## Intent

jhonstart (the React/Next-style UI framework, v0.beta.5) is already "real
botopink on the language's own primitives — no new compiler features" for its
core (`element.bp`), but it carries two debts this set clears:

1. **A coupling debt** — a `jhonstart.zig` probe test and jhonstart-named comments
   sit in `compiler-core`. `annotation-processors` P0 deletes them; this spec
   guarantees the framework still type-checks and renders as a pure client once
   they are gone (the framework's own `.bp` tests become the only coverage).
2. **A declarative debt** — `hooks.d.bp`/`html.d.bp`/`router.d.bp`/`server.d.bp`
   were `.d.bp` markers because language gaps G1–G4 blocked their real bodies.
   **G1–G4 landed in `feat`** (v0.beta.6), so this spec **promotes that surface to
   real `.bp`** on the now-available primitives: fn-typed record fields (G1),
   anonymous record types (G2), `fn() -> T[]` (G3), `Element[]`→`Children`
   coercion (G4).

jhonstart uses the **loader** half of `annotation-processors` (resolve
`from "jhonstart"`) and the generic language features; its hooks are the
`@Context<Element, _>` capability gated by `use`, **not** `#[decorator]`s. (A
`#[component]`/`#[client]` decorator layer on the `@Decl` half is a clean future
extension — recorded, not built here.) Per the repo rule (memory:
[[feedback_compiler_unaware_of_jhonstart]]), the compiler must stay unaware of it.

## Target syntax

```bp
import {div, text, useState, Element} from "jhonstart";   // generic loader, no embed

// hook shape now expressible (G1: fn-typed field; G2: anon record type)
fn useCounter(use cx, start: i32) -> { value: i32, set: fn(next: i32) } {
    return useState(cx, start);
}

// component: a plain fn returning Element; children as Element[] (G3 + G4)
fn Counter(use cx) -> Element {
    val c = useCounter(cx, 0);
    return div([
        text("count: " + c.value.toString()),
        button("inc", { -> c.set(c.value + 1) }),
    ]);
}

fn main() {
    print(renderToString(Counter()));        // synchronous SSR, pure .bp
}
```

## Examples

### the coupling removed (core forgets jhonstart)
```bp
// before: modules/compiler-core/src/comptime/tests/jhonstart.zig  (a jhonstart probe in core)
//         + "// jhonstart's div { … }" comments in infer.zig
// after : framework behaviour tested ONLY in libs/jhonstart/src/*.bp test {} blocks;
//         the Children coercion described generically in core; gate is green:
//             grep -riE "rakun|jhonstart" modules/compiler-core/src   → (nothing)
```

### the declarative surface goes real (gaps landed)
```bp
// hooks.d.bp (declarative, blocked by G1) ──► hooks.bp (real body)
record State<T> { value: T, set: fn(next: T) }      // G1 fn-typed field — now parses + infers
fn useState<T>(use cx, init: T) -> State<T> { … }    // real botopink, in the lib
```

## Steps

### F0 — stand up as a pure client (post-decoupling)
- [ ] After `annotation-processors` P0 lands, `import … from "jhonstart"` resolves
      through the **generic** loader; `element.bp` + the promoted modules type-check
      and `renderToString` runs with **no** jhonstart reference in `compiler-core`.
- [ ] The jhonstart coverage that lived in `comptime/tests/jhonstart.zig` is
      reproduced as `test {}` blocks **inside `libs/jhonstart/src/*.bp`** (the
      generic language behaviour it probed stays tested generically in core by P0;
      the framework behaviour is tested in the lib).
- [ ] `botopink.json` is the only wiring; nothing is embedded into the prelude
      (re-confirm the v0.beta.5 "not embedded" rule against the new loader).

### F1 — hooks: promote `hooks.d.bp` → real `.bp` (G1 + G2)
- [ ] `record State<T> { value: T, set: fn(next: T) }` and the hook family
      (`useState`/`useEffect`/`useMemo`/`useRef`/`useReducer`) get **real bodies**
      over `@Context<Element, _>`, returning the `{value, set}` shape (G1 fn-typed
      field; G2 anon record type where a transient shape is returned).

### F2 — html DSL: implement the `html` template body (expr-templates)
- [ ] `html.d.bp`'s `html(comptime q: @Expr<Element>) -> @Expr<Element>` gets a
      real body on the **already-shipped** expr-templates machinery (like erika's
      `erika "…"` and the `sql` example) — parse the JSX-like markup, build the
      `div`/`text`/builder pipeline, expand via `q.build(…)`. No new compiler
      surface.

### F3 — children ergonomics + builder API (G3 + G4)
- [ ] Builders accept `Element[]` (G3 `fn() -> T[]` return forms) and the
      `Element[]`/`string` → `Children` coercion (G4) so `div([a, b])` / nested
      lists type-check. Keep the array-arg form (`div([a, b])`); the trailing-lambda
      `div { [a, b] }` stays a recorded ergonomic follow-up.

### F4 — router + server context as real `.bp` where expressible
- [ ] `router.d.bp` (`Router`/`useRouter`/`Link`) and `server.d.bp` (`Http`
      ContextBase: `request()` + loaders) promote to real `.bp` for everything the
      language now expresses; the genuinely host-bound bits (client `mount`, the
      async SSR loaders gated on `use-await-prefix`/`async-generators` in
      `tasks/v0.beta.1/`) stay `.d.bp` and are **explicitly** recorded as still-gated.

### F5 — docs
- [ ] Update `libs/jhonstart/AGENTS.md`, `src/AGENTS.md`, `docs.md` to reflect the
      `.d.bp`→`.bp` promotions, the loader import path, and the cleared/remaining
      gaps — in the **same commit** as the code (repo rule).

## Test scenarios

```
loader  ---- import … from "jhonstart" resolves via the generic loader (no embed)
gate    ---- grep -riE "jhonstart" modules/compiler-core/src returns nothing (P0 gate)
hooks   ---- {value, set} hook shape type-checks + works as real .bp (G1/G2)
html    ---- html "<div>{x}</div>" expands to the div/text pipeline (expr-templates)
render  ---- renderToString(Counter()) produces the expected SSR string (synchronous)
children---- div([a, b]) coerces Element[] into Children (G4); nested lists type-check
gated   ---- client mount + async loaders remain .d.bp, recorded as still-gated
```

## Notes

- **Pure client, zero core surface.** Every behaviour is `libs/jhonstart/*.bp`;
  the only compiler dependencies are the **generic** loader + the G1–G4 gaps
  already in `feat` + the already-shipped expr-templates/`@Context`. jhonstart adds
  **no** core code (memory: [[feedback_no_lib_specific_in_core]] /
  [[feedback_compiler_unaware_of_jhonstart]]).
- **Prefer real `.bp`** (memory: [[feedback_prefer_bp_over_dbp]]): promote `.d.bp`
  to real bodies wherever the now-landed gaps allow; keep `.d.bp` **only** for
  genuinely host-bound intrinsics or async-gated surface, and say which gap gates
  each remaining marker.
- **Decorators are a future layer, not this spec.** jhonstart's component model is
  fn + `use` + `@Context` today. A `#[component]`/`#[client]` decorator layer on
  `annotation-processors`' `@Decl` half is a clean follow-up — recorded here, not
  built.
- **BLOCKED on `annotation-processors` P0** (the de-coupling + generic loader). The
  declarative→real promotions (F1–F4) are independently testable once the gaps are
  in `feat`, but the framework cannot be validated as a *pure client* until P0
  removes the core coupling. Carry the ⛔ banner in `TODO.md`; tests live only in
  `libs/jhonstart/*.bp`.
