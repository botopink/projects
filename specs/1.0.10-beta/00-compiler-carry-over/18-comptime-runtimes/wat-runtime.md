# The wat comptime runtime

**Decided (84, 2026-09-20): this runtime is the comptime runtime of every build whose target is `commonJS`, `typescript` or `wasm`, and of the client half of a split project; erlang/beam targets and a build with no target use beam. No flag.**

What a comptime body needs at run time, how the wat runtime gives it, how it is embedded, and the
wire encodings. Code: `modules/compiler-core/src/comptime/runtime/` (`runtime.zig`,
`persistent_wat.zig`, `wat/`) — the per-file contract is in `wat/AGENTS.md`.

## 1. One program, two runtimes

A decorator or template body is lowered once, by `codegen/erlang.zig` `emitComptimeModule`, into an
Erlang module (untyped mode: `'__bp_add'`, `'__bp_len'`, `maps:get`, `'__bp_prim_<m>'` shims, a
`main/1` taking an ETF argument). The BEAM runtime compiles that text. **The wat runtime runs that
same text**: it parses it back, lowers it to wasm and runs the result. There is no second lowering of
the botopink AST (an earlier design gave `wat.zig` a "dynamic-term mode"; it was not built): with one
program, the two runtimes can only disagree where a BIF is implemented twice — `rt.zig` against OTP —
and that is what the parity check measures (§ 6).

```
FnDecl ─ emitComptimeModule ─ Erlang text ─┬─ erlc/cmd 2 ─ BEAM (persistent_erl.zig)
                                           └─ wat/erl_parse ─ wat/lower ─ wat/link(+ rt.wasm) ─ wasm3 (persistent_wat.zig)
```

## 2. Reading the Erlang back — `wat/erl_parse.zig`

