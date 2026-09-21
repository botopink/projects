# The wat comptime runtime

**Decided (84, 2026-09-20): this runtime is the comptime runtime of every build whose target is `commonJS`, `typescript` or `wasm`, and of the client half of a split project; erlang/beam targets and a build with no target use beam. No flag.**

What a comptime body needs at run time, what `wat.zig` gives today, how the gap is closed, how
wasm3 is embedded, and the wire encodings. Measured 2026-09-20 ([`evidence.md`](./evidence.md)
E-8, E-9, E-10).

## 1. The host-import surface of a `wat.zig` module today

Exactly one import, `wasi_snapshot_preview1.fd_write` (`src/codegen/wat/wat_prelude.zig:65`,
rendered by `wat/wat_emitter.zig:50`). Everything else — the bump allocator (`$__heap_ptr`, data
section from 256), `str_concat`, `str_eq`, `str_slice`, `arr_at`, the print family, `assert_fail` —
is synthesised into the module as one of **42** `HelperGroup`s (`wat_ast.HelperGroup`,
`wat_prelude.zig:29-55`), emitted whole or not at all. A module that prints nothing imports nothing.

So a host for wat-lowered code provides `fd_write(fd, iovs, iovs_len, nwritten) → errno` and a
linear memory, and nothing else. From Zig (wasm3) that is one `m3_LinkRawFunction`; in a browser it
is one JS function. This is the property that makes the wat runtime the browser's runtime.

## 2. Why "run wat.zig's output" is not enough

`wat.zig` is untyped in its **input** — 65 uses of `ast.Expr`, 0 of `TypedExpr`; "codegen is
untyped, so we recover record/enum layout" (`wat.zig:576`, `:592`, `:616`) — but **static** in its
**values**: an `i32` is a number, a pointer to a length-prefixed string, a tuple base or a funcref
index by what the emitter knows at the call site, never by a tag in memory. `zero` (`:56`) is
"absence, false, a null pointer and every construct it cannot lower".

A comptime body is dynamically typed by construction. The erlang lowering makes that explicit: every
operation whose meaning depends on the run-time type is a call — `'__bp_add'/2` (number or string,
183 of 183 on-disk modules), `'__bp_len'/2` (183), `maps:get/2` (159), `'__bp_prim_<m>'` shims
(14) — and the argument is an ETF term whose shape the body discovers (`case` in 161 modules,
`fun(` in 141). Under a static value model `'__bp_add'(8000, X)` cannot be lowered: `X`'s tag is
not known.

Therefore `persistent_wat.zig` runs a **dynamic-term mode** of `wat.zig`, not the static target
mode. The two share the model (`wat_ast`), the emitters (text and binary) and the prelude
machinery; they differ in the value representation and in which helpers are linked.

## 3. The dynamic-term heap

One tagged representation, the eight `Term` variants `beam/term.zig` and `etf.zig` already name:

```
term := i32 pointer into linear memory →  u8 tag | payload
  0 nil                        (no payload; the canonical pointer is a constant)
  1 boolean    u8
  2 integer    i64             (small ints; bignums refused — none in the 183 modules)
  3 float      f64
  4 atom       u32 len, bytes  (interned: one pointer per distinct atom, so `==` is pointer equality)
  5 binary     u32 len, bytes  (a string)
  6 list       u32 count, count × term ptr   (a flat array of pointers; `lists:*` work on it)
  7 tuple      u32 arity, arity × term ptr
  8 map        u32 count, count × (key ptr, value ptr), keys sorted by atom pointer
```

Every helper of the erlang prelude's untyped set becomes a prelude group over this heap:
`$__bp_add`, `$__bp_len`, `$__bp_text`, `$__bp_json`, `$__maps_get`, `$__maps_put`,
`$__lists_map/foldl/foreach/filter/reverse/append`, `$__string_split/trim/uppercase/…`, `$__bp_eq`
(structural), `$__bp_cmp`. Closures (`fun(`, 141 modules) are the existing funcref table plus an
environment tuple — `wat.zig`'s closure lowering (27 sites) already does this in static mode with
`i32` environments; in dynamic mode the environment is a tuple term. `case` over terms is a `$__bp_is_*`
test on the tag plus the existing block/br_if arm structure. `try`/`throw` (183 / 125 modules): a
throw sets a global `$__bp_thrown` term and unwinds by returning `nil` through every frame that
checks the global after a call — no exception proposal needed, no host round trip.

