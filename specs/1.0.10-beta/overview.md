# Specs — 1.0.10-beta: the milestone cut once

1.0.10-beta is the open half of the compiler milestone ([1.0.5-beta](../1.0.5-beta/closure.md),
carried as one front) and the whole of the ecosystem milestone
(1.0.9-beta, which merged 1.0.6 rakun, 1.0.7 onze/jhonstart and 1.0.8 emilia) plus what every
library test stands on — the
assertion library, the snapshot engine and the `@src()` builtin that names a snapshot — in one
directory, ordered by what blocks what: every 1.0.9 front keeps its number and its files, and every
open 1.0.5 row has an id (decision 68; the mapping is [`unification.md`](./unification.md)).

**Where the milestone stands is [`status.md`](./status.md)** — the one file allowed to carry status,
kept current in the same commit as the work it reflects. **What the maintainer has decided and still
owes is [`decisions-taken.md`](./decisions-taken.md) and [`decisions-pending.md`](./decisions-pending.md)**
— numbering continued from 1.0.5-beta (68 onwards), never reused.

## Fronts

A front here is a *directory of fronts*: the number is the blocking order, the sub-fronts inside keep
their 1.0.9 numbers (identifiers, never reassigned — `03-rakun/23-rakun-ssr-pipeline/` is still
"front 23").

