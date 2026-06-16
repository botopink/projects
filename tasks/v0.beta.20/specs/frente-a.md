# frente-a — compiler-core close (closes v0.beta.19 §A7/§B/§C/§D2-D5/§G2) + enum-sections

**Slug**: frente-a
**Depends on**: v0.beta.19 `frente-a-compiler` partial close (`fe2b7e3` — §S/§U/§A6/§D1/§G1/§G3 done); v0.beta.20 `prim-op` §A2 (BEAM template dispatch) for §A7 alignment.
**Files**: see each sub-spec below — `comptime/{infer,unify,types,transform}.zig` · `codegen/{erlang,beam_asm,wat}.zig` · `libs/std/src/{order,sets,dict,queue}.bp` · `libs/erika/src/erika.bp` · new wat encoder + aggregate module · cross-backend snapshots.
**Touches docs**: `modules/compiler-core/src/{parser,comptime,codegen}/AGENTS.md` · `libs/{std,erika}/AGENTS.md` · `CHANGELOG.md`.
**Status**: pending — 10 sub-specs across 3 stages; no code landed yet (enum-sections fully designed but unimplemented).

## Current state (no code landed in origin/feat)

| Sub-spec | Landed | Remaining |
|---|---|---|
| **generic-inference-foundation** | — | full implementation (Self primitive kind resolution + generic var instantiation) |
| **wat-refactor** | — | full implementation (wat stack-discipline + wasm aggregates) |
| **beam-inline-prim-methods** | — | full implementation (6 array/string methods on BEAM ASM) |
| **erika-runtime-string** | — | full implementation (§G2 runtime template form) |
| **future-runtime-erlang-beam** | — | full implementation (`#[@future]` spawn-and-await on erlang+beam) |
| **enum-sections** | design + spec text complete (incl. multi-level nesting + numeric variants — section embedded in this file from emilia design discussion) | implementation (parser/decls.zig + ast.zig section/path AST + comptime resolution + desugar) |
| **primitive-interface-default-fns** | — | full implementation (depends on generic-inference-foundation) |
| **typed-method-dispatch** | — | full implementation (depends on generic-inference-foundation) |
| **wasm-test-runner** | — | full implementation (depends on wat-refactor) |
| **closeout** | — | snapshot sweep + umbrella audit (after every above lands) |

## DAG

```
01-keystones (6, parallel)
  generic-inference-foundation (§B keystone)
  wat-refactor                 (§C)
  beam-inline-prim-methods     (§D5)
  erika-runtime-string         (§G2)
  future-runtime-erlang-beam   (§D4)
  enum-sections                (net-new language extension; emilia consumer)

02-consumers (3, parallel; each picks its 01 dep)
  primitive-interface-default-fns  ← generic-inference-foundation
  typed-method-dispatch            ← generic-inference-foundation
  wasm-test-runner                 ← wat-refactor

03-closeout (1, after all above)
  closeout (combines snapshot sweep + umbrella audit)
```

---


---

## generic-inference-foundation — Self primitive kind resolution + generic var instantiation

**Slug**: generic-inference-foundation
**Depends on**: nothing in v0.beta.20 — file-disjoint with every other
  v0.beta.20 spec at the source level.
**Files**: `modules/compiler-core/src/comptime/{infer,unify,types}.zig`
  · `libs/std/src/{order,sets,dict,queue}.bp` (re-fold external inline
  tests) · `libs/std/AGENTS.md` · new
  `modules/compiler-core/src/comptime/tests/inference.zig`
**Touches docs**: `libs/std/AGENTS.md` ·
  `modules/compiler-core/src/comptime/AGENTS.md`
**Status**: pending

### Background

`instance_lowering` in `comptime/infer.zig` is the bridge between
inference's typed tree and codegen's per-backend emitter. When `Self`
inside a primitive interface `default fn` body can't be resolved to
the call-site receiver's primitive kind, the body's nested method
calls (`self.slice(…)`, `self.forEach(…)`) never get tagged with
`instance_lowerings[loc] = .prim{<kind>}` — so codegen falls through
to bare local calls that resolve to nothing on erlang/beam.

This is the keystone deferred from v0.beta.19's frente-a-compiler
§B1+B2+B5. It unblocks the companion
`primitive-interface-default-fns` spec (which emits the default fn
bodies as local mangled fns on erlang/beam) AND the
`typed-method-dispatch` spec (which tags local-record method calls
with `.record{TypeName}` via the same dispatch infrastructure).

Memory `project_generic_inference_gap` recorded this gap originally
in v0.beta.3 planning; v0.beta.19 surfaced four lib-test reds
(erika/jhonstart/onze/rakun on erlang) blocked on this fix.

### Checklist

- [ ] **F1** — Resolve `Self`'s primitive kind inside an interface
      `default fn` body. In `comptime/infer.zig` `instance_lowering`,
      when the enclosing interface is a primitive (Array/string/
      numeric/Bool — known via `primitiveInterfaceName`), substitute
      `Self`'s kind from the call-site receiver before re-typing the
      body. Records the resolved kind in
      `instance_lowerings[<callsite-loc>] = .prim{<kind>}` so every
      codegen consumer (`emitPrimMethod` on erlang/beam, the
      prototype patcher on commonJS, the wat layout pass) sees the
      tag.
- [ ] **F2** — Instantiate callee generic vars before `unifyAt` so a
      generic inline `test { … }` re-uses the module's `<T>` for the
      test's local bindings. Then fold the externalised `*_test.bp`
      shadow files back to inline `test` blocks inside `order.bp` /
      `sets.bp` / `dict.bp` / `queue.bp`.
- [ ] **F3** — Drop the generic-module inline-test caveat in
      `libs/std/AGENTS.md`; add inference unit tests for F1/F2 in a
      new file `modules/compiler-core/src/comptime/tests/inference.zig`.
- [ ] **F4** — Update `modules/compiler-core/src/comptime/AGENTS.md`
      to document the `instance_lowerings` `.prim` variant and the
      Self-resolution pass.

### Test scenarios

```
F1   ---- erika Array.drop default fn body typechecks under inference;
          commonJS still green; the dump for `xs.drop(n)` shows
          `instance_lowerings[loc] = .prim{.array}`.
F2   ---- order/sets/dict/queue inline `test { … }` blocks all green
          on commonJS+erlang; the shadow `*_test.bp` files are deleted
          from the repo.
F3+F4 -- comptime/tests/inference.zig: every F1/F2 case lands as a
          unit test (no shell, no codegen — pure infer); AGENTS.md
          Self-resolution row authored.
```

### Notes

- **No `--no-verify`.** Every commit through pre-commit (zig build +
  test + per-lib `botopink test`).
- **SSH for git remote ops** (memory `feedback_always_ssh_git`).
- **AGENTS.md in the same commit as the code** (memory
  `feedback_agents_md_maintenance`).
- The cross-primitive-method routing inside default fn bodies (e.g.
  `drop` calls `self.slice` which itself routes via
  `prim_erlang_dispatch`) is implicit in F1 — once the receiver is
  tagged `.prim{.array}` the existing `emitPrimMethod` switch handles
  the call. The companion spec
  `primitive-interface-default-fns` covers the emission side.

---

## wat-refactor — wat stack-discipline + wasm aggregates (record field layout + `?.`)

**Slug**: wat-refactor
**Depends on**: nothing in v0.beta.20 — file-disjoint with every other
  v0.beta.20 spec.
**Files**: `modules/compiler-core/src/codegen/wat.zig` ·
  `snapshots/codegen/wat/` (new fixtures)
