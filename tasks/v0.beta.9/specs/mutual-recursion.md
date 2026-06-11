# mutual-recursion — confirm forward references run on every backend

**Slug**: mutual-recursion
**Depends on**: nothing
**Files**: regression tests only (the inference pre-pass already landed); `modules/compiler-core/src/comptime/infer.zig` only if a backend run reveals a gap
**Touches docs**: `docs.md` (§Functions), `modules/compiler-core/src/comptime/AGENTS.md`
**Status**: pending — **F0 already resolved**, this spec only closes the regression gap

> **Carried forward from v0.beta.6, but the hard part is DONE.** The original gap —
> a top-level fn calling another declared *later* failed type-check — **no longer
> reproduces**. Verified 2026-06-10 on `feat` (`038ac51`):
>
> - `fn a() -> i32 { return b(); }  fn b() -> i32 { return 1; }` → **type-checks**.
> - True mutual recursion `isEven ⇄ isOdd` → type-checks on **commonJS, erlang,
>   beam, wasm** and **runs** on commonJS (`botopink run`, exit 0).
> - A genuine unbound name (`zzz`) still errors correctly (no regression in
>   diagnostics).
>
> So the top-level binding pre-pass that this spec asked for already exists in
> `feat` (landed with the jhonstart port's recursive renderer work). What is *not*
> yet proven is a **run** on the non-JS backends and a **committed regression
> test** guarding it.

## Target syntax (works today)

```bp
fn renderChildren(items: Element[]) -> string {
    var out = "";
    loop (items) { c -> out = out + renderToString(c); };   // forward ref — OK now
    return out;
}
fn renderToString(e: Element) -> string {
    if (e.tag == "#text") { return e.value; };
    return "<" + e.tag + ">" + renderChildren(e.children) + "</" + e.tag + ">";
}
```

## Steps

### F0 — confirm + lock in (no inference change expected)
- [ ] Add a regression test: two top-level fns that call each other across
      declaration order compile **and run** — assert the result, not just the exit
      code. Put it where the backend suites live, not in a Zig unit test, if a `.bp`
      run-test fits.
- [ ] Confirm mutual recursion **runs** (not just type-checks) on erlang and beam
      (commonJS already confirmed; wasm if the runner from
      [[stdlib-backends-parity]] F5 is available, else record it deferred).
- [ ] If — and only if — a backend run reveals codegen mis-ordering, fix the
      emitter so a forward-referenced fn resolves; otherwise this spec is
      test-only.

## Test scenarios

```
infer        ---- a() calls b() declared later — type-checks (regression guard)
run/commonJS ---- isEven(10) ⇄ isOdd → true (already green)
run/erlang   ---- same mutual recursion runs + returns the same result
run/beam     ---- same mutual recursion runs + returns the same result
infer        ---- a genuine unbound name still errors (diagnostics unchanged)
```

## Notes

- Scoped deliberately small: the inference fix the v0.beta.6 spec asked for is
  already in `feat`. Keeping the spec only to **prove every backend runs it** and
  to **commit the regression test** the original task never landed.
- If the backend runs are all green with no code change, close this by landing the
  test alone — do not invent work.
