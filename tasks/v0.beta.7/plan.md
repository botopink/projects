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

## stdlib-backends-parity

v0.beta.6 `stdlib-backends-and-tooling` remainder: A1 (mirror JS method lowering
on erlang/beam/wasm; `std_erlang.sh` green), A2-rest (`@[external]` associated fns
+ companion host modules), A3 (default-fn body inference, generic-extends-generic,
literal receivers), and Part B F1–F6 (literal receivers to codegen, snake→camel,
erlang/beam std loading, `?.` codegen, wasm test runner, duplicate-test warning).