A tokenizer and recursive-descent parser for the subset `codegen/beam/erl_emitter.zig` writes plus
the host templates of `libs/std/src/primitives.bp` (`raw` nodes): attributes, function clauses with
guard sequences, `case`/`if`/`try … of … catch`/`begin`, `fun` (anonymous, named, `fun f/A`,
`fun m:f/A`), list comprehensions with list and binary generators, maps and map updates, binaries
with segment types and sizes, strings as code points (as `erlc` reads a UTF-8 source), the operator
table. `receive`, records, macros and the old-style `catch E` are refused by name. It parses every
comptime module on disk when it was written: 420 (the compiler's tests and the five libraries).

## 3. The term heap and the runtime library — `wat/rt.zig`

Every value is an `i32` pointer to a tagged cell on the module's linear memory — the Erlang shapes the
generated modules use:

```
int (i64; a bignum raises {bp_wat_runtime, …})   float   atom (interned)   binary (a literal is referenced)
cons / []   tuple   map (keys kept in iteration order)   fun (table index, arity, environment tuple)
```

The library is **Zig compiled at `zig build`** for `wasm32-freestanding` (MVP features, `ReleaseSmall`,
`__heap_base` exported) and embedded in the compiler as bytes (`bp_wat_rt.wasm`, ≈ 60 KB) — not
hand-built wat prelude groups. It exports the term constructors and tests, term order and `==`/`=:=`,
and the BIFs the generated modules reach (`erlang:*`, `lists:*`, `maps:*`, `string:*`, `binary:*`,
`unicode:*`, `math:*`, `io_lib:format`, `io:format`, `json:encode`), each raising the reason the BEAM
raises (`badarg`, `{badkey, K}`, `badarith`, `function_clause`, `{badmap, M}` …). Memory is one bump
arena per evaluation (`rt_init`), grown by `memory.grow`, never freed: the module is instantiated fresh
for every evaluation.

**Exceptions.** A raise records `{Class, Reason}` in the runtime and returns `[]`; the lowered code tests
`rt_pending()` after every call that can raise and branches to the innermost handler — a `try`'s catch
clauses, a guard's failure (a raising guard fails, the exception is cleared), or the function's exit
(which returns 0). No wasm exception proposal, no host round trip.

## 4. The lowering and the link — `wat/lower.zig`, `wat/link.zig`

`lower.zig` lowers the generated module and the resident prelude it `-import`s (`../prelude.zig`'s
rendering, parsed once per process) — only what `main/1` reaches — into one `codegen/wat/wat_ast.zig`
module: clauses as `block`/`br` chains, patterns as tests on terms, funs lifted to table functions
`(Self, A1…An)` with an environment tuple, list comprehensions as loops, calls to the runtime as
`(import "rt" "rt_*")`. What it cannot take — `self/0`, `apply/3`, a BIF not in its table — is a
**refusal naming the construct**, reported as the module not compiling; never a zero value. The
refusal count over every codegen fixture and the five libraries is 0.

`link.zig` splices that module into the runtime's bytes: the runtime's sections are copied byte for
byte, the program's types, functions, table slots, globals, exports and literal data are appended, and
its `"rt"` imports resolve to the runtime's exports. The program's function bodies are encoded by
`codegen/wat/wasm_binary_emitter.zig` against the merged index spaces. The result is one module that
**imports nothing**. `wat/program.zig` caches it per module atom (the atom is the content hash of the
text). The `.wat` rendering of the lowered program is the listing a `COMPTIME WAT` snapshot section
shows (step 4).

## 5. Encodings

**In — ETF, reused.** `etf.encode` (`comptime/runtime/etf.zig`) writes the argument for both runtimes;
the wat module decodes it (`rt_etf_decode`) — exactly the tags `etf.zig` writes, an unknown tag traps.
One encoder, one decoder per runtime; atoms stay atoms, binaries stay binaries.

**Out — `json:encode` bytes.** `main/1` ends in `json:encode(…)` on both runtimes; `rt.zig`'s encoder
writes what OTP 27+'s writes (the escapes; floats as `float_to_binary(F, [short])`). One difference is
not reproducible and not part of the answer: the order of a map's keys. The BEAM iterates atom keys in
atom-table order — which modules the node happened to load first. So replies are read **in canonical
order, keys sorted** (`comptime/runtime/reply_order.zig`): the `COMPTIME REPLY` snapshot section, a map
lifted by `@expr` (its labels), and the parity comparison.

**Errors — the three-way `Response`.** `compile_error` is a refusal of the lowering (or the engine
rejecting the module); `runtime_error` is an exception out of `main` — `Class:Reason` as `~p` writes
them, the first line of the BEAM runtime's text, which appends a stack — or an engine trap; `ok` is the
reply. The evaluators' `switch` is the same for both runtimes (`runtime.zig` `Response`).

## 6. Executors and parity

**Native: wasm3, in-process** (`persistent_wat.zig`). A fresh wasm3 environment and runtime per
evaluation (8 MiB interpreter stack: an Erlang loop is recursion, and there are no tail calls), then
`bp_init`, `rt_alloc` + the ETF argument copied in, `bp_main(ptr, len)`. No child process, no pipe, no
file. A body's `io:format` goes to a buffer in the module's own memory — it cannot reach the
compiler's stdout. wasm3 is vendored in `modules/wasm3/` (v0.5.0, `-fwrapv -fno-sanitize=undefined`:
wasm integer arithmetic wraps).

**The browser build: the page's engine** (step 5). On `wasm32` the same export sequence runs behind
three host imports `modules/compiler-web/glue.js` serves (`bp_host.run_module`, `result_len`,
`result_copy`), with `WebAssembly.Instance`.

**Parity.** `runtime.parity` (a test hook) runs every evaluation on the other runtime too and records
answers that differ (`equivalent`: replies in canonical order, compile errors by kind, runtime errors
by `Class:Reason`). The codegen snapshot harness runs every fixture under it; `parity.zig` pins that the
comparison is live and that an edited helper is reported with both replies printed.

## 7. What the BEAM runtime does that this one does not

- `safe_call`'s process isolation and its 10 s timeout: a runaway body is a runaway wasm3 call today.
  No generated module `spawn`s, `receive`s or touches ETS.
- `~p`'s line breaking past 80 columns (`io_lib_pretty`): a long term in an error text prints on one
  line. No fixture carries one.
- Unicode case mapping: `string:uppercase`/`lowercase` of a non-ASCII letter raises
  `{bp_wat_runtime, …}` instead of answering.
- Integers beyond 64 bits: `{bp_wat_runtime, …}`.

The BEAM runtime is the reference; a difference found by parity is fixed in `rt.zig`.
