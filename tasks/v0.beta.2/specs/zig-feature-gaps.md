# zig-feature-gaps — catalog of Zig features bp does not support (evaluate later)

**Slug**: zig-feature-gaps
**Depends on**: nothing
**Files**: (analysis only — this spec IS the deliverable; may spawn follow-up specs)
**Touches docs**: docs.md (language reference: a "non-goals" / "differences from Zig" section)
**Status**: pending

> **Goal**: an explicit, decided catalog of Zig language features that have **no bp
> analog** — primarily everything around manual memory. It exists so the
> [`stdlib-tests`](stdlib-tests.md) / [`stdlib-gleam`](stdlib-gleam.md) work can say
> "out of scope" with a reference, instead of silently skipping. This is an
> **evaluation backlog**, not an implementation task: each entry gets a decision, and
> "maybe later" items graduate into their own specs.
>
> **Core stance.** bp's purpose is **not** to control memory access / allocation /
> freeing. Memory is host/runtime-managed (JS, BEAM, WASM). So the allocator/pointer
> half of Zig is a non-goal by design, not a missing feature.

## Decision legend

- ❌ **non-goal** — deliberately won't support (conflicts with bp's philosophy)
- 🟡 **evaluate** — no analog today, but could make sense — open a follow-up spec
- ✅ **has analog** — bp already covers it differently (listed for contrast, not a gap)

## Catalog

### Memory management (the main divergence)
| Zig feature | bp | Decision | Rationale |
|---|---|---|---|
| Allocators (`GeneralPurposeAllocator`, arena, `alloc`/`free`) | — | ❌ non-goal | host/runtime manages memory |
| `defer` / `errdefer` for resource cleanup | `try`/`catch` | 🟡 evaluate | cleanup is useful even without manual memory (handles, locks) |
| Pointers `*T`, `&x`, `.*`, `[*]T`, pointer arithmetic | — | ❌ non-goal | no raw memory model |
| Slices `[]T` (ptr+len) | `Array<T>` | ✅ analog | bp arrays cover the use, without the ptr |
| Alignment (`align()`, `@alignCast`) | — | ❌ non-goal | no memory-layout control |
| `packed` / `extern` struct, bit-level layout | `record`/`struct` | 🟡 evaluate | only if needed for WASM/FFI binary layout |
| `volatile` | — | ❌ non-goal | no hardware/memory semantics |
| `@ptrCast` / `@bitCast` / `@intFromPtr` | — | ❌ non-goal | no pointers to cast |

### Types / reflection
| Zig feature | bp | Decision | Rationale |
|---|---|---|---|
| Error sets (`error{...}`, `anyerror`, `!T`) | `@Result<D,E>`, `throw` | ✅/🟡 | analog exists; evaluate error-set inference/merging gaps |
| `@Type` / `@typeInfo` full reflection | `typeOf`/`typeName`/`hasField`/… builtins | 🟡 evaluate | partial; catalog the missing reflection surface |
| `@Vector` (SIMD) | — | ❌ non-goal | low-level numeric, no bp use case |
| Anonymous structs / tuples | `(a, b)` tuples, `record` | ✅ analog | covered |
| `comptime` type construction | `comptime` values + `typeparam` | 🟡 evaluate | bp has value comptime, not full type-level metaprogramming |

### Control flow / functions
| Zig feature | bp | Decision | Rationale |
|---|---|---|---|
| `async`/`await`/`suspend`/`resume` | `*fn`, `await`, `yield`, `loop await` | ✅ analog | bp's async model differs but covers it |
| Labeled blocks/loops, `break :label value` | `loop :label`, `yield :label` | ✅ analog | covered |
| `unreachable` / `@panic` | `panic`/`trap` builtins | ✅ analog | covered |
| `inline` fn / `inline for` | — | 🟡 evaluate | perf hint; no bp need yet |
| Inline assembly (`asm`) | — | ❌ non-goal | no low-level target |

### Interop / system
| Zig feature | bp | Decision | Rationale |
|---|---|---|---|
| C interop (`@cImport`, `extern`, `callconv`) | `@[external(…)]` | 🟡 evaluate | FFI annotation covers the common case; C ABI specifics out of scope |
| Threads / atomics / mutex | — | 🟡 evaluate | relevant on BEAM (processes) — separate concurrency story |
| `std.testing` allocator / leak checks | `test-blocks` | ✅ analog | bp tests don't need leak checks (no manual memory) |

## Steps

### F0 — complete the catalog
- [ ] Walk the Zig language reference section by section; for each feature, add a row with a decision (❌/🟡/✅)
- [ ] Cross-check against bp's current builtins (`builtins.d.bp`) and language reference

### F1 — record the "non-goals" in the language reference
- [ ] Add a "Differences from Zig / non-goals" section to `docs.md` summarizing the ❌ items (so users know memory control is intentionally absent)

### F2 — graduate the 🟡 items
- [ ] For each `evaluate` row, decide keep-as-non-goal or open a follow-up spec (e.g. `defer-cleanup`, `concurrency-beam`, `reflection-gaps`, `error-set-inference`)
- [ ] Link those follow-up specs here

## Test scenarios

```
docs ---- docs.md has a "non-goals (vs Zig)" section listing the ❌ items
review ---- every 🟡 row has a recorded decision or a linked follow-up spec
```

## Notes

- This spec is **analysis/decision**, not code — its "done" is a complete, decided
  catalog + the non-goals doc section, not a compiler change.
- It is the reference target for "out of scope" notes in `stdlib-tests` and
  `stdlib-gleam`.
- 🟡 rows are intentionally deferred — do not implement here; spin them out.
- Everything in English, including this file.
```
