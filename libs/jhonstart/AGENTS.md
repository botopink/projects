# libs/jhonstart/

> Path: `libs/jhonstart/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Spec: [`../../tasks/v0.beta.5/specs/jhonstart.md`](../../tasks/v0.beta.5/specs/jhonstart.md)

botopink's **React/Next-style** UI framework, written *in* botopink on the
language's own primitives — **no new compiler features**. Components are plain
functions returning `Element`; hooks are the `@Context<Element, _>` capability
gated by the `use` prefix; server components are `*fn … -> @Future<Element>`; an
optional JSX-like `html` DSL reuses `expr-templates` (`@Expr<Element>`).

The UI **core is real botopink** (`src/element.bp`, in `botopink.json`'s compiled
set): an `Element` tree, builders, and a synchronous SSR renderer — no host
intrinsics, no async. Only the host-bound / gap-blocked surface (interactive
hooks, client `mount`, router, Http server context) stays as illustrative
`.d.bp`. Nothing is embedded into the prelude; reached with `from "jhonstart"`,
never auto-loaded into the type `Env`.

## Tree

```text
libs/jhonstart/
├── AGENTS.md          ← you are here
├── botopink.json      ← package manifest (files: ["element.bp"])
├── docs.md            ← user-facing reference
└── src/
    ├── AGENTS.md
    ├── element.bp     ← COMPILED CORE: record Element + builders + renderToString + test {}
    ├── hooks.d.bp     ← state/effect/memo/ref/reducer (@Context<Element,_>) — blocked by G1
    ├── html.d.bp      ← the JSX-like `html` template DSL (signature; body pending)
    ├── router.d.bp    ← Router/useRouter/Link (Next-style navigation)
    └── server.d.bp    ← Http ContextBase: request() + loaders
```

## Layers

| Layer | Analog | ContextBase | Surface |
|---|---|---|---|
| core | React | `Element` | `element.bp` (compiled), `hooks`/`html` (declarative) |
| app | Next.js | `Http` | `router`, `server` (declarative) |

## Conventions

- **Prefer real `.bp`**: implement in botopink whatever the language can express
  (the `Element` record, builders, `renderToString` are ordinary `.bp`). Keep
  `.d.bp` only for genuinely host-bound intrinsics (client `mount`) or surface
  blocked by a language gap (hooks' `{value, set}` returns — gap G1).
- Builders take `Element[]` args (`div([a, b])`), not a `fn() -> Children`
  trailing lambda (`div { [a, b] }`, blocked by gaps G3/G4 — see spec Notes).
- `renderToString` is **synchronous** (`.bp`); SSR string output needs no async.
- Components are PascalCase (`Counter`, `Page`); fns/builders camelCase.
- Not embedded: do **not** wire jhonstart into `comptime/stdlib/prelude.zig` or
  `build.zig`.

## Compiler prerequisites

jhonstart is a *consumer*. The hook/async surface depends on language work:
`context-inference` (✅ landed), `expr-templates` (✅ landed — powers `html`),
`use-await-prefix` and `async-generators` (pending in `tasks/v0.beta.1/`). The
`html` DSL needs only the shipped expr-templates machinery.
