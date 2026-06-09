# v0.beta.7 — the lib-agnostic core

> A set with **one focus**: make `modules/compiler-core/src/**` know zero
> non-std libraries, and give a library enough to *define and act* on its own
> constructs purely in `.bp`. See [`../AGENTS.md`](../AGENTS.md) for the rules
> (3-layer model, slug, workflow). Live progress → [`status.md`](status.md).

## Context — where v0.beta.6 left off

v0.beta.6 landed the generic work (cross-module codegen parity, the jhonstart
**language** gaps, `implement`/`mutual-recursion` completeness, `erika` + a
data-driven std registry, editor tooling) and **surfaced the real problem**: the
v0.beta.5 frameworks coupled to the compiler. rakun's interim foundation
hard-codes `rakun` in the core; a jhonstart-named test sits in the compiler. This
set removes that coupling and ships the generic mechanism that replaces it. The
pending specs `annotation-processors` and `rakun` were **advanced here** from
v0.beta.6; the rest of v0.beta.6 froze as history.

## The principle (Eric, 2026-06-08/09)

- **The core provides a mechanism; the lib defines *and* acts.** The core exposes
  only a generic protocol; a library uses it to **define** its constructs
  (decorator markers, the types they apply to) **and to act** on them (validate,
  wire DI/router, emit code) — all in `.bp`. The core never learns what a marker
  means.
- **`std` may be coupled; other libs may not.** The standard library is the one
  allowed exception (embedded prelude, core may name its primitives/modules).
  Every other lib under `libs/<name>/` (rakun, jhonstart, future frameworks) must
  be a pure client of the generic mechanism.
- **Enforced gate:** `grep -riE "rakun|jhonstart" modules/compiler-core/src`
  returns nothing (std exempt) — shipped as a test, not a one-off check.

## Features (v0.beta.7)

Three specs. Only **what can be touched in parallel is a separate spec**: the
whole compiler-core de-coupling is one indivisible strand; the lib port and the
backend parity are the two that parallelize.

| Spec | Slug | Depends on |
|---|---|---|
| [annotation-processors — decorators as custom comptime fns; de-lib the core](specs/annotation-processors.md) | `annotation-processors` | comptime eval + expr-templates |
| [rakun — DI container + router + bootstrap, **on annotation-processors**](specs/rakun.md) | `rakun` | [`annotation-processors`](specs/annotation-processors.md) |
| [stdlib-backends-parity — finish non-JS backends + dispatch + inference](specs/stdlib-backends-parity.md) | `stdlib-backends-parity` | nothing |

## DAG (the one real edge)

```text
annotation-processors  ──(needs the mechanism)──►  rakun
        │  (compiler-core: generic protocol + @Decl reflection + generic loader;
        │   removes the rakun foundation, validateRakun*, and the jhonstart-named
        │   tests/comments; ships the lib-agnostic gate — one indivisible branch)
        ▼
rakun                  (libs/rakun/*.bp + libs/server: DI/router/bootstrap, all
                        lib-side decorator bodies — F2 IoC · F3 args · F4 router
                        · F5 Rakun.run over a real HTTP backing)

stdlib-backends-parity (independent — codegen erlang/beam/wasm + dispatch +
                        inference; parallel-safe with the above)
```

## Scope boundaries

- **annotation-processors is not divisible.** The generic mechanism *and* the
  removal of every non-std lib footprint (rakun foundation, `validateRakun*`, the
  jhonstart tests/comments) all touch `comptime/*` and the shared gate — one
  branch, sequential phases P0–P3. Splitting it would only create collisions.
- **rakun** waits on the mechanism, then implements all semantics in `.bp`
  (constructor injection, singleton scope; F5 needs a real `libs/server`, node
  first then erlang). No new core code.
- **stdlib-backends-parity** is the v0.beta.6 `stdlib-backends-and-tooling`
  remainder (Part A1/A2-rest/A3 + Part B F1–F6). Stdlib coupling in the core is
  allowed — this spec de-couples nothing; it is pure backend/inference parity.
- **Library tests live in the library's own `.bp` files** (`botopink test`), never
  in the compiler's Zig suites — this set *removes* the last violation of that.