**Memory.** The module's memory is fresh per evaluation (wasm3 re-instantiates; in the browser
`WebAssembly.instantiate` per call): the bump allocator never frees, and a body's whole run is one
arena. `eval_timeout_ms` (10 s on BEAM) becomes a fuel limit on wasm3 (`m3_SetFuel` where the build
enables gas, else an instruction-count trap in the prelude's loop back-edges) — the same contract,
"a runaway body is killed, not the compiler".

## 4. Feature gap table

Left: what the 183 on-disk comptime modules use (E-9, modules out of 183). Middle: what `wat.zig`
lowers today in static mode (E-8: the 22 carrier sites where it does not). Right: how the dynamic
mode closes or refuses it.

| Comptime body construct | Used by | Static `wat.zig` today | Dynamic mode |
|---|---:|---|---|
| `+` on number-or-string (`'__bp_add'`) | 183 | numbers only; string `+` via `str_concat` when both sides are statically strings (`isStringExpr`) | `$__bp_add` helper dispatching on tags (step 2) |
| `.length` (`'__bp_len'`) | 183 | arrays and strings by static kind | `$__bp_len` on tag 5/6/7 (step 2) |
| JSON reply (`json:encode`) | 183 | **none** (0 `json` sites) | `$__json_encode` group: escapes per RFC 8259, integers, floats via `print_f64`'s digits, maps as objects with atom keys, lists as arrays, `nil` → `null` — byte-identical to OTP `json:encode/1` on the 33 fixtures (asserted) |
| `try … catch` / `throw` | 183 / 125 | no exceptions (`assert_fail` traps) | thrown-global unwinding, § 3 |
| string literals (`<<"…">>`) | 183 | length-prefixed data segments | tag 5 terms in the data segment |
| map literal / `maps:get` (`#{`, `maps:`) | 183 / 159 | **none**: 0 `put_map`/map sites; `Dict` is "no lowering here" (`:3351-3352`) | tag 8 + `$__maps_get`/`$__maps_put`; a missing key fails the body with the erlang path's `{badkey, K}` text (decision 63/67: fail, not `nil`) |
| `case` on a term | 161 | numbers, strings, variants, Result tags (`:2923` "unknown variant" → `zero`) | tag tests; an arm the lowering cannot type-test is **refused** with `unsupported_method`-style located diagnostic, never `zero` |
| `erlang:*` BIFs (`is_binary`, `element`, `tuple_size`, `atom_to_binary`, …) | 161 | none | one helper per BIF the 183 modules use — the list is closed and small (measure in step 0: `grep -o "erlang:[a-z_]*" \| sort -u`) |
| closures (`fun(`) | 141 | funcref table, static env (`:3559`, `:3650`: map/flatMap need a *literal* closure — receiver passed through) | funcref + tuple env; `lists:map` with a bound fun is a helper, so the literal-closure restriction goes |
| `io_lib`/`integer_to_binary`/`float_to_binary`, `iolist_to_binary` | 131 | `print_*` digit groups exist | `$__bp_text` reuses the digit writers into a tag-5 term |
| `string:*` (`split`, `trim`, `uppercase`, `lowercase`, `replace`, `find`) | 129 | `str_slice`, `str_eq`, `str_concat` only | one helper per `string:` function used — measure the closed list in step 0 |
| `lists:*` (`map`, `foldl`, `foreach`, `filter`, `reverse`, `seq`, `nth`, `member`, `join`) | 128 / 54 | comprehensions and loops over static arrays | helpers over tag 6 |
| `'__bp_prim_<callee>'` shims (method on an untyped receiver) | 14 | primitive methods via `instance_lowerings` on a statically known receiver | `$__bp_prim_<callee>`: tag dispatch to the string/list helper, or the same located `unsupported_method` diagnostic the erlang path gives (`erlang.zig:481`) |
| capture API (`text/parts/source/context/bindings/lookup/ref`) | 67 | n/a | resident prelude functions over the decoded argument map — the wat twin of `prelude.zig:73-170`, generated from the **same `erl_ast` forms** through a small `erl_ast → wat_ast` lowering, so one definition |
| `emit/1`, `'__bp_emitted'/0` (decorators) | 80 | n/a | a global list term appended to; `main` returns it in the reply |
| `custom/3`, `build/2`, `expr/1`, `code/1` | 59 / 73 | n/a | result constructors as tuple terms, `$__bp_reply` matches `{'__bp_code', …}` |
| `binary:`/`byte_size` | 5 | n/a | `$__bp_len` on tag 5 |
| `unicode:*` | 0 | n/a | not lowered; refused if it appears |
| destructuring patterns (`:1466`, `:2675` "unsupported destructure pattern") | — | note + skip | tuple/list/map patterns on terms are exactly what `case` needs; lowered |
| `range`, pipeline rhs, `continue` outside loop (`:2959`, `:2943`, `:2987`) | — | `zero` / note | refused with a located diagnostic |
| Result/Option ops (`:3715`), `None` (`:3679`) | — | `zero` | atoms `ok`/`error`/`nil` terms, the erlang lowering's shape |
| array spread (`:4203`), extra args (`:4351`) | — | note | spread → `$__lists_append`; extra args refused |
| `§10` / decision 52 loop values (`:6522`, `:6529`, `:6558`) | — | `zero` | terms; same semantics the erlang path implements |
| binary op on unknown type (`:7209`) | — | `drop` | `$__bp_cmp`/`$__bp_arith` on tags |

**The rule**: in dynamic mode there is no `zero` carrier. A construct is lowered to a helper or
refused with the same located diagnostic the erlang path emits for an unsupported method
(`erlang.zig:481-495`, `template_eval.zig:271`); the refusal count is the step's progress metric and
a refusal on a fixture the BEAM runtime answers is a parity failure.

## 5. Encodings

**In — ETF, reused.** `etf.encode` (`comptime/runtime/etf.zig:43`) already writes the argument for
the BEAM path, pinned by inline tests to `term_to_binary/1`'s byte vectors on OTP 29. The wat path
copies those bytes into the module's memory at a known offset and calls `$__etf_decode(ptr, len) →
term` (a prelude group: 131 magic, tags 97/98/110/70/106/108/104/105/116/119/118/109 — the same
twelve `etf.zig` emits, nothing else; an unknown tag traps). Why not JSON or CBOR: a second encoder
in Zig for the same `Term`, and a format that cannot say atom-vs-binary (`maps:get(name, Decl)`
keys are atoms, values are binaries) or tuple-vs-list without a schema. ETF is one encoder, one
decoder per runtime, and the decoder is ≈ 150 lines of wat.

**Out — JSON text, identical.** The BEAM prelude's `'__bp_reply'/1` + `json:encode/1` produce the
reply `parseOutcome` reads (`template_eval.zig:701`; `Reply` `:691`). The wat prelude's `$__bp_reply`
+ `$__json_encode` produce the same bytes. The assertion is the 33 `COMPTIME REPLY` sections (E-6):
OTP's `json:encode` output on those is the oracle; escaping and float formatting must match it byte
for byte (floats: none of the 33 fixtures emit a float — verify in step 0; if one does, the format
is OTP's `float_to_binary(F, [short])`).

**Errors — the three-way `Response`.** `compile_error` is what the lowering refuses (before any
run); `runtime_error` is a trap or a thrown term that reached `main` (the prelude's `main` catch
writes `{kind: "error", message}` exactly as the erlang `main/1` does); `ok` is the reply bytes.
The evaluators' `switch (response)` (`decorator_eval.zig:112`, `template_eval.zig:139`) is untouched.

## 6. Embedding wasm3

`modules/wasm3/` is re-vendored (it was deleted 2026-06-29 with `wat_runtime.zig` and
`wat_to_wasm.zig`; the `.zig-cache` still holds its `cimport.zig`, 236 `m3_*`/`M3*` symbols — E-10).
Its `build.zig` exports what the previous vendoring did: `link(compile_step)`, `exposeHeaders(module)`,
`wasm3_srcs`, `wasm3_cflags`; root `build.zig` links it into the compiler-core module only for
native targets (`if (!target.result.cpu.arch.isWasm())`).

`persistent_wat.zig`:

```zig
pub fn evalWithArg(alloc, io, module: Module, arg: []const u8) !Response
  // 1. bytes = module.wasm (binary, from wasm_binary_emitter; cached per atom like `loaded`)
  // 2. env = m3_NewEnvironment(); rt = m3_NewRuntime(env, stack, ctx); m3_ParseModule; m3_LoadModule
  // 3. m3_LinkRawFunction(mod, "wasi_snapshot_preview1", "fd_write", "i(iiii)", &fdWrite)  → ctx.captured
  // 4. write arg into memory; m3_FindFunction("main"); m3_CallV(main, ptr, len)
  // 5. read the reply (ptr,len) from memory; classify; m3_FreeRuntime
```

No child process, no pipe, no lock across processes: the `io_mu` spin-lock and the `loaded` set of
`persistent_erl.zig` become a per-module cache of parsed bytes. Prints go to `ctx.captured` (the
role `erl.stderr.log` had), discarded unless a transport-style error names them.

**Binary emission.** wasm3 (and `WebAssembly.instantiate`) take the binary format, not `.wat`;
`wasmtime run` accepted text, which is why nothing in the tree encodes binary today.
`src/codegen/wat/wasm_binary_emitter.zig` renders the same `wat_ast.Module` the text emitter renders:
sections type(1), import(2), function(3), table(4), memory(5), global(6), export(7), start(8),
element(9), code(10), data(11), LEB128 everywhere, one function type per distinct signature. The text
stays the snapshot's `COMPTIME WAT` section; the binary is never written to disk on the comptime path.

## 7. What the BEAM runtime keeps doing that this one does not

`safe_call`'s process isolation (a body that `spawn`s, `receive`s, or touches ETS) has no wasm
equivalent and none of the 183 modules does any of it (E-9: 0 `spawn`, 0 `receive`, 0 `ets`); a body
that reaches an Erlang-only BIF is refused on wat and recorded as a parity gap, which is the honest
shape: the BEAM runtime is the reference, and the wat runtime's coverage is a measured number that
must reach 33/33 before a `commonJS`/`wasm`-target build is switched onto it (decision 84 names
the target rule; step 2's acceptance is the gate for the switch).
