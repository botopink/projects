# Spec 03 — Codegen Hardening

**Version:** 1.0.1-beta
**Status:** delivered
**Carried forward:** [`../1.0.4-beta/overview.md`](../1.0.4-beta/overview.md) (1.0.2-beta was folded into 1.0.4-beta)

---

## Objective

Make the codegen snapshot suite say something true. A RUN LOG had to be the output of a
program that really ran, a module that does not compile had to be visible as such, and the
three Erlang-family / wasm backends had to emit code a real toolchain accepts.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`.

## What changed

### The RUN LOG harness — `src/codegen/runtime.zig`

- **A run is decided by the process exit status, not by the length of its output**
  (`RunStatus` ~l.67, `runCaptured` ~l.88, `isProcessSuccess`). `.ok` = exited 0,
  `.failed` = ran and exited non-zero (deterministic, so recordable and cacheable),
  `.unavailable` = missing binary / spawn error / timeout (host-dependent, never recorded,
  never cached).
  - `executeBeamAsm` used to read the *empty* output of a successful `erlc +from_asm` as a
    failure, so BEAM never executed from a cold cache; every non-empty beam RUN LOG in the
    tree existed only through the local runtime cache. BEAM now runs for real.
  - `executeErlang` used to return `""` for any `erlc` output, warnings included, blanking
    the run of a module that compiled fine.
- **A compile/assembly failure is recorded, not swallowed** (`compileFailureLog` ~l.128): the
  RUN LOG becomes `COMPILE ERROR (erlc):` / `COMPILE ERROR (erlc +from_asm):` followed by the
  diagnostics — error lines only, with `Warning:` lines and OTP's `%  7| …` source echo
  filtered so the block is stable across OTP releases. A loader-validator rejection is now a
  visible block instead of an empty log.
- **Determinism**: `erlc`/`erl` are spawned with the scratch dir as their cwd (`-o .`,
  `-pa .`, bare `<module>.erl` / `<module>.S` in argv), so diagnostics quote `main.erl:4:5:`
  and no absolute `.botopinkbuild/tmp/<hex>/` path can reach a snapshot; a crashing fixture's
  `erl_crash.dump` lands in the scratch dir that is deleted right after.
- `HARNESS_VERSION` (~l.175) is part of the cache key, so a harness that records something
  different for unchanged inputs cannot be hidden by a warm cache.

### The snapshot gate — `src/codegen/snapshot.zig`, `src/codegen/tests/helpers.zig`

- A module that never reached the backend (parse / type error) or that comptime validation
  rejected now gets a `----- COMPILE DIAGNOSTIC -- <name>` section in place of the code
  section (`buildSnapshot` ~l.72-90). It used to contribute nothing at all, so the snapshot
  compared empty with empty and the test passed.
- **A snapshot test fails when its program does not compile** (`CompileExpectation`
  ~l.108-116). The only escape hatch is `assertJsCompileError` (~l.167), which asserts that
  the program *keeps* failing that way and requires a comment naming the missing feature —
  three call sites today (`tests/narrowing.zig:88`, `:150`, `tests/wat.zig:87`).
- Every backend is compared before the first failure is reported, so one suite round writes
  every `.snap.md.new` instead of stopping at the first mismatch.
- The snapshot tree was flattened to `snapshots/codegen/<target>/<slug>.snap.md` (plus the
  `codegen/errors/<target>/` leg).

### erlang — `src/codegen/erlang.zig`

- **Module-level `val`s are 0-arity functions** and a bare reference is a call, so a `val`
  declared at module scope and read from `main/0` no longer produces
  `variable 'X' is unbound`.
- **Variant patterns mirror what the constructor builds** (`patternNode` ~l.3733,
  `variantTag`): the tagged tuple `{'Rgb', R, G, B}` for a payload, the bare atom `'Lt'`
  without one. The old `{tag, Name, …}` shape bound `Name` as a fresh variable *and* added an
  element no constructor materialised, so every arm failed with `case_clause`.
- **`Ok`/`Err`/`Error` go through one tag table** (`resultTag`), matching the `{ok, V}` /
  `{error, E}` the `#[@result]` transform materialises; a user enum variant of the same name
  keeps its own name.
- **`case` guards are emitted** — `caseNode` used to drop `arm.guard`.
- **String `+` builds one binary**: `"hi " + "there"` → `<<"hi ", "there">>` instead of
  arithmetic `+` on binaries.
- **`&&` / `||` short-circuit** (`andalso` / `orelse`, not `and` / `or`).
- **`@print(a, b, …)`** pairs a fixed format string with the argument list
  (`io:format("~p ~p~n", [A, B])`); the single-`~p` template raised `badarg` with more than
  one argument.
