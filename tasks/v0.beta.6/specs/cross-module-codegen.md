# cross-module-codegen — concrete types across the package boundary

**Slug**: cross-module-codegen
**Depends on**: nothing (commonJS leg already landed in `feat`)
**Files**: `modules/compiler-core/src/codegen/erlang.zig`, `modules/compiler-core/src/codegen/beam_asm.zig`, `modules/compiler-core/src/codegen/wat.zig` (commonJS done)
**Touches docs**: `modules/compiler-core/src/codegen/AGENTS.md`
**Status**: done — erlang/beam/wasm cross-module parity merged into `feat` (99fb9e9; wasm single-module limit recorded)

## Intent

A library can now ship **concrete, emitted types** that a consumer imports
(`from "rakun"` pulls in `rakun/http` with `Response`/`App`/`HttpMethod`). The
commonJS backend already links these correctly — `require("./<mod>.js")`, `new`
for an imported record, `static` for a record's associated fn, and `exports.X`
for a `pub` type another module imports (the `CrossModule` index in
`commonJS.zig codegenEmit`). This spec brings the **other three backends to
parity** so a rakun (or any cross-package) consumer compiles and runs on every
target, not just node.

The gap surfaced building rakun: erlang lowered `Response.ok(...)` on an imported
record to a remote `response:ok(...)` (→ `undef`); the in-module case is fixed,
but a consumer calling `Response.ok` over the package boundary, and record
*construction* across modules, still need work — and beam/wasm are untouched.

## Examples

### A consumer constructs + calls an imported record (erlang)
```bp
import {Response, App} from "rakun";
fn handler() -> Response { return Response.ok("hi"); }
```
`http.bp`'s `Response`/`App` emit as their own module (`http.erl`, maps for the
record). In the consumer: `Response.ok("hi")` must lower to the **remote** call
into that module (`http:ok(<<"hi">>)`), and `App(8080, "/")` to the module's
map-building constructor — not a bare local call (which only works in-module).

### Same, on beam (`.S`) and wasm (`.wat`)
The emitted package module exports its constructors/associated fns; consumer
call sites reference them across the module boundary with the target's calling
convention.

## Steps

### F0 — erlang cross-package
- [ ] Track which imported names come from which emitted module (mirror the
      commonJS `CrossModule` index, or reuse a shared analysis).
- [ ] `Type.assocFn(...)` on an imported record → remote call to the owning
      module atom; imported record construction → the module's map constructor.
- [ ] Emit `-export` for `pub` types/assoc-fns another module imports.

### F1 — beam_asm cross-package
- [ ] Imported record construction (`put_map_assoc` in the owner) + cross-module
      `call_ext` to the owner module for associated fns.

### F2 — wasm cross-package
- [ ] Decide the wasm module-linking story for imported types (or record the
      explicit limitation if wasm stays single-module for now).

### F3 — shared
- [ ] Lift the commonJS `CrossModule` builder to a backend-agnostic analysis if
      it reduces duplication across the four emitters.

## Test scenarios

```
run (erlang) ---- a consumer importing Response.ok/App from rakun runs + prints
run (beam)   ---- same program runs on the BEAM .S backend
codegen      ---- imported record construction emits the owner-module constructor
codegen      ---- imported associated fn emits a cross-module call, not undef
```

## Notes

- commonJS is the reference implementation — match its behaviour, not its exact
  code. `new` is a JS detail; botopink source never has `new`.
- wasm may legitimately defer (single-module today). If so, `log()` the limit and
  scope this spec to erlang + beam.
