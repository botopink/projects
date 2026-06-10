# examples/

> Path: `examples/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Standalone `.bp` example programs that show what botopink code looks like. These
are documentation/showcase files — they are **not** part of any snapshot harness
and do not affect `zig build` / `zig build test`.

## Tree

```text
examples/
├── AGENTS.md          ← you are here
├── hello.bp           ← smallest runnable program (prints a line)
├── erika-linq/        ← generic loader showcase (WORKS): `import {of, erika} from "erika"`
│   └── src/main.bp        ← fluent `of(list).where(…).toArray().join(…)` + the SQL
│                            sub-language `erika "…"` / `erika """…"""`, cross-module
├── generic-loader-binding/ ← generic loader showcase (WORKS): the three `from "<lib>"` forms
│   └── src/main.bp        ← bare value (`of`), bare template fn (`erika "…"`), namespace (`erika.of(…)`)
├── jonhstar/          ← expr-templates showcase: comptime html template lib
│   ├── jhonstart.bp       ← `html(comptime q: @Expr<string>)` — parts/build DSL
│   └── main.bp            ← `\\` line-string template with `${name}`, expanded at compile time
├── yamlconf/          ← expr-templates showcase: config template (model 2)
│   ├── yamlconf.bp        ← `conf<T>` lifts a computed `record { … }` structure
│   └── main.bp            ← caller gets the structural type (`cfg.server.port`)
├── jhonstart-counter/ ← jhonstart (React/Next) showcase: component + hooks + events
│   └── main.bp            ← `use state`/`use effect`, `button(onClick){…}`, `mount`
├── jhonstart-todo/    ← jhonstart showcase: lists, controlled input, custom hook
│   └── main.bp            ← `items.value.map(…)` → `li`, `useToggle`
├── jhonstart-html/    ← jhonstart showcase: JSX-like `html` DSL (`<Component/>` + `${…}`)
│   ├── main.bp            ← `html \\<div><Page1/>…` expanded to an Element tree
│   └── pages.bp           ← `Page1/Page2/Page3` components resolved by the template
├── jhonstart-app/     ← jhonstart showcase: Next-style routing + server data loading
│   ├── main.bp            ← SSR entry: `await renderToString(await Page())`
│   └── app/               ← file-routing convention (layout.bp, page.bp, posts/[id]/page.bp)
└── rakun/             ← Spring-style framework showcase (ILLUSTRATIVE — targets the
    │                       planned `rakun` lib; spec: tasks/v0.beta.5/specs/rakun.md)
    ├── users.bp          ← #[repository]→#[service]→#[restController] DI triad + routes
    └── main.bp           ← `Rakun.run(App(port: 8080))` bootstrap
```

> The `rakun/` and `jhonstart-*/` files are **illustrative**: they target planned
> libraries (both are inert scaffolds today — specs:
> `tasks/v0.beta.5/specs/`), so they document intended usage and do not yet
> compile against the current toolchain — unlike the other examples here. The
> `jhonstart-html` demo is the closest to working: its `html` DSL needs only the
> shipped `expr-templates` machinery.

## Running an example

The `botopink` CLI is project-based — it reads a `botopink.json` and compiles the
modules under `src/`. To run a single example file, drop it into a throwaway
project:

```bash
botopink new demo            # scaffolds botopink.json + src/main.bp
cp examples/hello.bp demo/src/main.bp
cd demo && botopink run      # → hello, botopink
```

`botopink check` (type-check only) and `botopink build` (emit target code) work
the same way from inside the project.

## Conventions

- Keep each example minimal and self-contained — it must compile with the
  current compiler.
- Do not wire examples into snapshot tests; they are illustrative, not fixtures.