- **Loops are lowered by shape** — a bare `break` inside a loop body is
  `erlang:throw('__bp_break')` caught by the loop's `try` (`loopBreakCatch`); it used to
  render as nothing at all, leaving a `;` where a clause body belonged and breaking the whole
  module.
- **Array spread is `++`**: `[1, 2, ..rest]` → `[1, 2] ++ rest()`, not `[1, 2, rest]`.
- `#[@External.Erlang("…")]` template escapes resolve, and interface instance `default fn`s
  and bare-fn pipeline stages resolve to calls instead of unbound variables.

### beam — `src/codegen/beam_asm.zig`

- **Register staging**: parameters are spilled to `y0..y{arity-1}` right after `allocate`
  (`bindParams` ~l.1122, `emitParamSpill` ~l.1142), so the whole x-file is scratch and a
  `self.field` read cannot overwrite `self`. Every staging site takes its slot from
  `scratchBase()` (~l.1093, `max(min_live, 1)` — never `{x, 0}`, which each
  `lowerExprIntoX0` overwrites) and raises the floor with `raiseLive` (~l.1102) while a
  nested lowering runs, so a `gc_bif` or closure inside operand *i* cannot drop operands
  `0..i-1`. A BEAM `Live` count is a *prefix*, and the emitter now treats it as one.
- **`case`**: a bare `.ident` arm naming a nullary enum variant is a match test against that
  atom, not a binding; a string-literal arm restores the subject register after a failing
  test (`case_string_literal_patterns` printed `hello hi hi`).
- **`@print` prints every argument**, `.len` uses the `length` gc_bif, `null` lowers to
  `undefined` (matching what the option helpers test).
- **Cross-module**: an imported `pub fn` / `pub val` resolves through `crossOwnerOf`
  (~l.1812) to a remote `call_ext` — an imported `pub val` used to lower to the bare atom
  `'HOST'`. A destructure emits `is_map` before `get_map_elements` and writes every binding
  slot on *both* arms of the test, which the validator otherwise reports as
  `{unassigned, {y, N}}` after the merge.
- The `erlc +from_asm` loader-validator rejections the snapshot review recorded are gone: no
  beam snapshot carries a `COMPILE ERROR` block.

### wasm — `src/codegen/wat.zig`

Every emitted module loads. The four rules that keep it that way are documented in
`src/codegen/AGENTS.md` ("wat") and three of them are now enforced by the model rather than
by discipline (see spec 04): locals are hoisted, a sequence carries the stack it leaves,
every `call` is validated against the module's own functions / imports / declared externs,
and types are recovered and coerced rather than assumed. A shape the backend cannot lower
yet emits an honest `;; …` placeholder plus an `i32.const 0` carrier instead of something
that fails validation.

## How it is verified today

- `zig build test` is green from `repository/botopink-lang/`.
- `scripts/snap_audit.sh --mode=coverage` — label `a` = source without
  `@print`/`@assert`/`@panic`, `b` = has one and a `fn main`, `c` = has one but no `fn main`;
  state = RUN LOG section `missing` / `empty` / `nonempty`:

  | backend | a/empty | a/nonempty | b/missing | b/empty | b/nonempty | c/empty | total |
  |---|---|---|---|---|---|---|---|
  | node (commonJS) | 145 | 1 | 3 | 18 | 110 | 2 | 279 |
  | erlang | 146 | 0 | 3 | 6 | 122 | 2 | 279 |
  | beam | 145 | 0 | 3 | 18 | 110 | 2 | 278 |
  | wasm | 145 | 0 | 3 | 128 | 0 | 2 | 278 |
  | errors | — | — | — | — | — | 4 (`c/missing`) | 4 |

  `a/missing` is **0** on every backend (it was 30, i.e. the 29 tests whose snapshot files
  were 0 bytes), and `c/nonempty` is 0. Observable RUN LOGs went from 88 → 110 (node),
  64 → 122 (erlang) and 78 → 110 (beam); the erlang and beam figures are now produced by a
  process that really ran rather than by the local runtime cache.
- The three `b/missing` snapshots are the same three slugs on all four targets
  (`narrow_and_condition_field_access`, `narrow_assert_pattern_with_print`,
  `string_slice_without_end_arg_slices_to_source_length`) — the documented
  `assertJsCompileError` skips, each carrying its `COMPILE DIAGNOSTIC` section.
- `COMPILE ERROR` blocks left in a RUN LOG: **0** on commonJS, beam and wasm; **1** on erlang
  (`comptime_block_with_break`).
- Assembling every beam snapshot with `erlc +from_asm` after rewriting its `{exports, …}`
  form to export every function: **2 of 275** modules are rejected. (Unexported functions are
  dropped before validation, so the recorded modules assemble cleanly; the full-export run is
  what exposes the remaining staging bugs.)
- Compiling every `WASM TEXT` block with `wasmtime compile`: **282 of 282** load.
