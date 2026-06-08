# v0.beta.6 — working notes

This set is **completion work** across two strands: the v0.beta.4 carryover
(finish stdlib backends + dispatch + editor tooling) and the v0.beta.5
application-framework completion (cross-module codegen parity, rakun's
container/web/bootstrap, jhonstart's language gaps). Notes grouped per spec.

## stdlib-backends-and-tooling (carryover)

The JS path of the stdlib-interface migration is done (v0.beta.4); this spec is
the remainder — Part A: erlang/beam/wasm method lowering + dispatch stragglers
(`s.contains()`, `Array.range`, record-method bodies, companion modules) +
inference correctness (`default fn` bodies, literal receivers); Part B: the
backend-parity F1–F6 still open from v0.beta.3; Part C: editor-experience F0–F5
(semantic tokens, inlay hints, VS Code task/test integration). Authored by the
parallel carryover work; see its spec for the full breakdown.

## cross-module-codegen

### Why now
The rakun foundation made a library ship **concrete, emitted types** that a
consumer imports — a pattern the codegen never exercised before (the "std"
package only exported *functions* via qualified namespace, never constructed a
record across the module boundary). commonJS was fixed in the rakun work:

- a `CrossModule` index (built over every module in `codegenEmit`) resolves a
  `from "<pkg>"`/multi-module import to `require("./<path>.js")` of the file that
  emits each name; declaration-only names (decorators) emit no `require`;
- imported records are marked classes so construction emits `new`;
- a record's no-`self` associated fn emits as a `static` class method;
- `exports.X` is emitted only for `pub` types another module imports.

erlang got the **in-module** half (a local record's associated fn calls the bare
local fn, not a remote `response:ok`). The remaining work is the cross-*package*
half on erlang + the whole thing on beam/wasm.

### Open points
- wasm linking may stay single-module — if so, record the limit, don't fake it.
- Consider lifting `CrossModule` to a shared analysis if the four emitters
  duplicate it.

## rakun-ioc-web

### Why now
The markers resolve but mean nothing yet. F2 (the comptime component scan + DI
graph) is the heart of Spring-in-botopink; F3 (annotation arg validation) and F4
(router) are the surface around it. All comptime — reuses the `expr-templates`
scan machinery, no runtime reflection.

### Design decisions
- A record field whose type is a known component ⇒ a DI edge. Topo-sort; a cycle
  is a scoped diagnostic, not a crash.
- Singleton scope only; constructor injection only (immutable-first).
- `#[bean]`/`#[configuration]`/`#[value]` extend the graph (factory + property
  contributions) without changing the resolution model.

## rakun-bootstrap

### Why now
`Rakun.run` is the one leg that needs a **real** HTTP server (`libs/server`,
today a scaffold). Gated on `rakun-ioc-web` (it boots the scan/graph/router).
Keep `libs/server` minimal — one backend (node) first, then erlang.

### Open points
- The `Request` boundary interface gets its concrete, server-supplied impl here.
- Decide the imported-lib lowering for `Rakun.run` (driven by the import, never
  prelude-embedded).

## jhonstart-language-gaps

### Why now
jhonstart is a *consumer* held to "no new compiler features" — so anything it
can't express is, by definition, a language spec. The four gaps (G1 fn-typed
record fields, G2 anonymous record types, G3 `fn() -> T[]`, G4 `Children`
coercion) were verified empirically on `task/jhonstart` and block the idiomatic
hook (`{value, set}`) + `html`/builder (`div { [a, b] }`) APIs.

### Open points
- Each gap is independently shippable; split into separate task branches if
  parallelism helps. Kept as one spec because they share the goal + the files.
- jhonstart F4–F5 (SSR/loaders) remain gated on `use-await-prefix` +
  `async-generators` (`tasks/v0.beta.1/`), not this set.
