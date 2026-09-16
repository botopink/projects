# Turning `executeWat` on, and the four symbols nothing defines

Two decisions that decide what the wasm suite can see: when `executeWat` may execute, and what to do
with `Module.externs`.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`, except those starting with
`libs/`, which are relative to `repository/botopink-lang/`. Every `file:line` is at HEAD.

---

## Where it stands

`executeWat` (`src/codegen/runtime.zig:547-558`, the fn at `:553`) is a stub:

```zig
/// WebAssembly Text execution — **a stub**: every wasm RUN LOG is empty
/// until a runtime is wired back in (spec 03 step 2). The embedded wasm3
/// interpreter it used to call was removed with `vendor/wasm3`.
pub fn executeWat(allocator: std.mem.Allocator, wat_code: []const u8, module_name: []const u8, io: anytype) ![]u8 {
    _ = wat_code;
    _ = module_name;
    _ = io;
    return allocator.dupe(u8, "");
}
```

So wasm is the only backend with **0** observable RUN LOGs, and all 128 executable `b` fixtures
record nothing. The doc comment's "spec 03 step 2" names a spec step that no longer holds this
work; point it at this front when the stub changes.

## What turning it on today would pin

Measured by running every emitted module under `wasmtime run <module>.wat` (wasmtime 45) — see
[`causes.md`](./causes.md#how-the-numbers-were-measured):

| What the RUN LOG would record | `b` (128) | `a` (145) |
|---|---|---|
| the value the program means | 64 | 134 (empty, correctly) |
| **a knowingly-wrong value** | **35** | — |
| **an empty log for a module that aborted** — 27 unresolved calls (W1), 1 `@todo` (correct), 1 out-of-bounds load (W10) | **29** | 11 (3 unresolved calls, 8 `@todo`/`@panic`) |

**Turning it on today pins 35 knowingly-wrong RUN LOGs and 29 empty ones.** The empty ones are the
dangerous half. The harness records an empty RUN LOG for any non-zero exit — the shared run tail at
`src/codegen/runtime.zig:537-542`:

```zig
if (ran.status != .ok) {
    allocator.free(ran.output);
    const empty = try allocator.dupe(u8, "");
    if (ran.status == .failed) cacheWrite(io, allocator, &key, empty);
    return empty;
}
```

so a `wasm trap: wasm 'unreachable'` would be recorded exactly like a program that ran fine and
printed nothing. That is the failure mode 1.0.1-beta spent the milestone undoing, and beam's
`narrow_if_null_check_with_print` already shows how it misleads: that module runs, exits 0 and
prints nothing, and the coverage pivot files it under `b/empty`, which reads as "crashed".

## The condition

It is not "fix everything first". It is:

> `executeWat` may be turned on once **a wasm abort is recorded as a visible block** — a
> `RUNTIME TRAP (wasmtime):` section carrying the trap message, exactly as `COMPILE ERROR (erlc):`
> is recorded today (`src/codegen/runtime.zig:507`, `compileFailureLog`) — **and** W1 is closed, so
> reaching `unreachable` always means the *program* aborted rather than the backend giving up.

With those two in place nothing can be silently wrong: a trap shows as a trap, a wrong value shows
as a wrong value, and each remaining wrong value is pinned only with the divergence stated in its
test.

What it pins once the condition holds: the 64 correct values; a `RUNTIME TRAP` block on
`try_with_inline_catch_handler` and on the 8 label-`a` `@todo`/`@panic` fixtures (correct aborts,
now visible); a `RUNTIME TRAP` on `option_method_on_tuple_element` (W10) until it is fixed; and the
35 wrong values of W2…W9 and W11, each of which must carry its divergence in the test — or wait for
its cause to land — because "no wasm RUN LOG is accepted while its module is known to print the
wrong value".

## Recommended order

1. **Record the trap block** — a small change in `src/codegen/runtime.zig`, no lowering work. Do this
   first: it is what makes every later step's result legible.
2. **W1** — pass `instance_lowerings`, then the seven sub-classes
   ([`causes.md` § W1](./causes.md#w1--the-backend-is-never-handed-instance_lowerings-27-fixtures)).
3. **Turn `executeWat` on**, and bump `HARNESS_VERSION` (`src/codegen/runtime.zig:175`, currently
   `"2-exit-status"`) in the same commit — it is the first input of the content-keyed cache key
   (`:184`), so a warm cache would hide the change.
4. **W2/W3** (13 fixtures, one site), then W4, W5, W6, then the rest.

## Mechanics

- `wasmtime run <module>.wat` accepts the `.wat` text directly and runs the `_start` export the
  backend already emits (`src/codegen/wat.zig:1837`, `.exports = &.{ "_botopink_main", "_start" }`).
  So `executeWat` is `runCaptured` plus the existing content-keyed cache, the same shape as its
  siblings.
- wasm is single-module, so there is **no `aux` leg** (unlike `executeBeamAsm`, which assembles
  sibling `.S` modules).
- Do **not** reuse the erlang early-bail heuristic that skips a module with no `@print`: a wasm
  module with no `@print` can still trap, and that is exactly what must be seen — the 3 label-`a`
  unresolved-call aborts are only visible this way.
- A missing `wasmtime` must behave like a missing `erl` (`.unavailable` → empty, uncached), not like
  a failure.

## Ownership

`src/codegen/runtime.zig` is owned by no front in [`../fronts.md`](../fronts.md#ownership), and it is
also where the js-bridges front's `node --check` gate goes
([`../08-js-bridges/README.md`](../08-js-bridges/README.md)). Steps 1 and 3 both edit it: **stop and
report** to agree the owner before editing. The CI install of wasmtime
(`.github/workflows/test.yml:82-100`) is [`../02-cli-gate/`](../02-cli-gate/README.md)'s, and
[`../11-hygiene/wat-runtime.md`](../11-hygiene/wat-runtime.md) waits on this decision to keep or drop
it.

---

## Module externs — four symbols nothing defines

`Builder.externCall` (`src/codegen/wat/wat_ast.zig:564-569`) lets a module `call` a symbol it does
not define by recording it in `Module.externs` (`:268`). `declaresCall` (`:319-325`) treats an
extern as declared, so `validateModule` (`:334`, the check at `:346`) accepts the call. Four symbols
use it:

| Symbol | Build site | Reached from |
|---|---|---|
| `$__emit` | `src/codegen/wat.zig:2428` | the `emit` decorator builtin |
| `$__compilerError` | `src/codegen/wat.zig:2435` | the `compilerError` decorator builtin |
| `$__binding_ref` | `src/codegen/wat.zig:2443` | the `Binding.ref(entry)` template builtin |
| `$__str_concat_rt` | `src/codegen/wat.zig:3634` | template-body string `+` in `lowerBinOp` (`uses_str_concat_rt`, set only by `emitFnWat`) |

They were defined by the `wat_runtime` prelude that `emitFnWat` (`src/codegen/wat.zig:130`) output
was concatenated with — and **`wat_runtime.zig` no longer exists**: it was deleted with the vendored
`wasm3` module, before this milestone. The code already says so in a `KNOWN GAP` comment
(`src/codegen/wat.zig:2416-2424`). The evidence that this is a **delete-or-ship decision and not a
dangling-symbol bug**:

| Check | Result |
|---|---|
| Does anything define the four symbols? | no — `rg '__str_concat_rt\|__emit\|__compilerError\|__binding_ref' modules/` finds only these four call sites and their comments |
| Does any snapshot reach an arm? | no — `rg '__str_concat_rt\|__emit\|__compilerError\|__binding_ref' snapshots/codegen/wasm/` is empty |
| Does anything call `emitFnWat`? | **no — zero callers anywhere in `modules/`.** The 1.0.1-beta note said "no consumer outside `tests/wat.zig`"; there is no consumer at all, test included |
| Does the host it was written for still exist? | no — `src/codegen/wat.zig:129` says the output "runs through `wasm3_host.runWat`", and `wasm3_host` does not exist either |

### Recommendation

The single-fn comptime path has no caller and no runtime, so the decision is between shipping the
definitions — only worth it if the wasm3-era comptime path is coming back, and
`src/codegen/config.zig:22-23` and `src/codegen/runtime.zig:548-549` both record that it was retired
— and deleting.

**Delete:** `emitFnWat`, `renderItem`'s bare-form path (`src/codegen/wat/wat_emitter.zig:40`), the
four `externCall` sites, and `Module.externs` + `Builder.externs` with them, and lower those four
builtins to the honest `;; …` placeholder the rest of `wat.zig` uses. The unit test that goes with
it is `src/codegen/wat/wat_emitter.zig:352` (`ok.externs = &.{"nope"}`). The `uses_str_concat_rt`
flag (`src/codegen/wat.zig:441-444`) has no other setter and goes too.

### The comment sweep

Either way, every comment that still names a file that is not there must stop. Sites found by
`rg 'wat_runtime|wasm3' ` at HEAD:

| File | Lines |
|---|---|
| `src/codegen/wat.zig` | 127, 129, 138, 442, 968, 2417 (the `KNOWN GAP` block `2416-2424`) |
| `src/codegen/wat/wat_ast.zig` | 265, 494 |
| `src/codegen/tests/wat.zig` | 402-403 |
| `src/codegen/tests/features.zig` | 927 |
| `src/comptime/tests/helpers.zig` | 127 |
| `src/codegen/AGENTS.md` | 508-514 |
| `libs/std/src/builtins.d.bp` | 272 |

`src/codegen/wat.zig:965` (the `emitFnWat` section header, which names the retired template
evaluator path) goes with the deletion. `libs/std/src/builtins.d.bp` is
[`../03-std-surface/`](../03-std-surface/README.md)'s file — hand that line over rather than editing
it. `build.zig:17`, `:95`, `src/codegen/config.zig:22-23` and `src/codegen/runtime.zig:548-549` also
name `wasm3`; those are [`../11-hygiene/wat-runtime.md`](../11-hygiene/wat-runtime.md)'s, not this
step's.

**This is the safest independent piece of the front:** it touches no other backend, changes no
snapshot and has no caller to break. Hand it to a second worker.

**Acceptance:**
- [ ] No symbol is callable without a definition, or `Module.externs` is gone
- [ ] 0 references to `wat_runtime` or `wasm3_host` outside a changelog
- [ ] wasm snapshots byte-identical
