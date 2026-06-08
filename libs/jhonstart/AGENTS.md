# libs/jhonstart/

> Path: `libs/jhonstart/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Spec: [`../../tasks/v0.beta.5/specs/jhonstart.md`](../../tasks/v0.beta.5/specs/jhonstart.md)

botopink's **React/Next-style** UI framework, written *in* botopink on the
language's own primitives — **no new compiler features**. Components are plain
functions returning `Element`; hooks are the `@Context<Element, _>` capability
gated by the `use` prefix; server components are `*fn … -> @Future<Element>`; an
optional JSX-like `html` DSL reuses `expr-templates` (`@Expr<Element>`).

Like `server`/`client`, this is a **scaffold** today: `botopink.json` claims no
files, nothing is embedded into the prelude. It is reached with `from "jhonstart"`,
never auto-loaded into the type `Env`.

## Tree

```text
libs/jhonstart/
├── AGENTS.md          ← you are here
├── botopink.json      ← package manifest (files: [] — inert scaffold)
├── docs.md            ← user-facing reference
└── src/
    ├── AGENTS.md
    ├── element.d.bp   ← Element (the ContextBase) + Children
    ├── dom.d.bp       ← DOM builder intrinsics (div/p/button/input/…)
    ├── hooks.d.bp     ← state/effect/memo/ref/reducer — all @Context<Element,_>
    ├── html.d.bp      ← the JSX-like `html` template DSL (signature)
    ├── render.d.bp    ← mount (client) + renderToString (SSR, *fn)
    ├── router.d.bp    ← Router/useRouter/Link (Next-style navigation)
    └── server.d.bp    ← Http ContextBase: request() + loaders
```

## Layers

| Layer | Analog | ContextBase | Files |
|---|---|---|---|
| core | React | `Element` | `element`, `dom`, `hooks`, `html`, `render` |
| app | Next.js | `Http` | `router`, `server` |

## Conventions

- `.d.bp` files declare **signatures only**; the host runtime supplies the
  implementation per target (bound via `@[external(...)]`). Composite ergonomics
  (`Fragment`, `Link`, custom hooks, the `html` body) are ordinary `.bp` built on
  the intrinsics — a future phase (see the spec's F3).
- Components are PascalCase (`Counter`, `Page`); hooks/intrinsics are camelCase
  (`state`, `useToggle`, `renderToString`).
- Not embedded: do **not** wire jhonstart into `comptime/stdlib/prelude.zig` or
  `build.zig`.

## Compiler prerequisites

jhonstart is a *consumer*. The hook/async surface depends on language work:
`context-inference` (✅ landed), `expr-templates` (✅ landed — powers `html`),
`use-await-prefix` and `async-generators` (pending in `tasks/v0.beta.1/`). The
`html` DSL needs only the shipped expr-templates machinery.