**Touches docs**: `modules/compiler-core/src/codegen/AGENTS.md` (the
  `wat.zig` row narrows; `(KNOWN GAP: …)` clauses are dropped)
**Status**: pending

### Background

`wat.zig` is the only backend that can't run a typical test fixture:
the emitter is untyped, void builtins underflow the stack, and named
record-field access stubs to `i32.const 0`. v0.beta.19's frente-a-
compiler §C1+C3+C4+C6 deferred this — it's a contained refactor
rather than incremental, so it warrants its own spec.

The wasm test runner (`wasm-test-runner` (in this file: `frente-a-02-wasm-test-runner`)) is a
follow-up that consumes this refactor's outputs: without the
classifier in C1, `__bp_run_tests` can't emit cleanly; without C3's
record layout, fixtures using records crash.

The wasm single-module rule (originally §C5) is **already documented**
in `codegen/AGENTS.md` `wat.zig` row + `wat.zig:153` source comment —
this spec inherits it as-is, no new note.

### Checklist

- [ ] **F1** — Per-expression "produces a value" classifier. In
      `wat.zig`, classify each AST `Expr`: `@print` / `@panic` /
      `@todo` / void-returning calls produce nothing; everything
      else produces one i32. Drop only value-producing
      statement-exprs; for a void function (`f.returnType == null`)
      the last statement is not the return, so drop its value too.
      Thread `returns_value` into `emitBody`.
- [ ] **F2** — Record field layout. Stable 4-byte slot offsets per
      declared field order (mirror beam_asm's map-by-field-name
      shape but linearised). Constructor stores at offset; `recv
      .field` / `self.field` load `base + offset`; field assign
      stores; tuple `t._N` indexes the same memory.
- [ ] **F3** — `?.` on wasm. Guards the base against null (`i32.eqz`
      → branch to `i32.const 0` else load the slot). Remove the
      JS-style short-circuit stub.
- [ ] **F4** — Snapshots. `.wat` snapshots for F2's record layout
      (constructor + multi-field read) + F3's `?.` byte sequence.
- [ ] **F5** — `codegen/AGENTS.md` `wat.zig` row: drop the loop /
      record-field / `?.` `(KNOWN GAP: …)` clauses; pin the new
      single-module + classifier rules.

### Test scenarios

```
F1 ---- a fixture calling @print (void) followed by a value-returning
        fn no longer underflows the stack; wasmtime exits 0.
F2 ---- `record R { a: i32, b: i32 } val r = R(7, 11); @print(r.b);`
        loads from slot 1 (offset 4); snapshot pinned.
F3 ---- `recv?.member` on a null base emits 0; on a non-null base
        loads the named slot; snapshot pinned.
F4 ---- `.wat` snapshots all green under wasmtime smoke.
```

### Notes

- **No `--no-verify`**; **SSH for git**; **AGENTS.md in the same
  commit** (memory `feedback_agents_md_maintenance`).
- Cross-module linking stays out of scope (the existing single-module
  rule in `wat.zig:153` is the contract — `from "<pkg>"` imports that
  resolve to a concrete symbol elsewhere still emit a
  `;; cross-module import not linked` comment).
- This spec is the gate for the wasm test runner. Schedule the two
  back-to-back in one worktree if shipping serially.

---

## beam-inline-prim-methods — 6 array/string methods on BEAM ASM

**Slug**: beam-inline-prim-methods
**Depends on**: nothing in v0.beta.20 — file-disjoint with every other
  v0.beta.20 spec.
**Files**: `modules/compiler-core/src/codegen/beam_asm.zig`
  (`emitPrimMethod` array + string arms) · snapshots under
  `modules/compiler-core/snapshots/codegen/beam/beam/`
**Touches docs**: `modules/compiler-core/src/codegen/AGENTS.md`
  `beam_asm.zig` row (the "Remaining gaps" sentence loses 6 methods)
**Status**: pending

### Background

v0.beta.19's frente-a-compiler §D5 deferred per-method because each
one needs register choreography + a `erlc +from_asm` smoke. The
erlang backend already emits these via templates in
`primitives.d.bp`; BEAM needs the equivalent bytecode shape.

The six methods + their target shapes (all already documented in the
erlang templates):

| Method | Erlang template (already in `primitives.d.bp`) | BEAM target |
|---|---|---|
| `xs.join(sep)` | `iolist_to_binary(lists:join($0, lists:map(stringify_fun, $self)))` | inline closure + `lists:map` + `lists:join` + `iolist_to_binary` |
| `xs.indexOf(item)` | recursive `__Find/2` inline fun | inline closure with recursive `call_fun` |
| `xs.at(i)` | bounds-safe `lists:nth(I+1, L)` with `undefined` fallback | `is_lt`/`is_ge` guard + `gc_bif` arithmetic + `lists:nth` |
| `xs.slice(start, end)` (2-arg) | `lists:sublist($self, ($0)+1, (($1)-($0)))` | arity-branched register layout + arithmetic |
| `s.contains(needle)` | `(binary:match($self, $0) =/= nomatch)` | `call_ext binary:match` + `is_eq` test |
| `s.startsWith(prefix)` | `(string:prefix($self, $0) =/= nomatch)` | `call_ext string:prefix` + `is_eq` test |

### Checklist

- [ ] **F1-join** — `xs.join(sep)` on BEAM: build the per-element
      stringify fun via `make_fun3` (`is_binary` / `is_integer` →
      `integer_to_binary` / `io_lib:format`); register layout
      `{x,0} = stringify-fun, {x,1} = list`, then `call_ext
      lists:map/2`, `{x,1} = sep`, `{x,0} = result`, `call_ext
      lists:join/2`, then `call_ext iolist_to_binary/1`. Snapshot
      pinned.
- [ ] **F2-indexOf** — `xs.indexOf(item)`: emit a recursive
      `__Find/2` fun (already documented in the erlang template);
      register layout `{x,0} = Item, {x,1} = List`. The closure
      uses `call_fun` for the self-recursion.
- [ ] **F3-at** — `xs.at(i)` bounds-safe: `is_lt`/`is_ge` against
      `length`, then `lists:nth/2` with `I + 1` (gc_bif on the
      arithmetic). Return `undefined` (the `@Option` absent atom)
      on out-of-range.
- [ ] **F4-slice-2** — 2-arg `xs.slice(start, end)`: extend the
      existing 1-arg `slice` arity branch with a `cc.args.len + cc
      .trailing.len == 2` case that emits `lists:sublist(L, Start+1,
      End-Start)` with the right register choreography.
- [ ] **F5-string-contains** — `s.contains(needle)`: `call_ext
      binary:match/2`, then `is_eq` against `{atom, nomatch}` →
      boolean.
- [ ] **F6-string-startsWith** — `s.startsWith(prefix)`: `call_ext
      string:prefix/2`, then `is_eq` against `{atom, nomatch}`
      negated.
- [ ] **F7-docs** — `codegen/AGENTS.md` `beam_asm.zig` row: drop
      the 6 methods from "Methods needing inline funs / arithmetic
      / structural compares (`join`, `indexOf`, `at`, `isEmpty`,
      2-arg `slice`, … `string contains/startsWith`) are not yet
      lowered on BEAM".

### Test scenarios

Each method gets a snapshot fixture compiled with `botopink build
--target beam`, then assembled with `erlc +from_asm` and run via
`erl`. The expected outputs match the erlang backend's output
byte-identical.

