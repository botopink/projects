# mutual-recursion — forward references between top-level functions

**Slug**: mutual-recursion
**Depends on**: nothing
**Files**: `modules/compiler-core/src/comptime/infer.zig` (top-level binding pre-pass)
**Touches docs**: `docs.md` (§Functions), `modules/compiler-core/src/comptime/AGENTS.md`
**Status**: pending

> **Why.** Surfaced writing `renderToString` in `libs/jhonstart`. A function may
> call *itself* (its own name is in scope inside its body), but it may not call
> another top-level function declared *after* it: the earlier function sees the
> later one as out of scope. So mutually-recursive top-level functions don't
> compile, and the jhonstart renderer had to inline its child-walk into one
> self-recursive function instead of a clean `renderToString`/`renderChildren`
> pair.

## Target syntax

```bp
fn renderChildren(items: Element[]) -> string {
    var out = "";
    loop (items) { c -> out = out + renderToString(c); };   // forward ref
    return out;
}
fn renderToString(e: Element) -> string {
    if (e.tag == "#text") { return e.value; };
    return "<" + e.tag + ">" + renderChildren(e.children) + "</" + e.tag + ">";
}
```

## Examples

### Forward reference between two top-level fns — fails today
```bp
fn a() -> i32 { return b(); }   // error: 'b' is not in scope
fn b() -> i32 { return 1; }
```
Self-recursion (`fn a() { … a() … }`) already works, so a function's own name is
bound before its body is checked. The fix is to bind **all** top-level function
names before inferring **any** body.

## Steps

### F0 — inference
- [ ] Pre-pass: register every top-level `fn`/`pub fn` signature (name → type
      scheme) into the environment *before* inferring any body, so bodies can
      reference functions declared later (mirrors how recursive `record` type
      names already resolve)
- [ ] Confirm mutual recursion type-checks and that error reporting for a genuine
      unbound name is unchanged

## Test scenarios

```
infer   ---- forward_reference_top_level    (a() calls b() declared after — ok)
infer   ---- mutual_recursion               (renderToString ⇄ renderChildren — ok)
infer   ---- still_reports_unbound           (a truly undefined name still errors)
```

## Notes

- Order-independence for top-level declarations is the expected behaviour in most
  languages; this removes a surprising ordering constraint.
- Once it lands, the jhonstart renderer can split into the natural
  `renderToString`/`renderChildren` pair (currently inlined as a workaround).
