# v0.beta.7 — working notes

One focus: **the lib-agnostic core.** The core provides a generic mechanism so a
lib can *define and act* on its own constructs without the core knowing it; `std`
is the allowed coupled exception, every other lib is a pure client.

## Why this set (from the v0.beta.6 consolidation)

Building the frameworks coupled them to the compiler (rakun hard-coded in core; a
jhonstart-named test in the compiler). v0.beta.6 merged the generic work and
froze; the pending pieces (`annotation-processors`, `rakun`) advanced here, plus
the stdlib backend remainder.

## Granularity rule applied (Eric, 2026-06-09)

> "separe em spec diferentes só aquilo que pode ser tocado em paralelo"

- **annotation-processors = one indivisible spec.** The mechanism + removing the
  rakun foundation + folding away the jhonstart tests + the gate all touch
  `comptime/*` and the same gate — not parallelizable, so not split (no separate
  "decouple" spec, no P0/P1/P2 as separate specs).
- **rakun** is separable but **sequential** (needs the mechanism) → its own spec,
  one real dependency edge.
- **erika** and **jhonstart** are the other two **pure-`.bp` client ports** of the
  same mechanism (added 2026-06-09, same direction as rakun). Each waits on the
  generic loader half of `annotation-processors`, then does **lib-side-only** work
  in `libs/erika/*.bp` / `libs/jhonstart/*.bp` — separate specs because they touch
  disjoint libs (mutually parallel once the keystone lands), each one real edge to
  `annotation-processors`. No new compiler-core code in either.
- **stdlib-backends-parity** is genuinely parallel (codegen emitters + stdlib
  regions of inference) → its own spec, `Depends on: nothing`.

## annotation-processors

The keystone. A decorator is an ordinary comptime fn whose first param is a
reflected `@Decl`; the core only provides the protocol (recognize → reflect →
invoke → apply) + a generic `from "<lib>"` loader for non-std libs. P0 de-libs the
core (delete rakun foundation + `validateRakun*`, fold the jhonstart tests into
the generic suites, ship the `grep -riE "rakun|jhonstart"` gate as a test). P1
recognition + arg validation, P2 comptime invocation + `@Decl`, P3 wiring (DI +
router as lib-side generated decls/`@Expr`). std keeps its embedded path.

## rakun

All semantics in `libs/rakun/*.bp` as lib-side decorator bodies on the mechanism:
F2 IoC container (component scan + DI graph + cycle diagnostic), F3 annotation
arg/placement validation, F4 router, F5 `Rakun.run` over a real `libs/server`
(node first, then erlang). The interim F2/F3 reference implementation is preserved
on the `task/rakun` branch (`feb96f0`) — port the *behaviour*, don't merge the
core-coupled Zig.

## erika

The v0.beta.6 LINQ lib shipped **inside `std`** only to dodge the per-lib import
machinery rakun needed. The generic loader deletes that machinery, so erika
graduates to its own `libs/erika/` package (source moves unchanged), drops out of
`std_pkg_files`, and the recorded `erika "…"`-goes-`unbound`-after-import limit
closes via the loader's **generic** template-fn binding. Re-land the v0.beta.6
deferrals (`selectMany`, multi-field projection) now that G2/G3 are in `feat`.
Loader half only — erika carries no decorators.

## jhonstart

The UI framework is already real botopink on generic primitives, but carries (1) a
coupling debt — `comptime/tests/jhonstart.zig` + jhonstart comments in `infer.zig`,
which `annotation-processors` P0 removes — and (2) a declarative debt:
`hooks/html/router/server.d.bp` were markers because G1–G4 blocked their bodies.
G1–G4 landed in `feat`, so this spec promotes that surface to real `.bp` and stands
the framework up as a **pure client** of `from "jhonstart"` once the core forgets
it. Decorators (`#[component]`) are a recorded future layer, not this spec.

## stdlib-backends-parity

v0.beta.6 `stdlib-backends-and-tooling` remainder: A1 (mirror JS method lowering
on erlang/beam/wasm; `std_erlang.sh` green), A2-rest (`@[external]` associated fns
+ companion host modules), A3 (default-fn body inference, generic-extends-generic,
literal receivers), and Part B F1–F6 (literal receivers to codegen, snake→camel,
erlang/beam std loading, `?.` codegen, wasm test runner, duplicate-test warning).
