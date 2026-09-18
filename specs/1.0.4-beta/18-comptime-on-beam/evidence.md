# Evidence — comptime on BEAM

Every number in [`README.md`](./README.md), [`current-path.md`](./current-path.md),
[`options.md`](./options.md) and [`migration.md`](./migration.md) is produced here. Measured
**2026-09-17** on `botopink-lang` `0e5ff66`, Linux 7.2.4, **Erlang/OTP 29 (ERTS 17.0.6,
compiler 10.0.4)**, Zig 0.16.0, `zig build` already warm.

Scratch projects live outside every repository, under a session scratchpad; nothing below writes
into `repository/`. Re-run any block after `cd` into a fresh scratch directory.

---

## Method

Three instruments, used throughout:

| Instrument | What it measures | How |
|---|---|---|
| **E-1 wall clock** | one `botopink build`, best of 5 | a Python wrapper around `subprocess.run`, `time.perf_counter`, `min` and `median` reported |
| **E-2 in-node timing** | `compile:file` / `code:load_binary` / `Mod:main()` on a real generated module | an Erlang benchmark module run under `erl -noshell`, `erlang:monotonic_time(microsecond)`, N repetitions after one warm-up |
| **E-3 protocol replay** | the comptime server's round trip, seen from outside the compiler | a Python client that spawns the **same** `erl -noshell -pa <hash dir> -eval botopink_comptime_server:start(), halt().` and speaks the same `<u32 BE len><cmd><path>` frames |

