# libs/jhonstart/

> Path: `libs/jhonstart/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Spec: [`../../tasks/v0.beta.7/specs/jhonstart.md`](../../tasks/v0.beta.7/specs/jhonstart.md)
> (port), originally [`../../tasks/v0.beta.5/specs/jhonstart.md`](../../tasks/v0.beta.5/specs/jhonstart.md)

botopink's **React/Next-style** UI framework, written *in* botopink on the
language's own primitives — **no jhonstart-specific compiler features**.
Components are plain functions returning `Element`; hooks are the
`@Context<Element, _>` capability gated by the `use` prefix; server components are
`*fn … -> @Future<Element>`; an optional JSX-like `html` DSL reuses
`expr-templates` (`@Expr<Element>`). The compiler is **unaware** of jhonstart
(hard rule + `grep -riE "rakun|jhonstart" modules/compiler-core/src` gate); the
framework is a pure client, reached with `from "jhonstart"`, never embedded.

The UI **core + hooks are real botopink** (`src/element.bp`, `src/hooks.bp` — both
in `botopink.json`'s compiled set): an `Element` tree, builders, a synchronous SSR
renderer, and the hook family — no host intrinsics, no async. Only the host-bound
/ still-gap-blocked surface (client navigation, the Http server context, the
`html` markup body) stays as `.d.bp` declarations, each with an explicit
"STILL GATED" note. Nothing is embedded into the prelude.

## Tree

```text
libs/jhonstart/
├── AGENTS.md          ← you are here
├── botopink.json      ← manifest (files: element.bp, hooks.bp, html.d.bp, router.d.bp, server.d.bp)
├── docs.md            ← user-facing reference
└── src/
    ├── AGENTS.md
    ├── element.bp     ← COMPILED CORE: record Element + builders (Children) + renderToString + test {}
    ├── hooks.bp       ← COMPILED: State<T> + state/effect/memo/ref/reducer (@Context<Element,_>) + test {}
    ├── html.d.bp      ← the JSX-like `html` template DSL (signature; body GATED — F2)
    ├── router.d.bp    ← Router/useRouter/Link (host-bound navigation; GATED)
    └── server.d.bp    ← Http ContextBase: request() + loaders (host-bound/async; GATED)
```

## Layers

| Layer | Analog | ContextBase | Surface |
|---|---|---|---|
| core | React | `Element` | `element.bp` + `hooks.bp` (**compiled**), `html` (declared) |
| app | Next.js | `Http` | `router`, `server` (declared, host-bound) |

## Conventions

- **Prefer real `.bp`**: implement in botopink whatever the language can express.
  `element.bp` (record, builders, `renderToString`) and `hooks.bp` (the
  `{value, set}` hook family) are ordinary `.bp`. Keep `.d.bp` only for genuinely
  host-bound intrinsics or async-gated surface — and say which gap gates each one.
- Builders take a `Children` arg (`div([a, b])` / single / `string` — the G4
  coercion); the **list form** is what V1 renders and what `html` emits. The
  trailing-lambda sugar (`div { [a, b] }`) is a recorded follow-up.
- Hook bodies are pure/synchronous (SSR / first render): `state` yields its
  initial value, `memo` computes eagerly, `effect` is a no-op. The `use` prefix's
  per-target lowering (React `useState`/… on `commonJS`) is the host runtime's
  job — so hook bodies are unit-tested by **direct call** (no `use`) in `test {}`.
- `renderToString` is **synchronous** (`.bp`); SSR needs no async.
- Components are PascalCase (`Counter`, `Page`); fns/builders camelCase.
- Not embedded: do **not** wire jhonstart into `comptime/stdlib/prelude.zig` or
  `build.zig`.

## Compiler prerequisites (all generic, none jhonstart-specific)

jhonstart is a *consumer*. What it relies on:

- **Landed**: `context-inference` (`@Context`/`use`), `expr-templates` (`@Expr`),
  the G1–G4 gaps (fn-typed fields, anon record types, `fn() -> T[]`, `Children`
  coercion), the generic `from "<lib>"` loader, and — new in this port — generic
  **cross-module nominal-type resolution** (a local component `fn … -> Element`
  whose result feeds an imported `renderToString`/`use` now type-checks; see
  `modules/compiler-core/src/comptime` `type_decl_registry` + `resolveTypeName`).
- **Still gated** (block F2 / router / server, all generic core work):
  - the comptime template body sees only a native-JS prelude (no Option/`unwrapOr`
    runtime) — so `html`'s markup scanner is awkward to express; deferred (F2);
  - the generic loader binds a lib's **namespace** but not bare imported
    values/template-fns — `import {html} from "jhonstart"` leaves `html "…"`
    unbound (same gap as `erika "…"`);
  - `use-await-prefix` / `async-generators` (`tasks/v0.beta.1/`) for the server
    data layer;
  - the `Element` model has no **attribute** slot, so `Link`/form controls can't
    render `href`/`onClick` in pure `.bp` yet.
