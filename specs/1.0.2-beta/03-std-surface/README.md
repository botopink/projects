# Front 03 — std surface

**Priority:** critical — `libs/std` does not compile, so nothing that imports it can be trusted,
and its 22 `./gleam_stdlib.mjs` annotations put a `require` of a file that does not exist inside
`String.prototype.slice`
**Depends on:** nothing, but it **runs alone** — `libs/std` is embedded in the global environment,
so a signature change here re-records commonJS, erlang, beam and wasm at once
**Owns:** `libs/std/**` (source, `botopink.json`, `AGENTS.md`, `test/`) · no snapshot directory of
its own, but it moves **all four**
**Does not touch:** `codegen/**` and `comptime/**` — except the two single-site compiler fixes
carved out in [Ownership](#ownership) below, both of which belong to files other fronts own
(`comptime/infer.zig:6901`, the import emitter in `codegen/commonJS.zig`)

---

## Problem

`botopink check` inside `libs/std` stops on the first error and never reaches the tests:

```
warning: module not reached by any `mod` path — not compiled: src/types.bp
warning: module not reached by any `mod` path — not compiled: src/reflect.bp
warning: module not reached by any `mod` path — not compiled: src/primitives.bp
  Checking 24 module(s)...
error: pick expects a type and field names at random:141:13
```

The error is not about `random.bp`. A compiler intercept for type-manipulation builtins claims the
bare name `pick` before any module can declare it, so `libs/std`'s own
`pub fn pick<T>(xs: Array<T>) -> ?T` is unreachable — and with it the other 23 modules.

Behind that, the std declares 22 externals pointing at `./gleam_stdlib.mjs`, a file that exists in
no repository and in no commit. Four of the 22 sit behind `default fn slice`, so the emitter
patches `String.prototype.slice` and `Array.prototype.slice` with a body that throws.

## Current state

`src/root.bp:13-35` declares 23 `pub mod`; `src/` holds 26 `.bp` plus `sidecars/random.mjs`. The
three warned modules are 1147 lines (`primitives.bp` 1019, `types.bp` 79, `reflect.bp` 49).

Six defects, measured against a compiler built from HEAD. **6a is the only one that blocks the
rest** — with `random.bp`'s `pick` renamed in a scratch copy, the 23-module tree checks clean in
113 ms and `botopink test` reaches 131 tests:

| | before 6a | after 6a alone |
|---|---|---|
| `botopink check` | fails at `random:141:13` | clean, 24 modules |
| `botopink test` | not reached | 131 discovered · 113 pass · 18 fail · exit 1 |
| modules that crash before their first test | — | `env`, `os`, `process`, `random` (4) |
| failing assertions | — | 18, **all** `Cannot find module './gleam_stdlib.mjs'` |

The codegen-hardening rows this front also carries were measured by extracting each backend's
emitted code from its snapshot and running it outside the suite (`node --check` then `node main.js`
for commonJS; `erlc` then `erl -noshell` inside a `try … catch` for erlang; `erlc +from_asm` for
beam; `wasmtime run` for wasm). C1 closes **9** commonJS fixtures, E3 **1** erlang fixture.

## Mechanism

Two deep dives:

- [`blockers.md`](./blockers.md) — 6a, the type-manipulation intercept, and 6d, the four modules
  whose emitted JavaScript does not parse. These are what stand between the front and any
  measurement of the rest.
- [`node-externals.md`](./node-externals.md) — the `./gleam_stdlib.mjs` table: which of the 22
  declarations are inert, which 4 actually break, why the `default fn` prototype patch replaces a
  working native method with one that throws, and the shipping decision.
- [`external-annotations.md`](./external-annotations.md) — every `#[@External.<Target>(…)]` form, its traps, per-target coverage of `primitives.bp`, and the rule per situation for rewriting `libs/std`.

The remaining four defects — the manifest, the two unreachable modules, the 67 unreachable tests
and the OTP function that never existed — are in [`surface.md`](./surface.md).

## Ownership

Two of the seven steps have their fix **outside `libs/std`**, in a file another front owns. Both
are single call sites, and in both cases the owning front runs at a different time, so the
recommendation is a named carve-out rather than a sequencing dependency:

| Step | Fix site | Owner in [`../fronts.md`](../fronts.md) | Recommendation |
|---|---|---|---|
| 1 (6a) | `comptime/infer.zig:6901` — one guard on one call | [`../07-checker/`](../07-checker/README.md) | Carve it out to this front. Both fronts run alone, so they cannot overlap; the checker front must not touch `:6901` in the same milestone without reading this step |
| 2 (6c, helper half) | a JS helper prelude under `codegen/js/**` plus its request site in `codegen/commonJS.zig` | [`../08-js-bridges/`](../08-js-bridges/README.md) | Route it to the JS front. The annotations in `libs/std` name the helpers; the mechanism that emits them is the JS front's, and it is the third instance of a pattern the other three backends already have |
| 3 (6d) | the import emitter in `codegen/commonJS.zig` | [`../08-js-bridges/`](../08-js-bridges/README.md) | Route it to the JS front, or carve it out — this front cannot run `env`/`os`/`process`/`random` tests until it lands, and it is the same defect spec 06 report `codegen-comptime-misc` records as "dangling import for template-only symbols" |

Everything else is `libs/std` source only. The two steps routed to the JS front are the front's only
sequencing dependency: the annotations can land first and the helper-backed ones stay red until the
mechanism exists, or the mechanism lands first and this front re-records once.

## Steps

Fix in this order: 1 first (nothing is measurable before it), then 2, which is what the 18 red
tests are waiting for.

### Step 1 — Free the five type-manipulation names (6a)

Guard `comptime/infer.zig:6901` with `env.lookup(call.callee) == null` (and `call.receiver == null`),
so a user declaration of `pick` / `omit` / `partial` / `mergeRecords` / `mapFields` wins over the
builtin intercept. The correct pattern is eleven lines below in the `result` namespace
(`infer.zig:6911`, repeated at `:6919`). `pick` is documented public std surface
(`libs/std/AGENTS.md:47`), so renaming it is an API break, not a fix. Full mechanism in
[`blockers.md`](./blockers.md#6a--the-comptime-type-manipulation-intercept-claims-pick-before-any-module-can).

**Acceptance:**
- [ ] A module that declares `pick`/`omit`/`partial`/`mergeRecords`/`mapFields` calls its own
- [ ] `mergeRecords(A, B)`, `partial(T)`, `omit(T, n)`, `pick(T, ns)` still resolve where no user
      declaration shadows them (they do today with no `.bp` declaration anywhere)
- [ ] `botopink check` in `libs/std` is clean
- [ ] A regression test declares a `pick` and asserts its own body runs

### Step 2 — Remove the `./gleam_stdlib.mjs` dependency (6c · 03 row C1)

**The decision is taken and it is not negotiable by this step:** `gleam_stdlib.mjs` is the *Gleam
language's* runtime. The symbols are Gleam's — `string_length`, `starts_with`, `trim_start` — and
`libs/std/src/order.bp:1` admits the borrowing ("inspired by `gleam/order`"). Shipping it would make
botopink depend on another language's ABI for `slice`. **The dependency is removed, not satisfied.**

Per declaration, in this order of preference:

1. **The native JS method**, where its semantics already match the signature — an inline
   `@External.Node` template, zero runtime, zero load. This is what the 18 inert declarations do by
   accident today, so it is also their smallest change.
2. **A compiler-owned helper, emitted on demand**, where no native method matches. Not every
   primitive has a native method with the right semantics, so a botopink-owned JS helper set is
   expected — but **not as a module that always loads**: `require("./botopink_stdlib.mjs")` would
   pull the whole file in at the first call. The rule is **only the function actually used is
   emitted**, written into the generated module at the call site's request.

The mechanism exists three times already — `codegen/wat/wat_prelude.zig`'s `Builder.helper`,
`beam_asm.zig`'s `ensureStringifyHelper`/`ensureIndexOfHelper`/`ensureAtHelper`, `erlang.zig`'s
`comptime_helper_forms`. commonJS is the only backend without one, which is why it reached for
someone else's runtime file. Copy the WAT shape: requesting a helper and marking it for emission is
a *single operation*, so "called" and "defined" cannot diverge.

The helper set starts at the four declarations that break today (`stringSlice0/1`, `arraySlice0/1`)
plus `String.charAt`, whose JS semantics already differ from its signature; the other 18 are audited
for the cases where JS is lenient and the signature is not (negative indices, an empty separator,
what `trim` strips, `indexOf` returning `-1` against a `?i32`). The full table of the 22, where the
helper source lives, the rejected alternatives and the six snapshots that pin the broken `require`
are in [`node-externals.md`](./node-externals.md).

**Acceptance:**
- [ ] No declaration in `libs/std` names a file that is not shipped, and no emitted module contains
      `require("./gleam_stdlib.mjs")`
- [ ] **A program that calls one helper emits one helper and no `require`** — asserted by a codegen
      test that greps the emitted module for the helpers it did *not* call
- [ ] Requesting a helper and marking it for emission is a single operation, as in
      `codegen/wat/wat_prelude.zig`
- [ ] Every one of the 22 declarations is recorded as either an inline native template or a named
      helper, with the reason
- [ ] `libs/std`'s 18 `./gleam_stdlib.mjs` test failures are green
- [ ] The six commonJS snapshots that pin the `require` are re-recorded with a non-empty RUN LOG
- [ ] The 9 commonJS fixtures C1 closes print the value the program means
- [ ] `libs/std/AGENTS.md` states what a 3-arg `@External.Node` with a relative module actually
      does on an interface method versus on a `declare fn`

### Step 3 — Stop emitting an import for a template-only symbol (6d)

`env`, `os`, `process` and `random` abort with a Node `SyntaxError` before their first test: a
template-form `@External.Node` on an imported `declare fn` is lowered as a destructuring import
whose *key* is the template, with an empty module specifier. 31 tests are lost this way. The four
emitted lines and the counts are in
[`blockers.md`](./blockers.md#6d--four-std-modules-emit-javascript-that-does-not-parse). Fix in the
compiler —
`commonJS.zig` must not emit an import binding for a symbol whose `@External.Node` is a template or
a 1-arg native name; those render at the call site.

**Acceptance:**
- [ ] `env`, `os`, `process` and `random` run their tests
- [ ] A `declare fn` whose `@External.Node` is a template or 1-arg form emits no `require(…)`
- [ ] A codegen test covers each of the two shapes

### Step 4 — Replace `string:suffix/2`, which OTP does not have (03 row E3)

`primitives.bp:143-144` names a function that never existed in OTP. See
[`surface.md`](./surface.md#e3--stringsuffix2-is-not-an-otp-function).

**Acceptance:**
- [ ] `endswith_lowers_via_external_beam_single_line_body` runs on erlang and beam and prints `true`
- [ ] No `@External.Erlang` / `@External.Beam` in `libs/std` names a function `erl` answers `undef` to

### Step 5 — Make `botopink.json` `files` resolve (6b · spec-05 item 5.3)

Set `files` to the three real core files or drop the key. See
[`surface.md`](./surface.md#6b--botopinkjson-files-names-three-files-that-do-not-exist). The
diagnostic half (`libs.zig:302` should name the missing path) is a CLI change and belongs to
[`../02-cli-gate/`](../02-cli-gate/README.md); this front owns the manifest.

**Acceptance:**
- [ ] Every entry of every `botopink.json` `files` in the workspace resolves
- [ ] A missing `files` entry produces a located diagnostic, not a bare error name

### Step 6 — Decide `reflect.bp` and `types.bp` (6e · spec-05 item 5.1)

1129 lines reachable by nothing, re-implementing four functions that already exist in Zig and a
fifth (`mapFields`) that exists nowhere. Recommended: delete both. Evidence, and why each file fails
on its own, in [`surface.md`](./surface.md#6e--reflectbp-and-typesbp).

**Acceptance:**
- [ ] `reflect.bp` and `types.bp` are deleted, or declared in `root.bp` with tests that run
- [ ] `libs/std/AGENTS.md:27-29` matches the outcome
- [ ] `mapFields` either works or is documented as not existing

### Step 7 — Make `primitives.bp`'s 67 tests reachable (6f · spec-05 item 5.2)

Move them to `libs/std/test/primitives_test.bp`, or add a compiler-core test that compiles
`primitives.bp` in test mode. `pub mod primitives;` is **not** the fix — it would declare the
primitive interfaces twice. See [`surface.md`](./surface.md#6f--primitivesbps-67-tests-are-unreachable).

**Acceptance:**
- [ ] The 67 tests run on commonJS and erlang, with their failures registered by name
- [ ] `primitives.bp` is in exactly one of `std_core_files` / `std_pkg_files`
- [ ] A module in `libs/std/src/` that no `mod` path reaches fails the gate

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] `botopink check` and `botopink test` clean in `libs/std`, with every remaining failure
      registered by name in the front that owns it
- [ ] Every re-recorded snapshot was re-recorded from a value produced by **running** the program,
      not from the new text
- [ ] `libs/std/AGENTS.md` updated in the same commit
- [ ] Commit on `fix/std-surface`; no push, no merge

## Blast radius

`libs/std` is embedded in the global environment, so any signature change re-records commonJS,
erlang, beam and wasm at once — this is why the front runs alone and why no backend front may edit
`libs/std/src/primitives.bp`. It is the one file all four backends need: C1 and E3 are this front's,
and the beam row B4 and the wasm row W1 both reach into the same annotations from the backend side.

Concretely:
- Six commonJS snapshots pin the `require("./gleam_stdlib.mjs")` as expected output
  (`string_methods_map_to_native_js_names`, `string_slice_copies_bytes_into_a_new_buffer`,
  `array_slice_2_arg_lowers_byte_identically_across_backends`, `array_instance_default_fn_methods`,
  `option_method_on_tuple_element`, `array_zip_via_external_node_template`), four of them with an
  empty RUN LOG.
- 18 `libs/std` assertions, 2 of erika's 18 fluent tests and the jhonstart/onze paths recorded in
  [`../01-comptime-dispatch/README.md`](../01-comptime-dispatch/README.md) go green on step 2.
- Step 7 will surface new failures — one is known (`primitives.bp:473`, a let-generalisation gap,
  see `surface.md`); the rest must be registered by name rather than fixed here.
- Step 6, if it deletes the two files, removes the only `.bp` sources for `partial`/`omit`/`pick`;
  the Zig intercept becomes the sole definition, which is a statement
  [`../07-checker/`](../07-checker/README.md) has to agree with before it lands a std-type-functions
  step.

## Notes

- **The two carve-outs are the risk in this front**, not the `libs/std` edits. Both are named in
  [Ownership](#ownership); a worker who finds a third one stops and reports it.
- The `./stdlib.mjs` named by `external_import_binds_symbol` is a second phantom companion of the
  same family; it is a fixture, not std source, and belongs to the commonJS row.
- 6a closes two spec-06 review rows at once: report `codegen-comptime-misc`'s "`pick`/`omit`/
  `partial`/`mergeRecords` builtin intercept shadowing user fns" and report
  `codegen-wat-narrowing`'s "user `pick` vs the builtin". Coordinate the close with
  [`../09-review-tooling/`](../09-review-tooling/README.md) so the rows are not re-opened.
- The hygiene front tracks the same file pair (6e), the same manifest (6b) and the same test move
  (6f) from the prose side — see [`../11-hygiene/std-declarations.md`](../11-hygiene/std-declarations.md).
  This front owns the code; that one owns the names and the `AGENTS.md` trees.