E-2 and E-3 agree with each other and with `strace -c -w` on the compiler process
([E6](#e6--where-the-wall-clock-goes)), which is why the split below is reported as fact rather
than as estimate.

---

<a id="e1"></a>

## E1 — the comptime path costs 25 ms per evaluation, linearly

A generated project: one template fn (the `yamlconf` shape — `q.text()`, arithmetic, a labeled
tuple, `@expr`) and *N* call sites with **distinct** literals, so the memo cache
(`infer.zig:3470`) never hits.

```
pub fn conf<T>(comptime q: @Expr<string>) -> @Expr<T> {
    val t = q.text();
    val host = "0.0.0.0";
    val port = 8000 + t.length;
    val server = #(host, port);
    val debug = true;
    return @expr(#(server, debug));
}
val c0 = conf "cfg-0";
…
val c199 = conf "cfg-199";
```

`botopink build --target commonJS`, best of 5:

| N call sites | build (min) | `.erl` modules written | marginal cost |
|---:|---:|---:|---|
| 0 | **79.4 ms** | 0 | — (no `erl` is spawned at all) |
| 1 | 250.5 ms | 1 | +171 ms — server spawn + first eval |
| 10 | 481.9 ms | 10 | 25.7 ms / eval |
| 50 | 1342.1 ms | 50 | 21.5 ms / eval |
| 100 | 2578.9 ms | 100 | 24.7 ms / eval |
| 200 | **5255.8 ms** | 200 | 26.8 ms / eval |

**≈ 25 ms per evaluation, flat.** `check` and `build --target erlang` are the same to within 1 %
(5252.9 / 5279.6 ms at N = 200): the cost is inference-time, not codegen-time, and no target
escapes it.

**The memo cache proves it is the evaluation, not the parse.** The same 200 call sites with an
**identical** literal (one eval, 199 cache hits) build in **254.0 ms** — 1/20 of the time, one
`.erl` on disk.

<a id="e2"></a>

## E2 — inside the node: 8–52 ms to compile, 1 ms to load, 0.05 ms to run

E-2 over the modules the builds above left in `.botopinkbuild/tmp/template/`, N = 50 after a
warm-up:

| Generated module | lines | `compile:file` | `code:load_binary` | `Mod:main()` | `.beam` |
|---|---:|---:|---:|---:|---:|
| the N=200 project's (scope of 200 bindings) | 295 | **8.864 ms** | 1.103 ms | **0.232 ms** | 8 740 B |
| the N=10 project's | 105 | 6.734 ms | 1.072 ms | 0.238 ms | 2 940 B |
| erika's `erika` template | 759 | **52.858 ms** | 1.306 ms | **0.063 ms** | 12 888 B |

Summed over every module a real build produces (each compiled once, after a warm-up pass):

| Project | modules | `compile:file` | `code:load_binary` | `main()` | total `.beam` |
|---|---:|---:|---:|---:|---:|
| `erika` (the library) | 12 | **629.2 ms** (avg 52.44) | 10.7 ms | **0.63 ms** | 150 692 B |
| `erika/examples/erika-linq` | 18 | **942.2 ms** (avg 52.34) | 16.7 ms | **0.99 ms** | 227 424 B |
| `rakun/examples/rakun` decorators | 16 | 124.6 ms (avg 7.79) | 5.5 ms | 0.06 ms | 53 476 B |
| compiler suite, `tmp/template` | 56 of 57¹ | 443.6 ms (avg 7.92) | 34.0 ms | 0.42 ms | 155 864 B |
| compiler suite, `tmp/decorator` | 68 | 326.5 ms (avg 4.80) | 15.3 ms | 0.18 ms | 135 796 B |

¹ one fixture is a deliberate compile-error case (`erl_lint: undefined_function {ref,1}`) — the
negative test of the `compile_error` reply.

**The body itself is 0.06 % of the cost.** On `erika-linq` the comptime work — the SQL lexer, the
parser, the dual lowering — runs in **0.99 ms**; the Erlang compiler spends **942 ms** turning the
program that does it into a module, eighteen times.

<a id="e3"></a>

## E3 — the server round trip, measured from outside the compiler

E-3, same server binary, same working directory, same `.erl`:

```
spawn + server load + first eval:  149.2 ms   (N=200 project's module)
warm round trip:  min 9.75 ms   median 10.70 ms   max 12.08 ms
spawn + server load + first eval:  143.2 ms   (N=10 project's module)
warm round trip:  min  7.44 ms   median  8.36 ms   max  9.63 ms
```

`compile:file` + `load_binary` + `main()` from [E2](#e2) is 10.20 ms and 8.04 ms for those two
modules: the frame protocol itself costs **≈ 0.4 ms**, and the erl child's spawn-and-load is
**≈ 145 ms**, once per compiler process.

Floor for comparison — a bare VM start is **76.3 ms** (`erl -noshell -eval 'halt().'`, best of 10),
so the resident server pays for itself after the second evaluation and must stay resident whatever
else changes.

<a id="e4"></a>

## E4 — every call site compiles the same program again

For each project, every `.erl` in `tmp/{template,decorator}` was hashed whole (module line
normalised) and hashed again **up to `main/0`** — i.e. the lowered body plus the fixed host
functions, everything except the capture / handle data literal:

| Project | modules on disk | distinct modules | distinct code before `main/0` |
|---|---:|---:|---:|
| N=200 project, 1 template | 200 | 200 | **1** |
| `erika` (library) | 12 | 12 | **1** |
| `erika/examples/erika-linq` | 18 | 18 | **1** |
| `rakun/examples/rakun` (decorators) | 16 | 16 | 10 |
| compiler suite templates | 57 | 57 | 39 |
| compiler suite decorators | 68 | 68 | 33 |

A line-level diff of two of the N=200 modules: **14 differing lines out of 296**, every one of them
inside the capture literal —

```
--module(template_00c23fdb5a226a42).      +-module(template_069be15f6cb92ce0).
-            text => <<"cfg-29">>,        +            text => <<"cfg-152">>,
-                    span => #{start => 0, 'end' => 6, line => 1}
+                    span => #{start => 0, 'end' => 7, line => 1}
-            source => #{file => <<"main">>, line => 39, col => 16},
+            source => #{file => <<"main">>, line => 162, col => 17},
```

A census of one generated module (295 lines, the N=200 shape):

| Part | lines | share |
|---|---:|---:|
| the user's template body, lowered | **7** | 2.4 % |
| fixed host functions (`'__bp_add'`, `'__bp_len'`, `'__bp_text'`, `'__bp_json'`, `text`, `parts`, `source`, `context`, `bindings`, `lookup`, `ref`, `build`, `custom`, `fail`, `failAt`, `compilerError`, `expr`, `code`, `'__bp_reply'`) | 54 | 18.3 % |
| `main/0` — the capture as a literal map | 230 | 78.0 % |

The capture literal grows with the *caller's lexical scope*: the N=200 project's capture carries
all 200 top-level `val` names in its `bindings` list, which is why its module is 295 lines where
the N=10 project's is 105.

<a id="e5"></a>

## E5 — what each module shape costs

Same body, four shapes. `small` is the N=200 project's generated module; `tiny` is the same body
with the 19 host functions moved into a resident `bp_prelude` module and the capture taken as
`main/1`'s argument instead of baked in; `big` / `bigtiny` are the same transformation applied to
erika's 759-line template. `.S` produced with `erlc -S`, then `compile:file(…, [from_asm, binary,
return])`.

| Module | source lines | `.S` lines | `compile:file` | `.beam` |
|---|---:|---:|---:|---:|
| `small.erl` — **today's shape** | 295 | 541 | **8.470 ms** | 8 624 B |
| `small.S` `+from_asm` | — | 541 | **2.070 ms** | 8 460 B |
| `tiny.erl` — prelude + capture as argument | 14 | 68 | **1.290 ms** | 1 068 B |
| `tiny.S` `+from_asm` | — | 68 | **0.392 ms** | 904 B |
| `big.erl` — **today's shape** (erika) | 759 | 2 132 | **53.254 ms** | 12 760 B |
| `big.S` `+from_asm` | — | 2 132 | **10.211 ms** ¹ | 12 600 B |
| `bigtiny.erl` — prelude + capture as argument | 649 | 1 684 | **47.281 ms** | 10 084 B |
| `bigtiny.S` `+from_asm` | — | 1 684 | **9.333 ms** | 9 924 B |

¹ a second run of the same measurement gave 11.938 ms — the largest run-to-run spread seen in this
file (≈ 15 %). Every other row reproduced within a few per cent. Treat one significant figure as the
claim.

Two readings:

- **Narrowing the module helps a small body a lot (8.47 → 1.29 ms) and a large body barely
  (53.25 → 47.28 ms).** For a large body the win is not the shape, it is compiling it **once**
  instead of once per call site ([E4](#e4)).
- **`+from_asm` is worth 3–5× on every shape** (8.47 → 2.07, 53.25 → 9.33, 1.29 → 0.39).

`+no_postopt` does **not** help — the remaining cost is `beam_validator` and `beam_asm`, not the
assembly-level optimisers:

```
big.S    +from_asm                  11.938 ms/call
big.S    +from_asm +no_postopt      13.979 ms/call
small.S  +from_asm                   2.397 ms/call
small.S  +from_asm +no_postopt       2.080 ms/call
tiny.S   +from_asm                   0.453 ms/call
tiny.S   +from_asm +no_postopt       0.445 ms/call
```

(`compile:file`'s `asm_passes()` under `+from_asm` still runs `beam_a`, `beam_block`, `beam_jump`,
`beam_clean`, `beam_trim`, `beam_flatten`, `beam_z`, `beam_validator_weak`, `beam_asm` —
`/usr/lib/erlang/lib/compiler-10.0.4/src/compile.erl`.)

**`code:load_binary/3` is the floor.** 1 068-byte module, N = 200:

```
code:load_binary(tiny)        1.034 ms/call
read_file + load_binary       1.083 ms/call
```

So any design that loads **a module per evaluation** cannot go below ≈ 1 ms per evaluation, however
the module is produced. A design that loads a module per *template declaration* and then calls it
pays 0.05–0.24 ms per evaluation ([E2](#e2), `Mod:main()`).

<a id="e6"></a>

## E6 — where the wall clock goes

`strace -c -w` (wall-clock accounting) on the **compiler process only**, N = 200:

```
% time     seconds  usecs/call     calls    errors syscall
 97,27    2,193207        5483       400           readv
  0,96    0,021697          10      1975           munmap
  0,39    0,008752          10       803           writev
```

400 `readv` = 2 per evaluation (the 4-byte length prefix, then the payload) × 200 evaluations —
**one request per call site, no hidden second pass**. 2.193 s blocked on the server over a 5.25 s
build.

| Share of the N=200 build (5 255.8 ms) | ms | % |
|---|---:|---:|
| baseline compile with no comptime (N=0) | 79.4 | 1.5 |
| `erl` spawn + server load ([E3](#e3)) | ≈ 145 | 2.8 |
| blocked on the server — `compile:file` + `load_binary` + `main()` ([E6](#e6) `readv`) | **2 193** | **41.7** |
| compiler-side, per evaluation (the remainder ÷ 200 ≈ 14.7 ms) | ≈ 2 938 | 55.9 |

The compiler-side remainder is **not attributed further here**. Two candidate sites, both read at
`0e5ff66`: `buildModule` renders the module **twice** — once compilable, once as a `listing` for
the trace (`template_eval.zig:333-338`, `decorator_eval.zig:231-236`), and the trace list is passed
unconditionally from `infer.zig:3475` / `:2341`; and `writeModule` stages a randomly-named file and
renames it for every evaluation (`template_eval.zig:125-137`). It scales with module size
(14.7 ms/eval for 295-line modules, ≈ 22.5 ms/eval for erika's 739-line ones), which fits an
emission cost.

<a id="e7"></a>

## E7 — a template makes a JavaScript build depend on Erlang

```
$ env PATH=/empty botopink build --target commonJS
  Compiling 1 module(s)...
error: the template evaluator failed to run
  --> src/main.bp:10:10
   |
10 | val c0 = conf "cfg-0";
   |          ^

error: 1 module(s) failed to compile: main
```

The hint behind it (`infer.zig:3477`): *"Template bodies run in a persistent `erl` process at
compile time — check that `erl` and `erlc` are on PATH."* `AGENTS.md:60-61` states the same as a
prerequisite of `zig build test`.

The whole compile-time dependency on the Erlang toolchain is two `argv`s:

| Site | `argv` | When |
|---|---|---|
| `comptime/runtime/persistent_erl.zig:256` | `erlc -o <staging> <server>.erl` | once per server-source hash, cached in `.botopinkbuild/tmp/persistent_erl/<hash>/` |
| `comptime/runtime/persistent_erl.zig:211` | `erl -noshell -pa <hash dir> -eval botopink_comptime_server:start(), halt().` | once per compiler process, lazily |

Everything else that shells out to OTP is the **snapshot harness** or the CLI's `run`/`test`, not
the comptime path: `codegen/runtime.zig:545,565` (`erlc`), `:638,660` (`erlc +from_asm`),
`:581,673` (`erl -noinput`), `cli/run.zig:68` and `cli/test_cmd.zig:160` (`escript`).

<a id="e8"></a>

## E8 — `erlc +from_asm` assembles, loads and runs

Using the erika template's own generated module, compiled to `.S` and back:

```
$ erlc -S big.erl && wc -l big.erl big.S
  759 big.erl
 2132 big.S

$ time erlc +from_asm big.S
real 0m0,097s
$ ls -la big.beam
-rw-r--r-- 1 … 12712 … big.beam

$ erl -noshell -pa . -eval 'io:format("~p~n",[code:which(big)]), R = big:main(), io:format("~s~n",[string:slice(R,0,90)]), halt().'
"…/big.beam"
{"source":"of(erikaCities).where({ row -> row.pop >= __bp_hole_q_0 && row.pop <= __bp_hole
```

The module assembled from `.S` produces the same template reply as the module compiled from source.
Out-of-process costs, best of 5:

```
erlc +from_asm big.S     96.5 ms
erlc big.erl            190.9 ms
```

Both are worse than the resident node (9.3 ms and 53.3 ms in-node, [E5](#e5)): **spawning `erlc`
per evaluation is never the answer**; the resident node stays.

<a id="e9"></a>

## E9 — `+from_asm` in memory is not a documented path

`compile:file(File, [from_asm])` reads the `.S` with `beam_consult_asm`, which groups the consulted
terms into the internal `{Mod, Exp, Attr, Code, NumLabels}` the assembly passes expect. Feeding the
consulted term list straight to `compile:forms/2` is rejected:

```
compile:forms(+from_asm) -> {error,[{[],[{none,compile,
    {crash,beam_a,function_clause,[{beam_a,module,[[{module,tiny},{exports,…
```

A hand-rolled regrouping into the 5-tuple was also rejected (`{error,[{[],[{none,…}]}],[]}`). The
conclusion recorded for [`options.md`](./options.md) is narrow and factual: **there is no supported
in-memory `from_asm` entry point; the `.S` has to reach OTP as a file** — which is what the
evaluator already does with its `.erl`, so it costs nothing new.

<a id="e10"></a>

## E10 — what a `.beam` actually contains

Chunks of a module this project generates (`beam_lib:all_chunks/1` on the 1 068-byte `tiny.beam`):

```
AtU8  Code  StrT  ImpT  ExpT  LitT  Meta  LocT  Attr  CInf  Dbgi  Line  Type
```

The size of the machinery behind them, in this OTP's own compiler
(`/usr/lib/erlang/lib/compiler-10.0.4/src/`):

| File | LOC | What it is |
|---|---:|---|
| `beam_asm.erl` | 875 | instruction encoding, chunk layout, the `.beam` writer |
| `beam_dict.erl` | 390 | the atom / import / export / literal / line tables |
| `beam_opcodes.erl` | 397 | **192** `opname/1` clauses — the opcode table, regenerated per release by `beam_makeops` |
| **total** | **1 662** | what option (b) reimplements in Zig, and keeps in step with every OTP release |

`beam_opcodes:format_number()` answers `0` on OTP 29 — the format number is not a version the
compiler can negotiate on; the opcode *table* is what drifts.

<a id="e11"></a>

## E11 — the BEAM backend has no comptime path

Occurrences at `0e5ff66`, `modules/compiler-core/src/codegen/`:

| Symbol | `erlang.zig` | `beam_asm.zig` |
|---|---:|---:|
| `ComptimeModule` | 10 | **0** |
| `host_forms` | 3 | **0** |
| `host_records` | 2 | **0** |
| `host_enums` | 2 | **0** |
| `unsupported_method` | 9 | **0** |
| `untyped` (the comptime lowering mode) | 20 | 2¹ |
| `__bp_len` | 6 | **0** |
| `__bp_json` | 5 | **0** |
| `__bp_text` | 10 | 1 |
| `__bp_add` | 9 | 5 |

¹ both are unrelated: a comment at `:2507` and an `ast.CallExprOf(.untyped)` type reference at
`:6016`.

`erlang.zig:695` is the only `emitComptimeModule`; `erlang.zig:777` is the single line that puts the
emitter into untyped mode (`em.untyped = comptime_module != null`). `beam_asm.zig` has one public
entry, `codegenEmit` (`:834`), and no comptime shape at all.

The host forms are `erl_ast.Form` values. `erl_ast.Expr` has **27** variants —

```
raw term variable atom lexeme_binary call apply binop unop match tuple list cons map
map_update list_comp case_ fun try_catch bin number paren fun_clauses exception string
fun_ref list_block comment seq
```

— and exactly **one** renderer, `beam/erl_emitter.zig` → Erlang source. `beam/beam_emitter.zig`
renders `Term` (values) and `.S` instructions, never an `erl_ast.Expr`
(`codegen/beam/AGENTS.md`, "Files" table). There is no `erl_ast` → `.S` path and nothing to extend:
it does not exist.

<a id="e12"></a>

## E12 — blast radius on the snapshots

`modules/compiler-core/snapshots/`, 2 529 files:

```
$ grep -rl '^----- COMPTIME ERLANG' snapshots/ | wc -l
48
$ grep -rl '^----- COMPTIME ERLANG' snapshots/ | sed 's|snapshots/||;s|/[^/]*$||' | sort | uniq -c
      7 codegen/beam
      7 codegen/commonJS
      7 codegen/erlang
      7 codegen/wasm
      5 comptime/beam
      5 comptime/erlang
      5 comptime/node
      5 comptime/wasm
$ grep -rl '^----- COMPTIME REPLY' snapshots/ | wc -l
48
$ grep -rl '^----- COMPTIME VALUES' snapshots/ | wc -l
56
```

The **48** `COMPTIME ERLANG` files record the generated module's listing (the lowered body and
`main/0` — `template_eval.zig:161`, `decorator_eval.zig:124`); their `COMPTIME REPLY` twin records
the JSON the runtime answered. The 56 `COMPTIME VALUES` files are the Zig-folded `comptime` values
(`comptime/eval.zig`) and are **not** touched by this front.

No snapshot records a module *atom*: `grep -rl 'template_[0-9a-f]\{16\}' snapshots` → 0 (also
recorded by front 16).

<a id="e13"></a>

## E13 — what is left on disk

Nothing under `.botopinkbuild/tmp/{template,decorator}` is ever deleted, and no loaded module is
ever purged (`persistent_erl.zig:66-76`, no `code:purge/1`):

| Checkout | `tmp/template` | `tmp/decorator` | `.botopinkbuild` |
|---|---:|---:|---:|
| `repository/botopink-lang/modules/compiler-core` | 57 | 68 | 4.3 MB |
| `repository/erika` | 52 | 0 | 1.9 MB |
| `repository/jhonstart` | 10 | 0 | 488 KB |
| `repository/rakun` | 0 | 64 | 740 KB |
| `repository/onze` | 0 | 7 | 192 KB |

The `template_<hash>.erl` count is *cumulative across every build ever run in that directory* — 52
in `repository/erika` against the 12 a single build produces.

<a id="e14"></a>

## E14 — the suite

`zig build test` in the main checkout at `0e5ff66` ran **12.1 s** and ended with

```
failed command: cd …/modules/compiler-cli && ./../../.zig-cache/o/…/test …
```

after the CLI's `loadone-missing` diagnostics. Recorded as **observed, not diagnosed** — it is in
`modules/compiler-cli`, which this front does not own, and the checkout is shared with another
session. It is not a baseline this front may rely on; re-measure before using the suite as a gate.

---

## Reproducing

1. `zig build` in `repository/botopink-lang` (already warm here — 0.025 s).
2. Scratch project: `botopink new <dir>`, then write `src/main.bp` with the template fn above and
   *N* call sites with distinct literals.
3. E-1: time `botopink build --target commonJS` five times, take the minimum.
4. E-2: point the Erlang benchmark at `<dir>/.botopinkbuild/tmp/template`; it consults every
   `.erl`, compiles, loads and calls `main/0`, timing each phase with
   `erlang:monotonic_time(microsecond)`.
5. E-3: find `<dir>/.botopinkbuild/tmp/persistent_erl/<hash>/` and spawn the server with the same
   `argv` as `persistent_erl.zig:211`; write `<u32 BE len><0x01><path>` on its stdin and read the
   reply frame.
6. `.S`: `erlc -S <module>.erl`, then `compile:file("<module>.S", [from_asm, binary, return])`.

Every number drifts with OTP and with the machine. Re-measure before quoting.