```
F1 ---- `[10,20,30].join(", ")` emits the iolist_to_binary∘lists:join
        shape; assembles + runs to `<<"10, 20, 30">>`.
F2 ---- `[1,2,3,4].indexOf(3)` runs to `2`; `[1,2,3].indexOf(99)`
        runs to `-1`.
F3 ---- `[10,20].at(0)` runs to `10`; `[10].at(5)` runs to
        `undefined`.
F4 ---- `[1,2,3,4,5].slice(1, 4)` runs to `[2,3,4]`.
F5 ---- `<<"hello">>.contains(<<"ell">>)` runs to `true`.
F6 ---- `<<"hello">>.startsWith(<<"he">>)` runs to `true`.
```

### Notes

- Each method ships in its own commit (one snapshot per commit so
  bisection is clean if `erlc +from_asm` regresses).
- **No `--no-verify`**; **SSH for git**; **AGENTS.md in the same
  commit**.

---

## erika-runtime-string — `var s = "select …"; erika s` runtime-string template form

**Slug**: erika-runtime-string
**Depends on**: nothing in v0.beta.20 — file-disjoint with every
  other v0.beta.20 spec.
**Files**: `modules/compiler-core/src/comptime/{template_eval,template,infer}.zig`
  · `libs/erika/AGENTS.md` "Recorded gaps" drops the G2 row
**Touches docs**: `modules/compiler-core/src/comptime/AGENTS.md`
  (new runtime-template dispatch row) · `libs/erika/AGENTS.md`
**Status**: pending

### Background

The `erika "…"` template form requires a literal at the call site
today because the comptime template body runs over a
`@Expr<string>` captured at parse time. A `var s = "select …";
erika s` form needs the compiler to recognise the call site with a
runtime `string` arg (not an `@Expr<string>`) and synthesise a
runtime path: parse the SQL string at runtime, resolve the source
collection via the comptime scope snapshot, build the runtime
query.

The mechanism is **pure generic** — no erika-specific code in core.
Any template fn that wants runtime-string mode can opt in.

v0.beta.19's frente-a-compiler §G2 deferred this; the inline
template form (§G1 `${…}` interp) shipped on `origin/feat` as
erika `0262a54` + bot-lang `bc92e01`.

### Checklist

- [ ] **F1-infer** — In `comptime/infer.zig`, when a template fn call
      receives a runtime `string` arg (not an `@Expr<string>` capture),
      synthesise a `runtime_template` dispatch: the template body
      runs at runtime over the string payload. The comptime scope
      snapshot binds named collections; the runtime form looks them
      up by name at expansion time.
- [ ] **F2-template-eval** — `comptime/template_eval.zig` ships a
      runtime bootstrapper: the same JS prelude (`text` / `parts` /
      `lookup` / `bindings` / `build` / `custom` / `fail`) but
      parameterised over a runtime string + a runtime
      scope-snapshot dict. The runtime form's `text()` returns the
      runtime string; `parts()` returns a single `Text` part (no
      holes — runtime-string mode forbids `${…}` for now,
      diagnosable with a clear error).
- [ ] **F3-erika** — Erika picks up the runtime form for free —
      `erika.bp`'s template body already iterates `q.parts()` and
      uses `q.lookup(name)`. The only check needed: a runtime hole
      via `${}` interp on a runtime string is rejected with the
      diagnostic above.
- [ ] **F4-test** — Inline tests in `repository/erika/src/erika.bp`:
      `var s = "select name from erikaCities"; erika s` returns
      the same `Array<string>` the literal form does. Compile-time
      diagnostic on `var s = "where id = ${x}"` (interp in runtime
      string).
- [ ] **F5-docs** — `comptime/AGENTS.md` gains a "runtime-template
      dispatch" row; `libs/erika/AGENTS.md` "Recorded gaps" drops
      the G2 row.

### Test scenarios

```
F4 ---- `var s = "select name from erikaCities"; erika s` returns
        the same array `erika "select name from erikaCities"` does.
F4-fail -- `erika "where id = ${x}"` (interp form) keeps working;
            `var s = "where id = ${x}"; erika s` rejects with the
            new diagnostic.
F5      -- libs/erika/AGENTS.md "Recorded gaps" no longer mentions
            the runtime-string form.
```

### Notes

- **No erika-specific code in core** — the dispatch is generic;
  every template fn benefits.
- **No `--no-verify`**; **SSH for git**; **AGENTS.md in the same
  commit**.
- The scope snapshot is shared with the comptime form — same
  `q.lookup(name)` API.

---

## future-runtime-erlang-beam — `#[@future]` spawn-and-await lowering

**Slug**: future-runtime-erlang-beam
**Depends on**: `@Future<T, E>` surface contract, already on
  `origin/feat` (v0.beta.19 frente-b §1F).
**Files**: `modules/compiler-core/src/codegen/{erlang,beam_asm}.zig`
  · runtime `.erl` companion (`Future_*` ops, sibling to other
  runtime modules) · cross-backend snapshots
**Touches docs**: `modules/compiler-core/src/codegen/AGENTS.md` ·
  `libs/std/AGENTS.md` (Future doc row narrows)
**Status**: pending

### Background

v0.beta.19's frente-a-compiler §D4 deferred per its own "scope to
follow-up if too large" clause. Erlang's `spawn/1` +
`make_ref()`-tagged message passing is the canonical idiom for
single-result futures; this spec ships that on both erlang and
beam, matching the commonJS Promise-shaped surface frente-b §1F
defined.

`@Future<T, E>` per frente-b's §1F:

```bp
pub interface Future<T, E = any> {
    fn await(self: Self) -> Result<T, E>
    fn map<R>(self: Self, transform: fn(value: T) -> R) -> Future<R, E>
    fn flatMap<R>(self: Self, transform: fn(value: T) -> Future<R, E>) -> Future<R, E>
}
```

### Checklist

- [ ] **F1-erlang** — `#[@future] fn body` lowers to:
      ```
      future(Args) ->
          Caller = self(),
          Ref = make_ref(),
          spawn(fun() -> Caller ! {Ref, body(Args)} end),
          {future, Ref}.
      ```
      `await(F)` does a selective receive on the ref:
      `receive {Ref, V} -> {ok, V} after Timeout -> {error, timeout} end`.
- [ ] **F2-beam** — Same shape at register level.
      `spawn/1` is `call_ext` to `erlang:spawn/1` with a closure
      built via `make_fun3`; the await branch is a `loop_rec` +
      `remove_message` + `is_tagged_tuple` sequence.
- [ ] **F3-map/flatMap** — `Future.map<R>(self, transform)` /
      `Future.flatMap<R>(self, transform)` lower as new futures
      chained off the await result. Same dispatch path on both
      backends (the body is pure botopink built atop spawn + await).
- [ ] **F4-snapshot** — A `#[@future] fn double(n: i32) -> i32 {
      return n * 2; }` produces a working future on erlang + beam
      under `erlc +from_asm`; the chained Future.map preserves
      semantics across the await.
- [ ] **F5-docs** — `codegen/AGENTS.md` Remaining-gaps rows drop
      `#[@future]` async/await; `libs/std/AGENTS.md` Future doc row
      gains an "erlang/beam: spawn-and-await; commonJS: Promise"
      sentence.

### Test scenarios

```
F4 ---- a fixture: `#[@future] fn double(n) -> i32 { n * 2 }; val
        r = double(21).await();` returns 21*2=42 via spawn+receive
        on erlang+beam.
F3 ---- `double(21).map({ x -> x + 1 }).await()` returns 43 (the
        map chains a new future).
```

### Notes

