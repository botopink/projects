# Language gaps — 1.0.9-beta

The compiler is frozen for this milestone. Every front here is built from plain botopink plus
`@Decl`, comptime, `@emit` and `#[@external]`, and a front that needs a compiler change does not get
one. What it does instead is write the nearest form that parses today, mark the line
`// LANGUAGE GAP:`, and record the gap here.

This file is the feed for `specs/1.0.10-beta/`. The exit gate in [`fronts.md`](./fronts.md) requires
every `// LANGUAGE GAP:` marker left in an example to appear in a spec there — a gap that exists
only as a comment in a `.bp` file is a gap nobody will fix.

Rows are added as fronts are written. A row names the gap, where it bites, what the nearest valid
form is today, and what surface would close it.

## Confirmed gaps

| Gap | Bites | Nearest valid form today | Proposed surface |
|---|---|---|---|
| **No bitwise operators** — `&`, `\|`, `^`, `<<`, `>>` do not exist | 01 · 03 · 68 | Push the whole operation into an `#[@External]` host template, once per target | The five operators on the integer behaviors |
| **No `toString(radix)`** on the integer behaviors | 01 · 03 | Same — a host template per target | A radix argument, or a `std/fmt` module that does it in botopink |
| **No byte or binary type** | 01 · 13 · 15 · 24 · 25 · 70 · 71 | Every host cell marshals through `string`, so `net.recv` answers UTF-8 for a byte stream. Front 25 refuses `multipart/form-data` with 415 rather than read it lossily | A `Bytes` primitive with a declared encoding boundary. Without it no file upload, no file download and no image endpoint is expressible |
| **A std module cannot call another std module** — a cross-module bare import of an `#[@External]` symbol is `undefined` at runtime | 01 | Each module re-declares its own host cell | Fix the lowering so a bare import of an external symbol resolves |
| **No array destructuring in a binding** — `val [a, b] = xs;` does not parse | 02 | `xs.at(0)`, `xs.at(1)` | Destructuring patterns in `val`/`var` |
| **`@Future<T>` lowers eagerly on erlang** — the type carries no concurrency on the server target (`libs/std/src/http.bp:16-18`) | 02 · 23 · 25 · 28 · 30 · 60 | Design over **unstarted thunks** (`Array<fn() -> @Future<T>>`) and spawn one BEAM process per task, gathering by index — which is what front 02 now provides | A real scheduler behind `@Future` on BEAM, or an explicit `spawn`/`join` pair in the language |
| **No cancellation** — a losing racer and an expired timeout keep running | 02 | Document it; let the work complete and discard the result | Cancellation tokens, or linked processes with a kill path |
| **`@Decl` carries no source location** — a decorator cannot learn which file it annotates | 22 | The app-relative segment is an explicit decorator argument, generated and verified by front 50's CLI | A source-location field on `@Decl`. This is the defining premise of file-system routing, so the workaround is a CLI that must stay in step with the tree |
| **No `await` inside a `loop` or a closure** — the effect marker attaches to the fn, not the closure | 23 · 24 · 25 | Lift the awaited call out of the loop, or move the body into its own `#[@future]` fn | Allow the marker on a closure, or infer it |
| **Declared parameter defaults are never applied** | every front | Pass every argument explicitly — this is why every jhonstart call spells `attrs:`, and why `LayoutProps` is one record rather than three parameters | Apply declared defaults at the call site |
| **No assignment to a `self` field** | (carried from the ground truth; no front has needed it yet) | Return a new value; every real record is immutable | Either a mutable field form, or a documented statement that records are immutable by design |
| **No bodyless method in a `type` body** | 08 · 09 | Give the method a body that calls a generated helper, or declare it at module level as `pub declare fn` with a host cell | Bodyless method declarations inside a `type`, as the natural shape for `#[query]`-style decorators |
| **`xs[0]` silently drops the index on the BEAM backend** | every server front | `.at(i)`, `.first()`, `.slice(…)` | Fix the beam lowering, or reject the index expression at compile time rather than mis-compiling it |

## Unowned surface — not language gaps, but nobody's front

These came out of writing the fronts and have no owner. Each needs a decision before the wave that
needs it starts.

| Missing thing | First needed by | Note |
|---|---|---|
| **A std JSON walker** | 24 · 25 | `std/json` has no structured value, so a route handler can validate a body and return raw text and nothing more. Candidate for 1.0.10-beta, or a fold-in to a std front |
| **A `Request` test double** | 19 · 25 · and every rakun front that tests a handler | `Request` is a `behavior`, so no test can construct one. Front 25's example implements a `FakeRequest` inline; front 19 should own the real one |
| **New jhonstart element constructors** (`form`, `input`, `button`, `a`, `img`, `nav`, `h2`, `section`) | 24 · 27 · 67 · 53 | `element.bp` is frozen and only eight constructors exist. Fronts are building them through the public `Element` record in their own files, which works but duplicates. A jhonstart front should own the element surface |
