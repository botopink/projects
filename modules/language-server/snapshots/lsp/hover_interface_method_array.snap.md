----- SOURCE
```botopink
val xs = [1, 2, 3];
val y = xs.filter({ x -> true });
            ↑
```

----- HOVER at (line 1, char 12)
kind: markdown

```botopink
fn filter(self: Self, pred: fn(item: T) -> bool) -> Self

    // ── producers (associated — no receiver) ──
    // Pure botopink (no host backing): the host `lists:seq`/`duplicate` have the
    // wrong semantics (`seq` is end-inclusive; `duplicate` swaps the args), so
    // these recurse over `prepend`, giving identical end-exclusive `[start, stop)`
    // and `times`-copy results on every backend.
    default
```

*from `interface Array`*
