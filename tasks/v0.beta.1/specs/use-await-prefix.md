# `use` / `await` — prefix operators

**Branch**: `feat/use-await-prefix`
**Phase**: F3
**Depends on**: nothing (independent)
**Status**: pending

> Reworks `Expr.useHook` (commit `a42d948`): the hook stops being a statement with its
> own destructure and becomes a **prefix operator**; the binding (record/tuple/simple)
> comes from the regular `val`/`var` — for free.

## Principle

Symmetry: `use` : `@Context` :: `await` : `@Future`. Both are prefix operators gated by
the interface on the function's return type.

```bp
fn Panel() -> Element {
    val {count, set} = use state(0);     // record destructure (from val)
    val [a, b]       = use pair();       // tuple destructure (from val) — free
    val doubled      = use memo({ -> count * 2 });
    use effect({ -> log("x") });         // void: expression statement
    val resp         = await fetch(url); // async
}
```

### Custom hook (composing hooks)
```bp
fn useToggle(initial: bool) -> @Context<Element, {on: bool, toggle: fn()}> {
    val {on, set} = use state(initial);   // hook inside a hook
    return { on, toggle: { -> set(!on) } };
}

fn Button() -> Element {
    val {on, toggle} = use useToggle(false);   // uses the custom hook
    button(toggle) { if on { "on" } else { "off" } }
}
```

### Combined `try await`
```bp
*fn load(url: string) -> @Result<Data, Error> {
    val resp = try await fetch(url);   // await unwraps @Future, try unwraps @Result
    return parse(resp);
}
```

## Steps

1. AST: `Expr.usePrefix { inner: *Expr }` + `Expr.awaitPrefix { inner: *Expr }`
2. AST: remove the destructure internal to `useHook` (binding comes from `val`/`var`)
3. Parser: `use <expr>` as prefix (like `try`)
4. Parser: `await <expr>` as prefix
5. Parser: re-validate the `use` static prefix (all before any branch/return) against the new node
6. Format/print: emit `use expr` / `await expr`
7. Snapshots: `use_prefix_in_binding`, `use_prefix_void_statement`, `use_prefix_tuple_binding`, `format/use_prefix`

## Test scenarios

```
parser ---- val {v, s} = use state(0);
parser ---- val [a, b] = use pair();        (tuple via val — free)
parser ---- val x = use memo({ -> ... });
parser ---- use effect();                   (void statement)
parser ---- val r = await fetch(url);       (await prefix)
parser ---- use after if branch (error: not in static prefix)
parser ---- use after early return (error: not in static prefix)
```

## Notes

- Semantic validation (`use` requires `@Context`, `await` requires `@Future`) lives in
  `feat/context-inference` (F7) and the async file.
- Only the `await` **prefix** lands here. Full `*fn`/`yield`/`loop await` is in
  `async-generators.md`.