| Front | Priority | What |
|---|---|---|
| [`00-compiler-carry-over/`](./00-compiler-carry-over/README.md) | critical (two items pulled ahead), the rest beside | The open half of 1.0.5-beta as 25 prioritised items C-01…C-25: the type's identity in the value and one BEAM module per type (C-01), the index as a method call (C-02), the host-bound std wrapper (C-03), trailing defaults, module-level `var`, the run-time tails of decision 8, the parser gaps, the formatter's width, the optional `;` … Each item carries its 1.0.5 deep dives. Seven fronts sit inside it beyond the carry-over: [`18-comptime-runtimes`](./00-compiler-carry-over/18-comptime-runtimes/README.md) (C-26 — `.beam` emitted directly, a WAT comptime runtime on wasm3, snapshots per runtime, the compiler on wasm in the browser), [`19-use-activation`](./00-compiler-carry-over/19-use-activation/README.md) (C-27 — the `use` construct hooks and components are written with), [`20-builtins-surface`](./00-compiler-carry-over/20-builtins-surface/README.md) (C-28 — `builtins.d.bp` agreeing with itself and the effect chain of decision 95), and the three surface fronts of decisions 102–108: [`21-effect-chain`](./00-compiler-carry-over/21-effect-chain/README.md) (C-29 — `@Context<Base>` is only the owner marker; one grant of `use`; the three generators over one `YieldStep`; `getContext` — re-cut by 24), [`22-loops`](./00-compiler-carry-over/22-loops/README.md) (C-30 — `loop` / `while (…)` / `for (…) { x -> }` / `for await`, the loop that is a generator expression (spelled `iter loop` / `stream loop` by 24), `yield` / `break v` only in a generator scope) and [`23-std-purity`](./00-compiler-carry-over/23-std-purity/README.md) (C-31 — std as a pure root · `io/` · `testing/`, and the import tree `import {a: {b: {c}}, x.y.z, e.t.r*}`). They run 21 → 22 → 23, one at a time; 23 after `01-std`'s fronts 01/02/03 merge. Then, alone, [`24-effects-by-return`](./00-compiler-carry-over/24-effects-by-return/README.md) (C-32 — decisions 118–128: the return type is the annotation, `@Task<T>` never fails, only `@Result` fails, `@Iterator<T>` / `@Stream<T>`, `async { }`, `iter` / `stream` loops, no compatibility mode, the codemod `botopink migrate effects` and the sweep of every library and every library front's examples) |
| [`01-std/`](./01-std/README.md) | **critical — blocks everything** | `@src()` in the compiler → `import {asserts} from "std"` (`isTrue`, `isFalse`, `equals`, `notEquals`, `isNil`, `isNotNil`, `isOk`, `isError`, `contains`, `throws`, and the rest of the inventory) → the `std/snapshots` engine (`__snapshots__/<suite>/<slug>.snap`, `.new` on mismatch, no update flag) → the old `onze` mocking library retired into `std/asserts` → the orchestrator takes the name `onze` → the three std enablement fronts of 1.0.9 (01–03) → the bundled `routing` library (`04-routing-lib`, decision 115): the route matcher, the routing wires, the navigation vocabulary and the `:param` grammar server and browser share → the bundled `actions` and `validation` libraries (`05-actions-lib`, `06-validation-lib`, decision 116): the server-action protocol, and validation moved out of rakun → std writes and reads JSON (`01-std-lib-enablement`'s last steps: `json.quote` and the writers, `escape.scriptJson`, the structured `Json` and `json.decode` — decisions 116, 117) |
| [`02-packaging/`](./02-packaging/README.md) | high — lands alongside each library's first front | `repository/<lib>/modules/<lib>/`, `modules/<lib>-test/`, `modules/<lib>-<domain>/`, `examples/<project>/`; the manifest shapes the compiler actually parses; how `test-libs` discovers them; the dependency direction; front 95 carried beside it. Each library refines the cut in its own `modules.md` |
| [`03-rakun/`](./03-rakun/README.md) | per front — see its README | 51 fronts (04–25 · 60–66 · 72–93): Spring Boot 4 parity plus the server half of Next.js, on erlang (decision 113) — rakun serves; it builds no HTML. `modules.md` reconciles the 13 submodules already scaffolded under `repository/rakun/modules/` with the reference cut; `test-snap.md` / `test-snap-examples.md` are the preventive snapshot maps |
| [`04-jhonstart/`](./04-jhonstart/README.md) | per front | 9 fronts (26–32 · 67 · 94): the React half of Next.js — router, link, server components, client directive, the render and streaming (with the `jhonstart-emilia` bridge), error boundaries, metadata, forms, the element surface. jhonstart writes all the HTML (decision 113) |
| [`05-emilia/`](./05-emilia/README.md) | per front — may start on day one | 22 fronts (33–48 · 54–59): Tailwind CSS v4 parity — theme and cascade first, then the utility catalogue, modifiers, preflight, escape hatches, container queries, custom utilities, the attribute slot. `reference-coverage.md` is the Tailwind walk 1.0.8 never wrote; `tailwind-mapping.md` is carried |
| [`06-onze/`](./06-onze/README.md) | per front | 9 fronts (49–53 · 68–71): the orchestrator `onze` (its 1.0.7 draft name is in `unification.md`) — stand-up, CLI, image, font, the client bundle, the styling pipeline, image response, release packaging, and the example app that proves the whole stack. onze is the one package that imports jhonstart, rakun and the `jhonstart-emilia` bridge together (decision 113) |

Top-level documents: [`fronts.md`](./fronts.md) (ownership, the conflict matrix, the waves, the exit
gate) · [`contracts.md`](./contracts.md) (the cross-library contracts, now with contract 7 — the
test/snapshot contract) · [`language-gaps.md`](./language-gaps.md) (every compiler gap a library
front filed, each pointing at its `00` item) · [`deferred.md`](./deferred.md) (what has no path on
BEAM and why) · [`unification.md`](./unification.md) (old path → new path, front 01–96).

## Order

```
wave 0    01-std ───────────────────────────────────────────┐
          @src() · asserts · snapshots · old onze retired ·  │
          onze13 → onze · std enablement 01/02/03 ·          │
          the bundled routing library (01-std/04) ·          │
          bundled actions and validation (05, 06) ·          │
          json.quote and the writers (07)                    │
                                                             │
          00: C-01 module identity ──── pulled ahead ────────┤   (every erlang cell re-runs after it)
          00: @src() (01-std's carve-out into the compiler) ─┤   (contract 7: no snapshot test without it)
                                                             ▼
wave 1    02-packaging ── alongside the first front of each library:
          03-rakun 04 · 05 · 22 · 72      04-jhonstart 26 · 94      05-emilia 54 · 56 · 33 · 34 · 35      06-onze 49
                                                             │
waves 2–5 the 1.0.9 waves, unchanged (fronts.md § Waves):    ▼
          06 ► 07 · 08 · 11 · 12 · 13 · 14 · 15 · 16 · 17 · 19 · 21     22 ► 23 · 61 · 65     26 ► 27 · 28
          07 ► 09 · 10 · 18 · 20 · 76 · 87      23 ► 24 · 25 · 66 · 69      28 ► 29 · 30 · 31 · 32
          62 ► 60 · 64      29 ► 68      24 + 68 ► 67      26 + 48 ► 50 · 51 · 52 · 70 · 71 · 81
          … ► 53-onze-example-app (the proof)

beside    00-compiler-carry-over, C-02 … C-31 on its own order (C-01 is the spine; the surface
          fronts 21-effect-chain → 22-loops → 23-std-purity one at a time, 23 after 01-std's
          fronts 01/02/03 merge, then 24-effects-by-return alone); the libraries consume what
          lands and file gaps for what does not.
```

**Why `01-std` is first, in terms of what the others cannot verify without it.** Every `<lib>-test`
submodule is `assert<Subject>(loc, …)` helpers over `std/asserts` and `std/snapshots`, and every one
of those helpers takes a `SourceLocation` that only `@src()` can produce. A library front that lands
before `01-std` has tests it cannot write, or writes them against a private assertion copy that the
restructure then deletes. The `onze` name is the second reason: the orchestrator cannot take a
directory the mocking library still occupies.

**Why `02-packaging` is second and not first.** It is the directory tree every library front writes
into; but its `-test` submodules are built on `01-std`, so it cannot land before it. It lands beside
each library's first front rather than as one big move, because a move of files no front has written
yet moves nothing.

**Why the compiler runs beside and not ahead.** `00` is months of work and the libraries do not wait
on all of it. They wait on two items, which are named and pulled ahead; the rest lands on its own
order, and a library front that meets a missing compiler feature files a row in `language-gaps.md`
pointing at the `00` item that owns it, and works around it.

## What this milestone delivers, in the order the plan gave it

1. **The base and `std` (blocking).** The old `onze` mocking library is retired and 100 % of its
   assertions live in `libs/std/src/asserts.bp`; `onze13` is renamed `onze`; `import {asserts} from
   "std"` has at least the ten functions named above; `@src()` exists; snapshots have one engine and
   one path rule.
2. **Modules and submodules (structural).** Every library is `modules/**` (core, `<lib>-test`, the
   domain submodules its `modules.md` argues for) and `examples/**` (runnable `.bp` projects). The
   granularity is decided per library against its reference — Spring Boot 4 for rakun, Next.js for
   jhonstart and onze, Tailwind CSS v4 for emilia — and recorded with keep/merge/split/drop verdicts.
3. **Examples and validation.** `01-std/examples/` holds the two examples the plan asked for
   (asserts alone; a `-test` submodule exposing custom helpers over std). Each library's
   `test-snap.md` and `test-snap-examples.md` map, front by front, the snapshot tests to write —
   `.bp` with `@src()` and `\\` line strings — and the exact `.snap` each one produces.

## Rules carried forward

- **The most restrictive behaviour, and no configuration that bypasses it** (1.0.5 decision 67).
  A snapshot mismatch fails; nothing updates it but a person renaming the `.new` file. An unresolved
  import fails `check` and `build`. There is no flag.
- **The libraries split by concern** (decision 113): emilia is CSS, jhonstart is HTML, rakun is the
  service on erlang, onze wires them. jhonstart and rakun never import each other; emilia imports
  nobody and enters jhonstart through the `jhonstart-emilia` bridge; onze is the one package that
  imports jhonstart, rakun and the bridge together.
- **The compiler knows none of the libraries** (1.0.9). Only `00-compiler-carry-over` touches
  `repository/botopink-lang/modules/**`; `01-std` has two named carve-outs — `@src()`, and the
  bundled-package registry that makes `from "routing"` resolve like `from "std"`
  (`01-std/04-routing-lib`, decision 115), which also carries `actions` and `validation` (decision
  116). A bundled library is neutral like std: rakun and jhonstart both import it, and that is not
  an edge between them. It ships `.bp` files only — target-native code is an inline `#[@External]`
  template, never a `.erl` / `.mjs` sidecar (decision 117).
- **A page signal is jhonstart's end to end** (decision 117). jhonstart's render writes to a generic
  `Response` and turns its own `notFound` / `redirect` into the 404 / 307, or into late-signal markup
  after the first chunk; a client-only app (`clientApp`) handles them in the browser. onze only
  adapts rakun's response; rakun keeps `redirect` for server actions. Pages, layouts and templates
  are `fn … -> @Component<ElementBase, Element>` (decisions 117, 118 and 128).
- **The return type is the annotation** (decisions 118–128). A function gains `throw` / `try`,
  `await`, `use` or `yield` by writing `@Result`, `@Task`, `@Component<C, T>`, `@Iterator` or
  `@Stream` as its return; only `@Result` fails; there are no effect annotations and no
  compatibility window. The library fronts' examples are written in this spelling (`00 · 24-effects-by-return` step E8);
  the libraries' own sources move with its step E7.
- **One repo per front; target is assigned, not chosen; reuse std; additive only** — 1.0.9's rules,
  carried in `fronts.md` with their named exceptions.
- **Examples are code, not prose.** Every front carries `examples/*.bp` that compile against the
  syntax that exists today; a needed-but-missing syntax is a `// LANGUAGE GAP:` line and a row in
  `language-gaps.md`, never an invention.
- **A snapshot is evidence, not a baseline; the gate runs from a cold runtime cache; a backend
  builds a model and an emitter renders it** — 1.0.5's rules, still binding on `00`.
- **`status.md` is the only file that carries status.** Every other spec describes current state and
  remaining work; when a front lands its README becomes the record of what shipped and what it left.
