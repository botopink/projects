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
└── jonhstar/          ← expr-templates showcase: comptime html template lib
    ├── jhonstart.bp       ← `html(comptime q: @Expr<string>)` — parts/build DSL
    └── main.bp            ← `\\` line-string template with `${name}`, expanded at compile time
```

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