- Timeout default lives in a single host helper (`'Future_await'/1`
  with an `infinity` default; `'Future_await'/2` accepts an explicit
  timeout). Override via `await(self, timeout: i32)` overload — out
  of scope here, queued as known gap.
- **No `--no-verify`**; **SSH for git**; **AGENTS.md in the same
  commit**.

---

## enum-sections — nested grouping of variants inside an enum

**Slug**: enum-sections
**Depends on**: nothing — pure parser + comptime extension; codegen unchanged.
**Files**:
- `modules/compiler-core/src/parser/decls.zig` (`parseEnumBody` extension)
- `modules/compiler-core/src/ast.zig` (`EnumBody.sections: []Section` slot)
- `modules/compiler-core/src/comptime/{infer,unify,types}.zig`
  (path-access resolution `.Outer.Inner` + exhaustiveness in match)
- new `modules/compiler-core/src/comptime/tests/enum_sections.zig`
- snapshots under `modules/compiler-core/snapshots/codegen/` confirm
  byte-identical codegen vs the desugared enum-of-enum form
**Touches docs**: `modules/compiler-core/src/parser/AGENTS.md` ·
  `modules/compiler-core/src/comptime/AGENTS.md` ·
  `docs.md` (new "Enums" section)
**Status**: pending — authored during v0.beta.20 emilia design (the first
  in-tree consumer needs path-access tokens like `.Color.Red.500` and
  `.Pad.X.4`); lifted into v0.beta.20 so emilia ships with the natural
  surface from F0

### Background

Today, grouping enum variants under a category requires defining a
sibling enum per group and wrapping it in a single-payload variant:

```bp
enum TokenText { Bold, Italic, Underline, SizeXs, SizeSm, Size3xl }
enum TokenColor { Red500, Red600, Hex(string) }

enum Token {
  Text(TokenText),
  Color(TokenColor),
  Hover([Token]),
}

// usage
[.Text(.Bold), .Color(.Red500), .Color(.Hex("#abc"))]
```

Workable, but the `TokenText` / `TokenColor` sibling names are
artifacts the author doesn't want in the public surface — they exist
solely to scope the inner variants. The double-wrap (`.Text(.Bold)`)
adds visual noise vs the natural `.Text.Bold` namespace read.

The first real-world consumer is `repository/emilia` (CSS-in-bp, see
[v0.beta.20 emilia spec](ecosystem.md)), which
needs a token enum with ~10 top-level groups (`Text`, `Color`, `Pad`,
`Margin`, `Bg`, `Border`, `Layout`, `Flex`, `Effect`, modifiers
`Hover`/`Focus`/`Md`/`Lg`) and ~200 leaf variants. The double-wrap
makes `[.Text(.Bold), .Text(.Size3xl), .Color(.Red500)]` read poorly
in author code that runs dozens of these per element.

### Design

#### Surface

A new optional grouping construct inside `enum` body — **no keyword**,
the presence of `{ … }` after a PascalCase identifier (or pure digit
sequence inside a section) is the marker:

```bp
enum Token {
  Text {
    Bold, Italic, Underline,
    Size { Xs, Sm, Base, Lg, Xl, X2xl, X3xl, X4xl }   // nested section
  }

  Color {
    Red    { 100, 200, 300, 400, 500, 600, 700 }      // numeric variants
    Blue   { 100, 500, 700 }
    Gray   { 100, 500, 900 }
    Hex(string),                                       // bare variant w/ payload
  }

  Pad {
    X   { 1, 2, 4, 8, 16 }
    Y   { 1, 2, 4 }
    All { 4, 8 }
  }

  Border {
    W       { 1, 2, 4 }
    Rounded { Sm, Md, Lg, Full }
  }

  Hover([Token]),
  Focus([Token]),
  Md([Token]),
  Lg([Token]),
}
```

**Decision: no keyword.** Considered alternatives `section`, `mod`,
`ns` and rejected each — the zero-keyword form is the lightest, lets
the eye read variants and sections as the same material at different
nesting levels, and the parser disambiguation is trivial (rule below).

**Two relaxations on top of today's enum grammar:**

1. **Multi-level nesting.** Sections nest arbitrarily deep. Earlier
   draft constrained to one level; removed during emilia design —
   `Color { Red { 500 }, Blue { 500 } }` was the use case that
   demanded it.
2. **Numeric variant names — inside a section only.** Pure-digit
   tokens (`100`, `500`, `4`) are valid variant names when the
   declaration site is the body of a section. Top-level enum body
   keeps the existing rule (identifiers only). Path access reads
   them naturally: `.Color.Red.500`, `.Pad.X.4`.

#### Parser disambiguation rule

Inside an enum body (and inside any section body), after each item
the parser looks at the next token:

| After `Identifier` or `Integer` next is | Means |
|---|---|
| `{` | **Section.** Body is the section's variants. Identifier required (digits not allowed for section names). |
| `(` | **Variant with payload.** `Variant(Type)` — unchanged. (Numeric variants do not take payload.) |
| `,` or `}` | **Bare variant.** No payload — unchanged. |
| anything else | parse error |

Sections and variants may interleave freely at any level; vírgula
entre seções é opcional (a `}` que fecha a seção é separador
suficiente).

No conflict with existing syntax: today, `Identifier {` inside an
enum body is a parse error (variant payloads use `(`, not `{`).
Integer-as-name in enum body is also a parse error today. Both
additions fill holes, don't displace anything.

#### Usage

Path access with N segments — one per nesting level:

```bp
val tokens = [
  .Text.Bold,                       // 2 segments
  .Text.Size.X3xl,                  // 3 segments (Text → Size → X3xl)
  .Color.Red.500,                   // 3 segments — numeric leaf
  .Color.Hex("#abc123"),            // 2 segments — variant with payload
  .Pad.X.4,
  .Border.Rounded.Md,
  .Hover([.Text.Underline]),
]
```

Pattern match preserves the path at any depth:

```bp
match token {
  .Text.Bold       => "font-weight: bold",
  .Text.Size.X3xl  => "font-size: 1.875rem",
  .Color.Red.500   => "color: #ef4444",
  .Color.Red.600   => "color: #dc2626",
  .Color.Hex(h)    => "color: " + h,
  .Pad.X.4         => "padding-left: 1rem; padding-right: 1rem",
  .Hover(inner)    => emitHover(inner),
  _                => "",
}
```

Exhaustiveness on `match`: the compiler walks the section tree and
verifies every leaf is reached (same rule as today's enum
exhaustiveness, generalised across nesting depth).

#### Desugaring

The comptime lowers nested sections to the existing enum-of-enum form
recursively — one synthesised inner enum per section, mangled name
encoding the path:

```bp
// after desugar — what codegen sees
enum __Token__Color__Red { _100, _200, _300, _400, _500, _600, _700 }
enum __Token__Color__Blue { _100, _500, _700 }
enum __Token__Color__Gray { _100, _500, _900 }
enum __Token__Color {
  Red(__Token__Color__Red),
  Blue(__Token__Color__Blue),
  Gray(__Token__Color__Gray),
  Hex(string),
}

enum __Token__Text__Size { Xs, Sm, Base, Lg, Xl, X2xl, X3xl, X4xl }
enum __Token__Text {
  Bold, Italic, Underline,
  Size(__Token__Text__Size),
}

enum __Token__Pad__X { _1, _2, _4, _8, _16 }
enum __Token__Pad__Y { _1, _2, _4 }
enum __Token__Pad__All { _4, _8 }
enum __Token__Pad {
  X(__Token__Pad__X),
  Y(__Token__Pad__Y),
  All(__Token__Pad__All),
}

enum Token {
  Text(__Token__Text),
  Color(__Token__Color),
  Pad(__Token__Pad),
  Hover([Token]),
  Focus([Token]),
  Md([Token]),
}
```

