> Carried from `specs/1.0.5-beta/14-comptime-on-beam/options.md`, status at carry (2026-09-20): steps 0–2 landed (`bef762be`); step 3 is C-20, after C-01 (decisions 24 and 62)

# Options — what "comptime on BEAM" can mean

Five candidates, measured against the same question: **what does it remove from a build, and what
does it cost to build?** Numbers from [`evidence.md`](./evidence.md); the recommendation is § 7.

One fact frames all of them. Per evaluation today, the comptime *body* runs in **0.05–0.24 ms**;
the Erlang compiler spends **8–52 ms** producing the module that carries it, and `code:load_binary`
spends **1.0–1.3 ms** installing it ([E2](./evidence.md#e2), [E5](./evidence.md#e5)). The evaluator
is not slow at evaluating. It is slow at **compiling the same program once per call site**
([E4](./evidence.md#e4--every-call-site-compiles-the-same-program-again)).

---

## 0. The shape shared by every option

Whatever the module is made of, something has to **run** it, and BEAM bytecode runs on a BEAM VM.
So:

> **"Comptime on BEAM" can remove the Erlang *compiler* from a build. It cannot remove the BEAM
> *VM*.** The `erl` process stays in every option below. Only option (e) removes it, and (e) has
> been discarded twice — see [`history.md`](./history.md).

That is the honest ceiling. A commonJS-only user stops needing `erlc`-shaped work at compile time
but still needs `erl` on `PATH` ([E7](./evidence.md#e7--a-template-makes-a-javascript-build-depend-on-erlang)).

---

## 1. Option A — emit `.S`, let `erlc +from_asm` assemble it

The BEAM backend's existing output is BEAM assembly (`.S`), not bytecode. The comptime module would
be produced by `beam_asm.zig` instead of `erlang.zig`, written as `.S`, and the server would
`compile:file(Path, [from_asm, binary, return])` instead of `compile:file(Path, [binary, return])`.

**What exists.** `codegen/beam_asm.zig` (6 369 LOC) lowers a botopink program to `.S`;
`codegen/beam/beam_emitter.zig` renders every operand and instruction; `scripts/beam_export_audit.sh`
already assembles all 295 recorded beam modules with `erlc +from_asm`; `codegen/runtime.zig:638`
already invokes `erlc +from_asm` for the snapshot harness. The mechanics are proven end to end on a
module this project generates ([E8](./evidence.md#e8--erlc-from_asm-assembles-loads-and-runs)):

```
$ erlc -S big.erl                      # 759 lines of Erlang → 2132 lines of .S
$ erlc +from_asm big.S                 # → big.beam, 12712 bytes, 97 ms out of process
$ erl -noshell -pa . -eval 'R = big:main(), io:format("~s~n",[string:slice(R,0,90)]), halt().'
{"source":"of(erikaCities).where({ row -> row.pop >= __bp_hole_q_0 && row.pop <= __bp_hole
```

**What it is worth.** 3–5× off the in-node compile, on every module shape
([E5](./evidence.md#e5--what-each-module-shape-costs)):

| | source | `+from_asm` |
|---|---:|---:|
| erika's template (759 lines) | 53.25 ms | **10.21 ms** |
| the small template (295 lines) | 8.47 ms | **2.07 ms** |
| the narrowed module (14 lines) | 1.29 ms | **0.39 ms** |

`+no_postopt` buys nothing — the residue is `beam_validator` and `beam_asm`, not the optimisers.

**What is missing — and it is the whole of the front.** `beam_asm.zig` has **no comptime path at
all** ([E11](./evidence.md#e11--the-beam-backend-has-no-comptime-path)):

| Piece `erlang.zig` has | Occurrences in `erlang.zig` | in `beam_asm.zig` |
|---|---:|---:|
| `ComptimeModule` (host enums, host records, extra exports, host forms, the unsupported-method report) | 10 | **0** |
| untyped lowering mode (`em.untyped`) | 20 | **0** |
| `'__bp_len'/2`, `'__bp_json'/1` | 11 | **0** |

and the host glue is **`erl_ast.Form`**, a 27-variant Erlang code model whose only renderer is
`beam/erl_emitter.zig` → Erlang source. `beam/beam_emitter.zig` renders `Term` values and `.S`
instructions and has never seen an `erl_ast.Expr`. There is no `erl_ast` → `.S` path to extend.

So option A needs, in order:

1. the 19 template + 6 decorator host functions to stop being `erl_ast` and become something the
   BEAM backend can lower (either botopink source compiled by `beam_asm.zig`, or a **resident
   prelude** compiled once and called remotely — option C);
2. an untyped lowering mode in `beam_asm.zig`, mirroring the 20 decisions `erlang.zig:777` gates,
   including `'__bp_add'`/`'__bp_len'` dispatch and the located `unsupported_method` report;
3. host records and host enums (`Span`, `CustomNode`, `Binding`, `Source`, `Context`, `DeclKind`,
   `BindingKind`) lowered without declarations;
4. every construct the generated bodies use, in `.S`: map literals and map patterns in function
   heads, list comprehensions, `try`/`catch` with an exception pattern, multi-clause functions with
   guards, named funs, binary construction, `lists:foldl` with a fun, remote calls into `json`,
   `maps`, `string`, `io_lib`. The BEAM emitter has instructions for most of this
   (`get_map_elements`, `put_map`, `try`/`try_end`/`try_case`, `make_fun3`, `put_list`,
   `put_tuple2` — `codegen/beam/AGENTS.md`), but nothing drives them from an `erl_ast` tree.
5. `writeModule` writing `<module>.S` and the server learning a second command.

**In-memory assembly is not available.** `compile:file(File, [from_asm])` reads the `.S` through
`beam_consult_asm`; the consulted terms handed to `compile:forms/2` are rejected, and a hand-rolled
regrouping into the internal 5-tuple is also rejected
([E9](./evidence.md#e9--from_asm-in-memory-is-not-a-documented-path)). Not a blocker — the evaluator
already writes a file — but the `.S` cannot be streamed over the frame protocol as a term.

**Dependency surface removed:** none. `erl` stays; the Erlang *compiler* is still the thing that
turns `.S` into bytecode, it just runs 3–5× less of itself.

---

## 2. Option B — emit `.beam` bytecode from Zig

No Erlang toolchain in the compile-time path at all: the compiler writes a loadable `.beam` and the
node only does `code:load_binary/3`.

**What exists.** `codegen/beam/beam_emitter.zig` knows the *shape* of BEAM instructions well enough
to spell them as `.S` text, and `beam/term.zig` is a complete BEAM value model. Nothing encodes.

**What is missing.** A `.beam` this project's own path produces carries thirteen chunks
([E10](./evidence.md#e10--what-a-beam-actually-contains)):

```
AtU8  Code  StrT  ImpT  ExpT  LitT  Meta  LocT  Attr  CInf  Dbgi  Line  Type
```

`Code` is the compact-term-encoded instruction stream; `AtU8`/`ImpT`/`ExpT`/`LocT`/`LitT` are the
tables it indexes. In OTP 29 that machinery is 1 662 LOC of Erlang — `beam_asm.erl` 875,
`beam_dict.erl` 390, `beam_opcodes.erl` 397 with **192** opcodes, and `beam_opcodes.erl` is
regenerated by `beam_makeops` **for every release**. Reimplementing it in Zig means owning a
per-OTP-release opcode table and a bytecode encoder with no validator in front of it — today
`erlc +from_asm` runs `beam_validator_weak` before `beam_asm`, and a mis-encoded module is a VM
crash rather than a diagnostic.

**What it is worth.** Over option A, and **after** the module is compiled once per declaration
(option C), it saves 0.39 ms per template *declaration*. Per evaluation it saves nothing at all:
`code:load_binary` is unchanged at ≈ 1.0 ms, and that is the floor either way.

**History says no.** The 1.0.0-beta spec that created this runtime is explicit —

> **Important:** do NOT write raw BEAM assembly in Zig. The host layer only manages the subprocess
> lifecycle and communicates via the line protocol. All Erlang/BEAM code is generated by the
> existing `beam_asm.zig` codegen backend (comptime vals) or `erlang.zig` backend
> (templates/decorators).
> — `botopink-lang` `specs/1.0.0-beta/persistent-erl-runtime.md`, Step 2 (in history; see
> [`history.md`](./history.md))

That decision was about the *host layer*, not about the backend, so it does not forbid option B
outright — but it is the same instinct, and nothing has changed to justify reversing it: the
measured payoff of B over A is ≈ 0.4 ms per template declaration.

**Dependency surface removed:** the Erlang *compiler* leaves the compile-time path entirely. `erl`
stays.

---

## 3. Option C — keep the resident node, feed it a module compiled once

Not "assembled instead of source" — **compiled once instead of once per call site**. Three changes,
none of them in a backend:

1. **The 19 + 6 host functions move into a resident prelude module**, compiled and loaded at server
   warmup exactly like `botopink_comptime_server` itself (hash-keyed directory, `erlc` once, skipped
   when warm — `persistent_erl.zig:234-274`). A body calls them as `bp_prelude:text(Q)`.
2. **The capture / `@Decl` handle stops being a literal and becomes an argument**: the per-eval
   module exports `main/1`, and the term travels over the frame protocol.
3. **The module is keyed by the template *declaration*, not the call site** — the Wyhash is taken
   over the code without the data, so the node compiles and loads it once and every later call is a
   frame that names an already-loaded module and carries a term.

The protocol grows two commands beside cmd 1: *load this module* and *call `Mod:main(Term)`*.

**What it is worth**, measured by building exactly that shape by hand
([E5](./evidence.md#e5--what-each-module-shape-costs)):

| | today | prelude + argument | + `.S` `+from_asm` (option A on top) |
|---|---:|---:|---:|
| small template, compile | 8.47 ms | **1.29 ms** | 0.39 ms |
| erika's template, compile | 53.25 ms | 47.28 ms | 9.33 ms |
| `.beam` size, small | 8 624 B | 1 068 B | 904 B |

and the compile happens **once per declaration** rather than once per call site:

| `erika/examples/erika-linq` | compile | load | run | total erl-side |
|---|---:|---:|---:|---:|
| today (18 evaluations) | 942.2 ms | 16.7 ms | 0.99 ms | **960 ms** |
| option C | ≈ 47 ms | ≈ 1.0 ms | 0.99 ms | **≈ 49 ms** (**19×**) |
| option C + A | ≈ 9 ms | ≈ 1.0 ms | 0.99 ms | **≈ 11 ms** (**87×**) |

The premise is measured, not assumed: across every project sampled, the code before `main/0` is
identical for every call site of a template — 200 modules / **1** distinct body, 18 / **1**,
12 / **1** ([E4](./evidence.md#e4--every-call-site-compiles-the-same-program-again)).

**What is missing.**

- An encoder for the capture/handle `Term` as something the node can read as a term. Erlang's
  external term format is the natural answer (`binary_to_term/1`), ≈ 200–300 LOC over the existing
  `beam/term.zig` model — atoms, binaries, small/large integers, floats, lists, tuples, maps. It
  must **not** be re-rendered as Erlang source and `erl_eval`'d: that path is measured at ≈ 50× a
  direct call (`codegen/beam/AGENTS.md`, `'__bp_erl_eval'/2`).
- Plain arguments must travel as terms too. They already resolve to values only — binary, atom,
  integer, float or character list (`comptime/template.zig:154-166`) — so they can.
- The trace/listing snapshots change shape (48 files, [E12](./evidence.md#e12--blast-radius-on-the-snapshots)).
- `writeModule`'s per-evaluation staged write and rename disappears for the common case (one write
  per declaration).

**Dependency surface removed:** none. But `erlc` is invoked once per *server-source hash*, not per
build, which is already true today.

---

## 4. Option D — cache the compiled module across builds

Orthogonal and cheap: key a `.beam` on disk by the same content hash and `code:load_binary` it
instead of recompiling. It does not remove `code:load_binary`'s ≈ 1.0 ms, and `read_file +
load_binary` measures 1.083 ms against 1.034 ms for load alone — the disk is free, the load is not.

Worth ≈ 8 ms per *first* evaluation of a body, nothing on later ones, and it adds a cache-invalidation
surface (OTP version, prelude version) for a win option C already contains. **Not recommended
on its own**; it falls out of option C for free if the per-declaration `.beam` is kept in
`.botopinkbuild/`.

---

## 5. Option E — a BEAM VM that is not `erl`

The only option that would remove `erl` from the compile-time dependency surface. Both known
candidates are already discarded in this project's history ([`history.md`](./history.md)):

| Candidate | Status | Why |
|---|---|---|
| **AtomVM in-process** | vendored, partially implemented, then reverted (1.0.0-beta, Steps 1–4 of the original spec) | needs estdlib bundling, a stdout dup/pipe shim in C FFI, NIF registration for the descriptor walkers, no Windows platform layer, ~40 C sources, and a segfault kills the compiler |
| **wasm3 + WAT comptime** | vendored, shipped, then deleted | replaced by this very runtime; `modules/wasm3/` and the WAT prelude were removed in the same spec |

Re-proposing either needs a named change in the facts. There is none. **Not proposed.**

---

## 6. Comparison

| | A `.S` + `from_asm` | B `.beam` from Zig | C compile once per declaration | D disk cache | E non-`erl` VM |
|---|---|---|---|---|---|
| per-evaluation erl cost | 2.07 ms + 1.0 load | 1.0 load | **0.05–0.24 ms**, no load | 1.0 load | — |
| `erika-linq` erl-side | ≈ 200 ms | ≈ 20 ms | **≈ 49 ms** | ≈ 940 ms | — |
| with C on top | ≈ 11 ms | ≈ 2 ms | — | — | — |
| removes `erlc`-shaped work | partly (3–5×) | **yes** | no (but runs it 18× less) | first build only | yes |
| removes `erl` | no | no | no | no | **yes** |
| new compiler code | untyped `.S` mode + host forms in `.S` (≈ 1 500–2 500 LOC) | that **plus** a BEAM encoder (OTP's own is 1 662 LOC, per-release) | prelude + ETF encoder + 2 protocol commands (≈ 400–600 LOC) | ≈ 100 LOC | a vendored VM |
| risk | a second lowering of every comptime construct diverging from the erlang one | a mis-encoded module is a VM crash, not a diagnostic | the reply shape and the 48 listing snapshots move | cache invalidation | discarded twice |
| blocked by | the `erl_ast` → `.S` gap | option A, plus B's own encoder | nothing | nothing | the record |

---

## 7. Recommendation

**Do C first, then decide whether A is still worth doing.**

1. **C is where the measured cost is.** The build does not pay 25 ms per evaluation because the
   module is Erlang source rather than BEAM assembly; it pays because it compiles the *same* module
   once per call site. `erika-linq` loses 95 % of its comptime cost to C alone, with no backend work
   and no second lowering of the language.
2. **A on top of C is worth ≈ 38 ms per template declaration** (47.28 → 9.33 ms) and costs the whole
   `erl_ast` → `.S` gap: an untyped lowering mode in `beam_asm.zig` and a `.S` form for every host
   function. That is a large, duplicating investment for a number that C has already made small.
   It is worth doing only if the goal is stated as *"no Erlang source in the compile-time path"* —
   a principle — rather than as a build-time target.
3. **B is not recommended.** Over A it saves ≈ 0.4 ms per declaration and buys a per-OTP-release
   opcode table plus an unvalidated encoder. The project already wrote down "do NOT write raw BEAM
   assembly in Zig", and nothing measured here argues for reversing it.
4. **E is not proposed.** Discarded twice; nothing has changed.

The staged plan, with what proves each stage and what the fallback is, is
[`migration.md`](./migration.md).
