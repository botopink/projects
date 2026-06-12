# cross-module-codegen — concrete types across the package boundary

**Slug**: cross-module-codegen
**Depends on**: nothing (the commonJS leg already landed in `feat`)
**Files**: `modules/compiler-core/src/codegen/erlang.zig`, `modules/compiler-core/src/codegen/beam_asm.zig`, `modules/compiler-core/src/codegen/wat.zig` (commonJS done)
**Touches docs**: `modules/compiler-core/src/codegen/AGENTS.md`
**Status**: pending

> Carried forward from v0.beta.6 (never merged). A draft erlang leg lives on the
> preserved `task/cross-module-codegen` branch (`a9e2ad2`, unmerged off an old
> `feat`) — **review and rebase or redo**; do not blind-merge a stale codegen
> commit. Memory: [[reference_worktree_merge_param_threading]].

## Intent

A library can now ship **concrete, emitted types** that a consumer imports
(`from "rakun"` pulls in `Response`/`App`/`HttpMethod`; `from "erika"` pulls in
`Query<T>`). The commonJS backend already links these correctly — `require`, a map
constructor for an imported record, `static` for a record's associated fn, and
`exports.X` for a `pub` type another module imports (the `CrossModule` index in
`commonJS.zig`). This spec brings the **other three backends to parity** so a
cross-package consumer compiles and runs on every target, not just node.

The gap surfaced building rakun: erlang lowered `Response.ok(...)` on an imported
record to a remote `response:ok(...)` (→ `undef`); the in-module case is fixed, but
a consumer calling `Response.ok` over the package boundary, and record
*construction* across modules, still need work — and beam/wasm are untouched.

> **Relation to `stdlib-backends-parity`.** That spec lowers *std* method dispatch
> on beam/wasm; this spec links *library-emitted concrete types* across the module
> boundary. They touch the same three emitters — sequence the merges.

## Examples

### A consumer constructs + calls an imported record (erlang)
```bp
import {Response, App} from "rakun";
fn handler() -> Response { return Response.ok("hi"); }
```
`http.bp`'s `Response`/`App` emit as their own module. In the consumer:
`Response.ok("hi")` must lower to the **remote** call into that module
(`http:ok(<<"hi">>)`), and `App(8080, "/")` to the module's map-building
constructor — not a bare local call (which only works in-module).

### Same, on beam (`.S`) and wasm (`.wat`)
The emitted package module exports its constructors/associated fns; consumer call
sites reference them across the module boundary with the target's calling
convention.

## Steps

### F0 — erlang cross-package
- [ ] Track which imported names come from which emitted module (mirror the
      commonJS `CrossModule` index, or reuse a shared analysis).
- [ ] `Type.assocFn(...)` on an imported record → remote call to the owning module
      atom; imported record construction → the module's map constructor.
- [ ] Emit `-export` for `pub` types/assoc-fns another module imports.

### F1 — beam_asm cross-package
- [ ] Imported record construction (`put_map_assoc` in the owner) + cross-module
      `call_ext` to the owner module for associated fns.

### F2 — wasm cross-package
- [ ] Decide the wasm module-linking story for imported types — or `log()` the
      explicit limitation if wasm stays single-module for now (parity with the
      `stdlib-backends-parity` wasm-single-module stance).

### F3 — shared
- [ ] Lift the commonJS `CrossModule` builder to a backend-agnostic analysis if it
      reduces duplication across the four emitters.

## Test scenarios

```
codegen/erlang ---- a consumer's Response.ok("hi") lowers to the owner module's remote call + runs
codegen/erlang ---- imported App(8080,"/") constructs the owner's record map
codegen/beam   ---- the same import constructs + calls across the module boundary
codegen/wasm   ---- imported-type construction links, OR the limitation is recorded
```

## Notes

- `new` is a JS detail; botopink source never has `new`.
- wasm may legitimately defer — if so, record the limit and scope to erlang+beam,
  matching how `stdlib-backends-parity` handles wasm single-module.
- The first real consumer is a `from "rakun"` app (F5 in [[rakun]]); align the two.