**Numeric variants** lower to identifier form prefixed with `_`
(matching Zig's discrimination of `_500` from `500`). The path access
`.Color.Red.500` is purely surface — the desugared form uses `_500`
as the actual variant name in the synthesised enum. Codegen emits the
same shape it would for a hand-written variant `Red500`.

The synthesised enums (`__Token__Color__Red`, etc.) are NOT exported
to user code — they live in the comptime symbol table under mangled
names. The path-access in user code lowers during inference to the
wrapped form.

#### Constraints

1. **Section name collisions are errors.** Two sections with the same
   name at the same nesting level, or a section name that matches a
   sibling variant name at the same level, trip a parser diagnostic.
2. **Section names must be PascalCase identifiers.** Pure-digit names
   are reserved for variant *leaves*, not section *nodes*.
3. **Bare variants and sections coexist** at any level — same rules
   as today, no ordering required.
4. **Variants may carry payload** at any nesting level (e.g.,
   `Hex(string)` in the `Color` section). Numeric variants do not
   take payload.
5. **No upper bound on nesting depth** — the desugarer emits one
   synthesised enum per section, mangled-name-encoded by path. The
   language imposes no recommended depth limit; each consumer lib
   picks its own ergonomic cutoff (e.g., emilia uses 3 levels for
   the common case `.Color.Red.500` and goes deeper only when the
   domain demands it).

### Files

| File | Change |
|---|---|
| `parser/decls.zig` `parseEnumBody` | Recognise `section Name { Variant1, Variant2(Payload)?, … }` after the existing variant grammar; build `EnumBody.sections: []Section`. |
| `ast.zig` `EnumBody`, new `Section` | Add `sections` slot; `Section { name: []u8, variants: []EnumVariant }`. |
| `comptime/infer.zig` path resolution | `.Outer.Inner` resolves to `Token.Outer(__Token__Outer.Inner)`. `match` exhaustiveness walks sections. |
| `comptime/transform.zig` desugar | Emit synthesised inner enums during type collection. Symbol table tracks the mangled names. |
| `comptime/unify.zig` | Unification of section-payload variants with their inner enum. |
| `comptime/tests/enum_sections.zig` | New: section declaration, path access, exhaustive match, payload variant within section, collision diagnostics. |
| `snapshots/codegen/{commonJS,erlang,beam,wat}/` | Existing snapshots are unaffected; new fixture proves byte-identical codegen vs the manually-written enum-of-enum form. |

### Diagnostics

| Code | Trigger | Message |
|---|---|---|
| ES1 | Two sections with the same name at the same level | `section "<path>.<name>" declared twice in enum "<enum>"` |
| ES2 | Section name collides with a sibling variant name | `section "<path>.<name>" collides with variant "<name>" in enum "<enum>"` |
| ES3 | Section name is a pure-digit token | `section names must be PascalCase identifiers (got "<digits>")` |
| ES4 | Path access on enum without that section path (`.Foo.Bar.Baz` where the chain doesn't resolve) | `enum "<enum>" has no path "<full.path>"` |
| ES5 | `match` arm leaves a leaf unreached | `pattern not exhaustive: missing leaf "<path>" under section "<section>"` |
| ES6 | Numeric variant with payload (`100(string)`) | `numeric variants cannot carry payload` |

### Phases

| Phase | Description |
|---|---|
| F0 | Parser extension: `section` keyword + body grammar; AST slot. Snapshot 3 fixtures (one per: section-only, section + top-level variants mix, section variant with payload). |
| F1 | Comptime desugar: synthesise inner enums; populate symbol table. |
| F2 | Path access resolution `.Outer.Inner` in `infer.zig`; pattern compilation in `match`. |
| F3 | Diagnostics ES1–ES5 with span info. |
| F4 | Cross-backend snapshot: every backend emits byte-identical code vs the manually-written enum-of-enum form (gate). |
| F5 | First in-tree consumer: `repository/emilia/src/tokens.bp` rewrites its current desugared form to use `section`. Verify the existing emilia tests stay green. |
| F6 | Docs sweep: `docs.md` new "Enums > Sections" subsection, parser/comptime AGENTS.md updates. |

### Non-goals

- **No section visibility modifiers.** Sections are always public if
  the enum is public. No `pub section` / `private section`.
- **No section-level methods.** Methods on enums (interface-driven)
  are unaffected; they dispatch on the top-level enum, not on a section.
- **No section spread / import.** `... section Foo from OtherEnum`
  was considered and rejected — keeps the enum self-contained.
- **No string variants.** Numeric leaves (`100`, `500`) are
  permitted; string leaves (`"red"`, `"blue"`) are not. If a string
  taxonomy is needed, the natural form is `Hex(string)` (variant with
  payload).

### Recorded alternatives

| Alternative | Why not picked |
|---|---|
| Keyword `section` (`section Text { … }`) | Most explicit, future-proofs record-payload syntax; but adds a vocabulary word for a feature that the bare `Text { … }` form already encodes unambiguously today. |
| Keyword `mod` (`mod Text { … }`) | Reuses existing keyword (zero new vocabulary), but conflates "file/dir module" and "enum sub-group" in reader's mental model. |
| Keyword `ns` (`ns Text { … }`) | Too terse; the 5-char saving doesn't justify cryptic reads. |
| Path access `.Outer(.Inner)` instead of `.Outer.Inner` | Consistent with today's variant-payload syntax but loses the namespace read. Path form is the whole point of the spec. |
| Section as separate type (`tag Text in Token { … }` outside enum body) | Splits the source of truth (enum + its sections in different declarations). Inline form keeps "one enum, one place" invariant. |

### Goal

After enum-sections lands:

- emilia's token enum reads as `[.Text.Bold, .Color.Red500]` instead
  of `[.Text(.Bold), .Color(.Red500)]`.
- `match` arms write `.Text.Bold => …` directly; exhaustiveness on
  every section.
- Codegen is byte-identical to the manually-written enum-of-enum form
  (zero runtime cost — the desugaring is pure comptime).
- The pattern is reusable for any future "category enum" surface
  (state machines, AST node tagging, diagnostic codes).

---

## primitive-interface-default-fns — emit Array/String/Bool/numeric instance default fns on erlang + beam

**Slug**: primitive-interface-default-fns
**Depends on**: `generic-inference-foundation` (in this file: `frente-a-01-generic-inference-foundation`)
  (consumes `instance_lowerings[loc] = .prim{<kind>}` produced by F1).
**Files**: `modules/compiler-core/src/codegen/{erlang,beam_asm}.zig` ·
  new `modules/compiler-core/src/codegen/tests/primitive_interface_default_fns.zig`
  · snapshots under `modules/compiler-core/snapshots/codegen/`
**Touches docs**: `modules/compiler-core/src/codegen/AGENTS.md` (the
  erlang + beam_asm Remaining-gaps rows narrow significantly)
**Status**: pending

### Background

v0.beta.19's frente-a-compiler §B4 was deferred because its closure
requires the keystone above (Self primitive kind resolution). The
erlang + beam `emitInterface` paths today skip instance `default fn`s
(those with `self` as first param) — see `codegen/erlang.zig:3090`
"Instance default fns (with `self`) are a separate gap, not emitted
here."

Concrete user-visible symptom (`zig build test-libs --lib erika
--target erlang`):

```
.botopinkbuild/test-out/erika.erl:90:  function drop/2 undefined
.botopinkbuild/test-out/erika.erl:95:  function forEach/2 undefined
.botopinkbuild/test-out/erika.erl:249: function fold/3 undefined
```

These are calls to Array's instance `default fn`s (`drop`/`forEach`/
`fold`) inside erika's pure-bp methods. Once `Self` resolves to
Array<T> via the keystone, the bodies become emittable as plain
local fns on erlang + beam.

### Checklist

- [ ] **F1-erlang** — Extend `emitInterface` in `codegen/erlang.zig`
      to also emit instance default fns (`has_self == true`) as bare
      local functions named after the method. For methods carrying
      an `@external(erlang, …)` annotation, skip the local definition
      (the host-backed template wins via `emitPrimMethod` at the call
      site). Also walk `prelude.primitives` so the primitive
      interfaces (Array/String/Bool/numeric) join the per-module
      emission pass even though they aren't in `program.decls`.
- [ ] **F1-beam** — Mirror on `codegen/beam_asm.zig` with BEAM ASM
      label reservation (`reserveFn` for each new local) and body
      emission (`emitFn` reuses the standard expr pipeline since the
      body is pure botopink — closures, prim calls, branches, val
      bindings all already lower correctly). Validate against
      `erlc +from_asm` by reassembling every touched snapshot.
- [ ] **F2-test** — `tests/codegen/primitive_interface_default_fns.zig`:
      one fixture per backend that exercises every now-emitted method
      (Array's `drop`/`take`/`fold`/`find`/`count`/`all`/`any`/`first`/
      `rest`/`contains` on Array<i32>; String's analogues). Assert the
      emitted code + run end-to-end under node / escript / `erlc
      +from_asm; erl`.
- [ ] **F3-libs** — `zig build test-libs` flips erika / jhonstart /
      onze / rakun rows green on the erlang column. Confirm
      `zig build test-libs --target beam` (once the wasm-test-runner
      spec lands beam-test support) also green.
- [ ] **F4-docs** — `codegen/AGENTS.md` `erlang.zig` + `beam_asm.zig`
      Remaining-gaps rows drop the "instance default fns not
      emitted" entry and the "(also broken on Erlang)" qualifier on
      every method now covered.

### Test scenarios

```
F1-erlang ---- drop/2, forEach/2, fold/3 (+ the rest) emit as bare
                local fns in every consuming erlang module; bodies
                cascade through emitPrimMethod for host calls.
                Snapshots regen byte-clean.
F1-beam   ---- same set emits as BEAM ASM labels; `erlc +from_asm`
                assembles + `erl` runs the snapshot fixtures.
F3-libs   ---- the 4 lib reds (erika/jhonstart/onze/rakun) flip green
                on erlang via `zig build test-libs`.
```

### Notes

- Memory `project_stdlib_backends_parity` already pins this as the
  remaining backend-parity work for v0.beta.19+.
- **No `--no-verify`**; **SSH for git**; **AGENTS.md in the same
  commit**.
- This spec does **not** introduce new prim methods — only emits the
  existing default fn bodies. New prim methods land via
  [`prim-op-template-instance-methods`](prim-op.md).

---

## typed-method-dispatch — local-record method dispatch via mangled local fns on erlang + beam

**Slug**: typed-method-dispatch
**Depends on**: `generic-inference-foundation` (in this file: `frente-a-01-generic-inference-foundation`)
  — the inference pass tagging call-site receivers with `.record{TypeName}`
  shares infrastructure with the keystone's `.prim{kind}` tagging.
**Files**: `modules/compiler-core/src/comptime/infer.zig` (tagging) ·
  `modules/compiler-core/src/codegen/{erlang,beam_asm}.zig` (consume tag)
  · new cross-backend snapshots
**Touches docs**: `modules/compiler-core/src/codegen/AGENTS.md`
**Status**: pending

### Background

v0.beta.19's frente-a-compiler §D3 deferred typed-value method
dispatch on erlang/beam. Today, `p.parse(x)` where `p: Parser`
lowers to the bare local call `parse(P, X)` — works for LOCAL
records (the bare fn exists because `emitRecord` emits it by name)
but the call doesn't honour the record's own associated-fn mangling
convention (`'Parser_parse'`). Imported records already work via
`imported_types` mapping (emitting `<owner>:'Parser_parse'(P, X)`);
the local-record path is the gap.

### Checklist

- [ ] **F1-infer** — In `comptime/infer.zig`, when a call's receiver
      resolves to a record/struct type, record
      `instance_lowerings[<loc>] = .record{<TypeName>}`. The map and
      variant already exist (the keystone consumes `.prim`); this
      section adds the `.record` variant population for LOCAL records
      (cross-module already populated).
- [ ] **F2-erlang** — In `codegen/erlang.zig`, the call emitter's
      `.record` branch already exists at line ~2268 — extend to
      emit the mangled local `'Parser_parse'(P, X)` for LOCAL records
      (not the bare `parse(P, X)`). Cross-module path (already
      `<owner>:'Parser_parse'`) stays.
- [ ] **F3-beam** — Same on `codegen/beam_asm.zig`. The `instance
      _lowerings.get(loc).record` branch consumes the mangled name
      via `fnLabelsFor("'Parser_parse'", arity + 1)` (the receiver
      counts as the first arg).
- [ ] **F4-test** — A fixture defining `record Parser { … } fn
      parse(self, x) { … }`, then `p.parse(x)`. Snapshot pinned on
      both backends: emitted call uses the mangled form.
- [ ] **F5-docs** — `codegen/AGENTS.md` erlang + beam_asm rows: drop
      "typed-value method dispatch (`p.parse()`)" from Remaining
      gaps.

### Test scenarios

```
F4-erlang ---- `record Parser { … } parse(self, x){…}; p.parse(x)`
                emits `'Parser_parse'(P, X)` (not `parse(P, X)`).
F4-beam    ---- same fixture emits `{call, 2, {f, <label-of-Parser_parse>}}`.
F4-libs    ---- existing record-method tests stay green (no
                regression).
```

### Notes

- This spec is intentionally narrow: only local-record method
  dispatch. Cross-module record method dispatch is already correct
  via `imported_types`.
- **No `--no-verify`**; **SSH for git**; **AGENTS.md in the same
  commit**.

---

## wasm-test-runner — `botopink test --target wasm` end-to-end via wasmtime

**Slug**: wasm-test-runner
**Depends on**: [`wat-refactor`](#wat-refactor — wat stack-discipline + wasm aggregates (record field layout + ?)) — without F1's
  value-tracking classifier and F2's record layout, test fixtures
  don't run cleanly under wasm.
**Files**: `modules/compiler-cli/src/cli/test_cmd.zig` ·
  `modules/compiler-core/src/codegen/wat.zig` (test-mode `__bp_run_tests`
  entry emission) · new `snapshots/codegen/wat/` test-runner fixture
**Touches docs**: `modules/compiler-cli/AGENTS.md` ·
  `modules/compiler-core/src/codegen/AGENTS.md`
**Status**: pending

### Background

`test_cmd.zig`'s target gate currently rejects wasm
(`target != .commonJS and target != .erlang`). v0.beta.19 deferred
this — it's blocked on the wat-refactor spec because the test
runner needs the same value-tracking + aggregate machinery to emit
its own entrypoint cleanly.

Once wat-refactor lands, the runner is mechanical: the test-mode
codegen emits a `__bp_run_tests` function that walks an exported
test-fn table, and the CLI invokes `wasmtime` with stdout/stderr
piped back to the reporter (same shape commonJS/erlang use).

### Checklist

- [ ] **F1** — Test-mode codegen on wasm: `wat.zig` emits a
      `__bp_run_tests` export that iterates the module's test
      functions and prints the same `running N tests` / `ok` /
      `FAIL` lines the commonJS/erlang runners produce. Test
      functions are exported as `__bp_test_<index>` (mirroring the
      commonJS convention).
- [ ] **F2** — `test_cmd.zig`: target gate accepts `.wasm`. The
      branch dispatcher in `run()` picks the `wasmtime` runner with
      args `[".botopinkbuild/test-out/main.wasm", "--invoke",
      "__bp_run_tests"]`. The reporter parses the same `passed /
      failed` line shape.
- [ ] **F3** — End-to-end: a 1-test fixture (`test "x" { assert 1 == 1;
      }`) runs under `wasmtime` → exit 0, 1/1 pass. A failing
      assertion exits 1 with the same error shape commonJS reports.
- [ ] **F4** — `codegen/AGENTS.md` + `modules/compiler-cli/AGENTS.md`:
      drop the "wasm target not yet supported by `botopink test`"
      notes; record the new wasmtime invocation in the cli AGENTS.

### Test scenarios

```
F3 ---- `cd /tmp/wasm-test && botopink test --target wasm` on a
        1-test fixture runs under wasmtime → exit 0, "1 passed, 0
        failed" line.
F3-fail -- a `test "x" { assert false; }` exits 1 with
            `FAIL x  (assertion failed)  at <path>:<line>`.
```

### Notes

- `wasmtime` must be on `$PATH`. The harness checks for it and
  exits with a clear hint if absent (parity with the
  `escript not found` path on the erlang runner).
- **Single-module rule** carries over: cross-module test fixtures
  emit the same `;; cross-module import not linked` comment as
  the regular build, and the test runner reports the affected
  module as `(skipped — wasm single-module rule)`.
- **No `--no-verify`**; **SSH for git**; **AGENTS.md in the same
  commit**.

---

## frente-a-03-closeout — cross-backend snapshot sweep + umbrella audit

**Slug**: frente-a-03-closeout (combines `cross-backend-snapshots-sweep` + `frente-a-tail` umbrella)
**Depends on**: every other frente-a-tail sub-spec (`frente-a-01-*` keystones + `frente-a-02-*` consumers); v0.beta.19 `frente-a-compiler` partial close (`fe2b7e3`) for the §A7/§B/§C/§D3-D5/§G2 deferrals to be closed; v0.beta.20 `prim-op` `annotation-tail` (BEAM+wat user-template dispatch) for §A7 alignment — note that `prim-op` `annotation-tail` itself depends on `std-tail-followup` §A2 commonJS+erlang (already on `origin/feat` — `a7c6d07` + `52d6101`), so the landing order is `std-tail-followup §A2 (done)` → `prim-op annotation-tail BEAM+wat (pending)` → `frente-a closeout audit (this spec)`.
**Files**:
  - **Snapshot regen** (cross-backend sweep):
    - `modules/compiler-core/snapshots/codegen/{erlang,beam,wat}/` — regenerate every cross-backend snapshot affected by §D3 (typed-method-dispatch), §D4 (future-runtime-erlang-beam), §D5 (beam-inline-prim-methods); regen the §C wat fixtures touched by wat-refactor + wasm-test-runner.
    - `modules/compiler-core/src/codegen/AGENTS.md` — Remaining-gaps rows narrow to their final state.
  - **§B — generic-inference deep close**:
    - `comptime/infer.zig` (registerStdlib gap; the keystone `frente-a-01-generic-inference-foundation` authored this — closeout audits)
    - `comptime/transform.zig` (erika-LINQ red)
    - new `tests/comptime/generic_inference.zig`
  - **§C — wasm aggregates / wat refactor**:
    - `codegen/wat.zig` + `codegen/wasm/aggregate.zig` (new; refactor lands in `frente-a-01-wat-refactor`; closeout audits)
  - **§D3 — beam_asm cross-module qualified-call**:
    - `codegen/beam_asm.zig` (cross-module qualified-call lowering — dual of §D2's `fbe6b62`)
  - **§D4 — `#[@future]` lowering**:
    - `codegen/{erlang,beam_asm}.zig` (Promise-equivalent shape — lands in `frente-a-01-future-runtime-erlang-beam`; closeout audits)
  - **§G2 — erika runtime-string interpolation**:
    - `comptime/transform.zig` lowering (lands in `frente-a-01-erika-runtime-string`; closeout audits)
**Touches docs**:
  - `modules/compiler-core/src/codegen/AGENTS.md` (Remaining-gaps roll — drop §A6 row, refresh §D2 to "done upstream + §A2-twin-aware", final-state rows pin surviving gaps in one line each)
  - `modules/compiler-core/src/comptime/AGENTS.md` (generic-inference fix's caller-impact note)
  - `libs/erika/AGENTS.md` (§G2 runtime-string row)
  - `CHANGELOG.md` (per-track entries)
**Status**: pending

### Premise

The v0.beta.19 `frente-a-compiler` set landed §S (`*fn` removal), §U
(unused-builtin sweep), §A6 (annotation-driven Family 1), §D1 (print
family), §G1 (`${…}` interp), §G3 (AGENTS refresh). The status row
(`fe2b7e3`) deferred §A7 / §B / §C / §D2-D5 / §G2 with specific
reasons recorded; §D2 since landed upstream (`fbe6b62` / `c5a4ad3`).

This closeout is the **last spec in frente-a-tail** — it lands AFTER
the 9 other specs (6 keystones + 3 consumers) regenerate every
cross-backend snapshot affected, then runs the audit checklist that
proves every §A7 / §B / §C / §D3-D5 / §G2 row narrows to "done" in
`codegen/AGENTS.md` Remaining-gaps. The choice to fold the snapshot
sweep AND the umbrella audit into one closeout — instead of two
separate specs — keeps the receipt single: "frente-a-tail is done"
means the entire compiler-core close has landed AND been audited.

The non-fold-into-std-tail-followup choice is deliberate: those
tracks are deep compiler work (generic inference; wat refactor;
`#[@future]` lowering on a new backend pair) and file-disjoint with
the stdlib-driven follow-ups. Running them on their own worktree
keeps std-tail-followup's spec / test gate focused on stdlib surface.

### Checklist

The order below is the gate ordering — each check passes after the
relevant `frente-a-01-*` / `frente-a-02-*` spec lands.

#### Phase 1 — snapshot sweep (audit + regen)

- [ ] **S1-snapshots-D3** — Cross-backend snapshots for typed
      method dispatch: fixture compiled with `--target erlang` and
      `--target beam`; both emit the mangled local
      `'Parser_parse'(P, X)` form; the snapshots match byte-for-byte
      across the two backends. (lands via
      `frente-a-02-typed-method-dispatch` (this file);
      closeout audits)
- [ ] **S2-snapshots-D5** — Each of the 6 BEAM inline-fun methods
      gets its snapshot already in
      `frente-a-01-beam-inline-prim-methods` (this file);
      this closeout confirms the snapshots round-trip through
      `erlc +from_asm` and match the erlang reference.
- [ ] **S3-snapshots-D4** — `#[@future]` fixture's snapshot lands
      via `frente-a-01-future-runtime-erlang-beam` (this file);
      this sweep verifies the chained `Future.map` produces matching
      output across erlang+beam.
- [ ] **S4-negation-note** — Sweep the
      `negation_in_expression gc_bif Live count` note pinned in
      `codegen/AGENTS.md:57`. Snapshot the actual register layout
      in beam_asm + add an `erlc +from_asm` smoke that asserts the
      gc_bif Live argument matches the documented minimum.
- [ ] **S5-AGENTS-final** — Drop every row from `codegen/AGENTS.md`
      Remaining-gaps that frente-a-tail closes. Final-state rows pin
      the surviving gaps in one line each (no follow-up references —
      every prior gap either landed in v0.beta.20 or is explicitly
      scoped to a successor spec).

#### Phase 2 — umbrella audit per §-deferral

- [ ] **§A7 — BEAM bytecode-template gate (audit-only)**
  The actual wiring lands in `prim-op-02-annotation-tail`. This phase's audit:
  - [ ] Confirm `prim-op-02-annotation-tail` landed its BEAM template path.
  - [ ] Verify the §A6 "irreducible allow-list" carve-out from
        `codegen/AGENTS.md` is empty.
  - [ ] Cross-check via `git grep "mem.eql(u8, callee" modules/compiler-core/src/codegen/beam_asm.zig`
        — expect zero matches in `emitPrimMethod` (the dispatch surface).
  - [ ] Update `frente-a-compiler` spec's §A7 row in v0.beta.19 status
        to "done via prim-op-02-annotation-tail".

- [ ] **§B — generic-inference (inline tests + erika-LINQ + registerStdlib)**
  Closeout receipt — the keystone work landed in `frente-a-01-generic-inference-foundation`:
  - [ ] `comptime/infer.zig` — `registerStdlib`'s generic-instance
        gap closed. Inline tests in generic modules (pair, list,
        iterator, dict, sets, function, queue) green
        (memory `project_generic_inference_gap`).
  - [ ] `comptime/transform.zig` — erika-LINQ shape on erlang/beam:
        the `Query<T>` enumerator's `where`/`select` chain lowers via
        `tryEmitPrimAnnotation` recognising the `Query<T>` receiver as
        `.prim(.record)`.
  - [ ] `tests/comptime/generic_inference.zig` (new) — round-trip a
        generic module's inline tests on every backend.

- [ ] **§C — wasm-aggregates + wat refactor**
  Closeout receipt — the refactor landed in `frente-a-01-wat-refactor`:
  - [ ] `codegen/wasm/aggregate.zig` (new file) extracted from `wat.zig`.
  - [ ] `codegen/wat.zig` — `emitRecord` / `emitStruct` / `emitEnum`
        delegate to `aggregate.zig`. No behaviour change (snapshots
        stay byte-identical).
  - [ ] Nested record/struct/enum lowering supported. Test via
        `tests/codegen/wasm/nested_record.zig` (new).
  - [ ] Pin via per-shape snapshots.

- [ ] **§D3 — beam_asm cross-module qualified-call lowering**
  The dual of §D2 (`fbe6b62`):
  - [ ] `codegen/beam_asm.zig` — qualified-call emitter recognises
        the local-module receiver path (`from "myMod" myFn(args)` →
        `beam atom-lookup + apply`).
  - [ ] Per-call snapshots green.

- [ ] **§D4 — `#[@future]` erlang/beam lowering**
  Closeout receipt — lands in `frente-a-01-future-runtime-erlang-beam`:
  - [ ] `codegen/erlang.zig` — `#[@future]` fn bodies lower to a
        `proc` shape that returns `{ok, V}` on success or
        `{error, R}` on throw.
  - [ ] `codegen/beam_asm.zig` — mirror the lowering, register-
        allocating the result tuple.
  - [ ] `tests/codegen/future_erlang.zig` + `tests/codegen/future_beam.zig`
        round-trip green.

- [ ] **§D5 — per-target coverage matrix (close-out)**
  Docs sweep:
  - [ ] `modules/compiler-core/src/codegen/AGENTS.md` — extract the
        per-target coverage table from the STD-001 lookup output (lands
        in `std-tail-followup` P9 / P18) and pin it in the AGENTS file.

- [ ] **§G2 — erika runtime-string interpolation**
  Closeout receipt — lands in `frente-a-01-erika-runtime-string`:
  - [ ] `comptime/transform.zig` — runtime-string lowering for
        erika templates whose body is a `string`-typed expr.
  - [ ] `libs/erika/src/erika.bp` — `runtimeBody: string` carrier
        alongside the existing `compileBody: @code` path.
  - [ ] `tests/comptime/erika_runtime.zig` round-trips a runtime-
        string template across the four backends.

### Test scenarios

```
S1   `record Parser …; p.parse(x)` snapshot pinned on erlang+beam (mangled local)
S2   6 BEAM snapshots all match the erlang reference; `erlc +from_asm` round-trips
S3   `#[@future] fn …` cross-backend snapshot pinned
S4   negation_in_expression gc_bif Live count pinned in snapshot
S5   `codegen/AGENTS.md` Remaining-gaps section is final-state
§A7  zero `mem.eql` BEAM allow-list arms in beam_asm.zig `emitPrimMethod`
§B   inline tests in pair/list/iterator/dict/sets all green on commonJS+erlang
§B   erika-LINQ Query<T>.where().select() lowers on erlang+beam
§C   record A { b: B } nested record lowers on wat
§C   wat snapshots byte-identical pre- and post-refactor
§D3  qualified cross-module call from a std module emits BEAM apply
§D4  `*fn() -> i32` returns {ok, V} on erlang; throw lowers to {error, R}
§D5  STD-001 matrix matches the codegen AGENTS row by row
§G2  erika "..." with a runtime-string body emits the join shape
```

### Notes

- This spec is the **gate** for v0.beta.20's compiler-tail tracks
  shipping as a coherent set. It runs last in frente-a-tail.
- **§B is the keystone risk** — generic-inference work is deep, and
  the fixes here have to keep the existing `tests/comptime/*.zig`
  snapshots byte-identical (the `tryEmitPrimAnnotation` interface-
  method path stays untouched). If `registerStdlib`'s fix surfaces
  cross-backend snapshot churn, defer to v0.beta.21 with a clear
  carve-out.
- **§C wasm refactor** can land independently — it's purely
  organizational at the file level, no surface change.
- **§D4 `#[@future]`** crosses over with `std-tail-followup` P11
  (`time.sleep`). If P11 wants a clean shape, schedule §D4 first;
  otherwise the spec author may choose to land sleep with the §A3
  `#[@result]` shape and defer §D4 to v0.beta.21.
- **No `--no-verify`**; **SSH for git**; **AGENTS.md in the same
  commit as the code** (memory rules).

### Exit gate

- [ ] §A7 audit confirms zero `mem.eql` BEAM allow-list arms.
- [ ] §B `registerStdlib` fix lands; generic-module inline tests
      green; erika-LINQ on erlang+beam green.
- [ ] §C wat aggregate refactor lands; per-shape snapshots regen green.
- [ ] §D3 beam_asm cross-module qualified-call lowering green.
- [ ] §D4 `#[@future]` lowering green on erlang+beam.
- [ ] §D5 codegen AGENTS per-target table matches STD-001 runtime
      lookup row-by-row.
- [ ] §G2 erika runtime-string interpolation lands; new fixture
      green across the four backends.
- [ ] S1–S5 snapshot sweep complete; `codegen/AGENTS.md` Remaining-gaps
      section is final-state; zero "deferred" entries point at
      v0.beta.20 specs.
- [ ] `botopink-lib-test --lib all --target all` green.
- [ ] CHANGELOG per-track entries.
