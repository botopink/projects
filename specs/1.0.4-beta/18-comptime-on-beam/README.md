# Front 18 — comptime-on-beam

**Priority:** high — every build that uses a template or a decorator pays 8–52 ms of Erlang
*compilation* per call site to run a body that takes 0.05 ms, and a `--target commonJS` build fails
without OTP on `PATH`
**Depends on:** [`../12-surface-cutover/`](../12-surface-cutover/README.md) landed (delivered) ·
[`../06-checker/`](../06-checker/README.md), which owns `src/comptime/infer.zig` — this front edits
its two evaluator call sites · **step 3 also depends on
[`../01-backend-residuals/`](../01-backend-residuals/README.md) step 6**, which owns `beam_asm.zig`
**Owns:** `src/comptime/template_eval.zig`, `src/comptime/decorator_eval.zig` (unowned until now —
[`../fronts.md` § Unowned items](../fronts.md#unowned-items)) · the eval-protocol half of
`src/comptime/runtime/persistent_erl.zig` (carve-out of
[`../09-hygiene/`](../09-hygiene/README.md)) · a new `src/comptime/runtime/prelude.zig` ·
`src/codegen/erlang.zig`'s `ComptimeModule` / `emitComptimeModule` (carve-out of 01) · the 48
snapshots carrying a `----- COMPTIME ERLANG` section
**Does not touch:** `src/comptime/eval.zig` (the Zig-folded `comptime` values — 56 `COMPTIME VALUES`
snapshots stay put) · `src/comptime/infer.zig` beyond the two `evaluate(…)` call sites (06) ·
`src/comptime/snapshot.zig` ([`../07-comptime-dedup/`](../07-comptime-dedup/README.md)) · the module
atoms of `buildModule` ([`../16-module-naming/`](../16-module-naming/README.md) step 5) ·
`src/codegen/runtime.zig`, `wat.zig`, `commonJS.zig`, `typescript.zig` (01) · `libs/std/**` and
`repository/{emilia,erika,jhonstart,onze,rakun}/**` — **no `.bp` changes anywhere**

Paths are relative to `repository/botopink-lang/modules/compiler-core/` unless they start with
`modules/`, `libs/` or `scripts/`, which are relative to `repository/botopink-lang/`. Line numbers
and counts read at `botopink-lang` `0e5ff66` (2026-09-17); re-locate by symbol, re-measure before
quoting.

---

## The request, and the reading this front adopts

The maintainer, 2026-09-17, verbatim:

> *"crie outra frente que é para ----- COMPTIME ERLANG não ser feito em erl mais sim em beam e deixa
> o beam só para codegen"*

The first half is unambiguous: **comptime evaluation stops being "render Erlang source, compile it,
load the module" and becomes a BEAM-level path.** The trailing clause reads literally as *"leave BEAM
only for codegen"*, which contradicts it.

**The reading adopted here:** *leave **`erl`** — Erlang **source** — to codegen only. Erlang source
stays a user-facing output target (`--target erlang`) and stops being a compile-time execution
mechanism.* Three reasons:

1. The sentence's own contrast is `erl` **against** `beam` (*"não ser feito em erl mais sim em
   beam"*). The trailing clause reuses `beam` where that contrast requires `erl` — one word, and the
   clause then says exactly what the first half says.
2. Under the literal reading the two halves cancel: the comptime path would have to become BEAM and
   simultaneously not use BEAM. No third mechanism is named.
3. The string the maintainer set off with dashes — `----- COMPTIME ERLANG` — is **verbatim the
   snapshot section name** of the generated Erlang source (48 files,
   [`evidence.md` E12](./evidence.md#e12--blast-radius-on-the-snapshots)). The request names the
   artefact it wants gone, and that artefact is Erlang *source*.

> ### Question for the maintainer
>
> There is a second coherent reading that would change **step 3** and nothing else:
> *"leave the **BEAM backend** (`beam_asm.zig`) to codegen only — do not make the comptime evaluator
> depend on it; build the comptime BEAM path separately."*
>
> Under the adopted reading, step 3 extends `beam_asm.zig` with an untyped lowering mode and reuses
> it. Under this second reading, step 3 would instead need a **second** BEAM lowering owned by
> `src/comptime/`, duplicating `beam_asm.zig` — which this front does not recommend and has not
> costed. If the intent is "the comptime evaluator must not touch `beam_asm.zig`", say so before
> step 3 starts; steps 0–2 are unaffected either way.
>
> A third question, sharper than both: **steps 0–2 remove 95 % of the erl-side cost — 57 % of
> `erika-linq`'s whole build — without any BEAM work at all**
> ([`options.md` § 7](./options.md#7-recommendation)). If the goal is build time, step 3
> is optional. If the goal is the principle — *no Erlang source in the compile-time path* — it is
> not. Which is it?

---

## Problem

A template or a decorator body is turned into an Erlang **source** module, once per call site, and
the resident `erl` compiles it from source before running it.

```
$ botopink build --target commonJS            # 200 call sites of one template fn
   Compiled in 5255.8ms                       # 79.4ms without the template calls
$ ls .botopinkbuild/tmp/template | wc -l
200                                           # 200 modules, 1 distinct program
```

Reproduced and broken down in [`evidence.md`](./evidence.md). Two failures, both measured:

**1. The compiler compiles the same program once per call site.** Across every project sampled, the
generated modules differ **only** inside the capture data literal — 200 modules / 1 distinct body,
18 / 1, 12 / 1 ([E4](./evidence.md#e4--every-call-site-compiles-the-same-program-again)). A
line diff of two of them is 14 lines out of 296, every one a string in the capture.

**2. A JavaScript build needs the Erlang toolchain.**

```
$ env PATH=/empty botopink build --target commonJS
error: the template evaluator failed to run
  --> src/main.bp:10:10
```

([E7](./evidence.md#e7--a-template-makes-a-javascript-build-depend-on-erlang))

## Current state

Measured 2026-09-17, OTP 29 / ERTS 17.0.6, `0e5ff66`. Method and raw output in
[`evidence.md`](./evidence.md); the call path in [`current-path.md`](./current-path.md).

### What one evaluation costs

| | ms | share of a 25 ms evaluation |
|---|---:|---|
| `compile:file` in the node (8.4 ms small body · **52.9 ms** erika's) | 8 – 53 | the Erlang front end, over a program that never changes |
| `code:load_binary` | 1.0 – 1.3 | |
| **`Mod:main()` — the comptime body running** | **0.05 – 0.24** | **0.2 %** |
| frame protocol | ≈ 0.4 | |
| compiler side (renders the module twice, builds the `Term`, stages and renames the file, parses the JSON) | ≈ 15 | 59 % |
| once per compiler process: `erl` spawn + server load | ≈ 145 | (bare VM floor 76 ms) |

### What a real build pays

| Project | evaluations | build | `compile:file` | `load_binary` | **body** |
|---|---:|---:|---:|---:|---:|
| `erika/examples/erika-linq` | 18 | 1 592.4 ms | **942.2 ms** | 16.7 ms | **0.99 ms** |
| `erika` (the library) | 12 | 1 121.8 ms | 629.2 ms | 10.7 ms | 0.63 ms |
| `rakun/examples/rakun` | 16 decorators | — ¹ | 124.6 ms | 5.5 ms | 0.06 ms |
| generated, 200 call sites | 200 | 5 255.8 ms | 1 834.2 ms | 90.1 ms | 0.69 ms |
| generated, 0 call sites | 0 | **79.4 ms** | — | — | — |

¹ the example does not compile at `0e5ff66` — [`../13-ecosystem-migration/`](../13-ecosystem-migration/README.md);
it runs its 16 decorator evaluations before failing, which is what is measured.

### What is left on disk

`.botopinkbuild/tmp/{template,decorator}/*.erl` is never deleted and no loaded module is ever purged
([E13](./evidence.md#e13--what-is-left-on-disk)): `repository/erika` holds **52** template modules
where one build writes 12; `compiler-core` holds 57 + 68 and 4.3 MB.

## Mechanism

`templateEval.evaluate` (`comptime/template_eval.zig:82`) and `decoratorEval.evaluate`
(`comptime/decorator_eval.zig:64`) build an `ast.Program` of one `fn`, attach host glue as
`erl_ast.Form`s, and hand both to `erlang.emitComptimeModule` (`codegen/erlang.zig:695`) — the
ordinary Erlang backend with `em.untyped = true` (`:777`). The result is named
`template_<hash of the code>`, written to `.botopinkbuild/tmp/template/`, and the resident server
does `compile:file` → `code:load_binary` → `Mod:main()` (`persistent_erl.zig:64-80`).

The capture is baked into `main/0` as a **literal map**, so the hash — and therefore the module —
is per call site. A 295-line generated module is 7 lines of body, 54 lines of fixed host functions,
and 230 lines of data ([`current-path.md` § 3](./current-path.md#3-what-the-generated-module-looks-like)).

Full trace, with every `file:line`, in [`current-path.md`](./current-path.md).

## The gap in the BEAM backend

This is the size of the maintainer's literal request, measured
([E11](./evidence.md#e11--the-beam-backend-has-no-comptime-path)).

**`beam_asm.zig` has no comptime path at all.** Occurrences at `0e5ff66`:

| | `erlang.zig` | `beam_asm.zig` |
|---|---:|---:|
| `ComptimeModule` (host enums, host records, extra exports, host forms, the located unsupported-method report) | 10 | **0** |
| untyped lowering mode | 20 | **0** ¹ |
| `'__bp_len'/2`, `'__bp_json'/1` | 11 | **0** |

¹ its two hits are a comment (`:2507`) and an `ast.CallExprOf(.untyped)` type reference (`:6016`).

**The host glue has no BEAM renderer, and never had one.** The 19 template and 6 decorator host
functions are `erl_ast.Form` values. `erl_ast.Expr` has **27** variants; its only renderer is
`codegen/beam/erl_emitter.zig` → Erlang source. `codegen/beam/beam_emitter.zig` renders `Term`
values and `.S` instructions and has never seen an `erl_ast.Expr` (`codegen/beam/AGENTS.md`). There
is no `erl_ast` → `.S` path to extend — it does not exist. **That is why the `.erl` path was chosen
in 1.0.0-beta even though the spec's own diagram drew BEAM bytecode**
([`history.md`](./history.md#the-intent-that-was-never-implemented--and-what-this-front-revives)).

**What the bodies actually need.** The generated modules use map literals and map patterns in
function heads, list comprehensions, `try`/`catch` with an exception pattern, multi-clause functions
with guards, named and anonymous funs, binary construction, `lists:foldl`, and remote calls into
`json`, `maps`, `string`, `io_lib`. `beam_emitter.zig` has instructions for most of the shapes
(`get_map_elements`, `put_map`, `try`/`try_end`/`try_case`, `make_fun3`, `put_list`, `put_tuple2`) —
what is missing is anything that drives them from a comptime body.

**The distinct bodies that would have to lower**, as a progress metric for step 3: **39** template
bodies and **33** decorator bodies in the compiler's own suite; **1** in erika, **1** in erika-linq,
**10** in rakun ([E4](./evidence.md#e4--every-call-site-compiles-the-same-program-again)).

## What "on BEAM" buys, and what it cannot

Five candidates are costed in [`options.md`](./options.md). The two facts that decide it:

**`erlc +from_asm` is worth 3–5×** on every module shape, proven on this project's own generated
module ([E5](./evidence.md#e5--what-each-module-shape-costs), [E8](./evidence.md#e8--erlc-from_asm-assembles-loads-and-runs)):

| | source | `+from_asm` |
|---|---:|---:|
| erika's template, 759 lines | 53.25 ms | **10.21 ms** |
| the small template, 295 lines | 8.47 ms | **2.07 ms** |
| the same body with the host functions resident and the capture as an argument, 14 lines | 1.29 ms | **0.39 ms** |

**Compiling it once instead of once per call site is worth 19×** — more than the assembly change,
and it needs no backend work:

| `erika-linq`, erl-side | compile | load | run | total |
|---|---:|---:|---:|---:|
| today (18 evaluations) | 942.2 ms | 16.7 ms | 0.99 ms | **960 ms** |
| host functions resident, capture as an argument | ≈ 47 ms | ≈ 1.0 ms | 0.99 ms | **≈ 49 ms** |
| the same, plus `.S` `+from_asm` | ≈ 9 ms | ≈ 1.0 ms | 0.99 ms | **≈ 11 ms** |

**And the ceiling, stated plainly:** BEAM bytecode runs on a BEAM VM. *No* option here removes `erl`
from the compile-time dependency surface; they remove the Erlang *compiler*'s work. The only
candidates that would remove the VM — AtomVM in-process, wasm3 — were vendored, tried and deleted by
this project ([`history.md`](./history.md)). This front does not re-propose them.

## Steps

Step 0 is a prerequisite for every acceptance below. Steps 1 and 2 are the recommendation; step 3 is
the maintainer's literal request and is **decided after step 2's numbers land**, because step 2
changes what it is worth. Detail, fallbacks and estimates in [`migration.md`](./migration.md).

### Step 0 — the measurement lives in the repository

A script that generates the N-call-site project, builds it, and prints the breakdown — wall clock,
evaluations, and the in-node `compile:file` / `code:load_binary` / `main()` split over the modules
the build left behind.

**Acceptance:**
- [ ] `scripts/comptime_bench.sh` (or a `modules/compiler-core` test) reproduces
      [E1](./evidence.md#e1--the-comptime-path-costs-25-ms-per-evaluation-linearly) and
      [E2](./evidence.md#e2) on the runner's machine, writing nothing inside a repository
- [ ] Its N=0 / N=200 rows are recorded in this README as the **before** line, re-measured, not
      copied

### Step 1 — the fixed host functions become a resident prelude

The 19 template and 6 decorator host functions, plus `erlang.comptime_helper_forms`, move into one
Erlang module built and loaded at server warmup exactly as `botopink_comptime_server` already is
(hashed directory, `erlc` skipped when warm — `persistent_erl.zig:234-274`). A body calls them
remotely.

**Acceptance:**
- [ ] `compile:file` of the smallest generated module: **8.47 ms → ≤ 1.5 ms** (step 0's script)
- [ ] All **48** `----- COMPTIME REPLY` snapshot sections **byte-identical**; the 48
      `----- COMPTIME ERLANG` sections shrink to the body plus `main/0`, each diff classified in the
      commit message
- [ ] The located "no primitive type and no host function provides `.foo(…)`" diagnostic still
      fires — the negative fixture that today fails `erl_lint` with `{undefined_function, {ref,1}}`
      still produces the compiler's message, not `erl_lint`'s
- [ ] `zig build test` green from a cold cache; `zig build test-libs` green

### Step 2 — the capture becomes an argument; one module per declaration

`main/0` becomes `main/1`; the capture map and the `@Decl` handle travel as Erlang external-term-format
binaries (an encoder over `codegen/beam/term.zig`, **not** source text re-parsed in the node —
that is the `'__bp_erl_eval'/2` shape, measured at ≈ 50× a direct call in
`codegen/beam/AGENTS.md`). The module's content hash is taken over the code **without** the data, so
one module serves every call site of a declaration. The frame protocol gains cmd 2 (*compile and load,
answer the module atom*) and cmd 3 (*call `Mod:main(Term)`*); **cmd 1 stays** as the fallback and for
the existing regression tests (`persistent_erl.zig:445-485`).

**Acceptance:**
- [ ] `erika/examples/erika-linq` erl-side: **960 ms → ≤ 60 ms**, measured with step 0's script
- [ ] The generated N-call-site project's slope: **≈ 25 ms → ≤ 1 ms per evaluation**; N=200 build
      **5 255 ms → ≤ 600 ms**
- [ ] `.botopinkbuild/tmp/template/` holds **one** `.erl` per template declaration after a build of
      `erika-linq`, not 18
- [ ] All 48 `COMPTIME REPLY` sections byte-identical
- [ ] A fixture for each shape that must survive the term round trip: a holed template
      (`${…}` parts), an `@ExprCustom` return with its reference tree, a decorator whose `@Decl`
      handle carries fields, methods, variants and annotations
- [ ] `botopink clean` removes `tmp/template` and `tmp/decorator` (`cli/clean.zig`)
- [ ] `zig build test` green from a cold cache; `test-libs` green

### Step 3 — the module reaches the node as BEAM assembly (after 01 step 6, and after the maintainer answers)

`beam_asm.zig` gains what `erlang.zig:777` gates: an untyped lowering mode, host records and host
enums without declarations, and a `main/1` entry. The reply encoder and the capture API are already
resident after step 1, so **no host function needs a `.S` form**. `writeModule` writes `<module>.S`;
cmd 2 learns `[from_asm]`.

**The `.erl` path stays, per declaration, as the fallback** — a body the BEAM path cannot lower
falls back instead of failing. The fallback rate is the step's progress metric.

**Acceptance:**
- [ ] erika's single compile: **47.3 ms → ≤ 12 ms**
- [ ] All 48 `COMPTIME REPLY` sections byte-identical; the `COMPTIME ERLANG` sections become
      `COMPTIME BEAM ASSEMBLY`, 48 files, classified as a rename in the commit message
- [ ] `scripts/beam_export_audit.sh` still 295/295
- [ ] The count of distinct bodies lowering on beam is recorded: *N of 39 template and M of 33
      decorator bodies in the suite*; every fallback names the construct in
      `src/codegen/beam/AGENTS.md`
- [ ] No `.erl` is written for a declaration the BEAM path lowered

### Step 4 — not proposed, recorded

`.beam` written by Zig, and a BEAM VM that is not `erl`. Both costed and declined in
[`options.md`](./options.md#2-option-b--emit-beam-bytecode-from-zig) and
[`history.md`](./history.md). Recorded so the next reader does not re-derive them.

**Acceptance:**
- [ ] No row of this front proposes either; the reasons are cited, not restated

## Gate

- [ ] `scripts/gate.sh --cold` green in this front's worktree (zig build · cold `zig build test` ·
      `test-bpmp` · beam export audit · `test-cli` · `test-libs` · `test-language`)
- [ ] The **48** `----- COMPTIME REPLY` sections byte-identical at every step — the reply is the
      assertion; the listing is not
- [ ] The 56 `----- COMPTIME VALUES` snapshots untouched (`comptime/eval.zig` is not this front's)
- [ ] Every re-recorded `COMPTIME ERLANG` listing classified in the commit message (shrink /
      rename / lowering change), never bulk-accepted
- [ ] Each step's number re-measured with step 0's script and written into this README
- [ ] `AGENTS.md` updated in the same commit for `src/comptime/`, `src/comptime/runtime/`,
      `src/codegen/` and `src/codegen/beam/`; `meta:architecture.md`'s "O que roda onde" table names
      the new shape (it currently says a module is generated and executed per evaluation)
- [ ] Commit on `fix/comptime-on-beam-<step>`; no push, no merge

## Blast radius

| What moves | Size |
|---|---:|
| snapshots recording the generated Erlang (`----- COMPTIME ERLANG`) | **48** of 2 529 — 7 each in `codegen/{beam,commonJS,erlang,wasm}`, 5 each in `comptime/{beam,erlang,node,wasm}` |
| snapshots recording the reply (`----- COMPTIME REPLY`) | 48 — **must not move** |
| snapshots of Zig-folded comptime values (`----- COMPTIME VALUES`) | 56 — **not this front's** |
| compiler source | step 1 ≈ 250 LOC · step 2 ≈ 500 LOC · step 3 ≈ 1 500–2 500 LOC |
| `.bp` source anywhere | **none** |
| libraries that get faster | `erika` (12 evaluations/build), `erika-linq` (18), `jhonstart` (10), `rakun` (16 decorators), `onze` (7) |

The risk worth naming: **step 3 is a second lowering of every comptime construct.** Today one
emitter (`erlang.zig`, untyped mode) decides what a comptime body means; step 3 adds a second in
`beam_asm.zig`, and the two can diverge silently because the `COMPTIME ERLANG` listing stops being
the same language. The `COMPTIME REPLY` snapshots are the only cross-check, which is why they are a
gate line and not a step-3 line.

The other risk: **the front's own numbers date fast.** Every figure here is OTP 29 on one Linux
machine; step 0 exists so the next reader re-measures instead of quoting.

## Notes

- **The body is not slow.** On `erika-linq` the comptime work — a SQL lexer, a parser and a dual
  lowering — runs in **0.99 ms**. Everything else is the cost of getting it into the VM.
- **The resident node must stay.** A bare `erl -noshell -eval 'halt().'` is 76.3 ms; the server pays
  for itself after the second evaluation ([E3](./evidence.md#e3--the-server-round-trip-measured-from-outside-the-compiler)).
  Spawning `erlc` per evaluation is strictly worse than the node — 96.5 ms out of process against
  9.3 ms in it ([E8](./evidence.md#e8--erlc-from_asm-assembles-loads-and-runs)).
- **There is no in-memory `from_asm`.** `compile:file(File, [from_asm])` reads the `.S` through
  `beam_consult_asm`; the consulted terms fed to `compile:forms/2` are rejected
  ([E9](./evidence.md#e9--from_asm-in-memory-is-not-a-documented-path)). The `.S` reaches OTP as a
  file, exactly as the `.erl` does today — no new cost, but it means the module cannot be streamed
  over the frame protocol.
- **`+no_postopt` is not a shortcut.** The residue under `+from_asm` is `beam_validator` and
  `beam_asm`, not the assembly-level optimisers ([E5](./evidence.md#e5--what-each-module-shape-costs)).
- **This front finishes an abandoned design, it does not revive a discarded one.** The 1.0.0-beta
  spec that created this runtime drew `.bp → beam_asm.zig → BEAM bytecode → resident erl` and shipped
  `.erl` instead, because the host glue had an Erlang-source renderer and no `.S` one. The
  designs this project *did* discard — AtomVM in-process, wasm3 — are option E and are not proposed
  ([`history.md`](./history.md)).
- **`zig build test` in the main checkout at `0e5ff66` ended with a `modules/compiler-cli` failure**
  after 12.1 s ([E14](./evidence.md#e14--the-suite)). Observed, not diagnosed; it is not this
  front's file and the checkout is shared. Re-measure before treating the suite as a baseline.

---

## Rows to add to `fronts.md` and `overview.md`

Paste as-is; this front does not edit either file.

### `overview.md` — the front table

```markdown
| [`18-comptime-on-beam`](./18-comptime-on-beam/README.md) | high | not started — needs a maintainer decision on step 3 | Comptime evaluation renders an Erlang **source** module per call site and compiles it in the resident node: 8–52 ms of `compile:file` to run a body that takes 0.05 ms, and 200 call sites of one template produce 200 copies of one program. Costs the options — `.S` + `erlc +from_asm`, `.beam` from Zig, one module per declaration — and recommends compiling once per declaration first |
```

### `overview.md` — the Order diagram

```markdown
12 surface-cutover (alone) ──► 06 checker ──► 01 steps 5–6 ──► 08 wave A
                                   │                │
                                   ├──► 07 comptime-dedup ──► 08 wave B
                                   ├──► 16 module-naming (codegen atom sites + CLI output layout)
                                   └──► 18 comptime-on-beam steps 0–2 ──► step 3 (after 01 step 6)
```

### `fronts.md` — Ownership

```markdown
| **18** [`comptime-on-beam`](./18-comptime-on-beam/README.md) | `src/comptime/{template_eval,decorator_eval}.zig` (previously unowned) · the eval-protocol half of `src/comptime/runtime/persistent_erl.zig` (carve-out of 09) · a new `src/comptime/runtime/prelude.zig` · `ComptimeModule` / `emitComptimeModule` in `src/codegen/erlang.zig` and, for step 3, the untyped comptime mode of `src/codegen/beam_asm.zig` (carve-outs of 01) · one new script in `scripts/` (carve-out of 05) | the 48 snapshots carrying `----- COMPTIME ERLANG` in `snapshots/{codegen,comptime}/**` | not started — steps 0–2 after 12; step 3 after 06 and 01 step 6, and needs a maintainer decision |
```

### `fronts.md` — Conflict matrix

Add an `18` column and row; the existing rows gain one cell each.

```markdown
|  | 01 (5–6) | 06 | 07 | 08 | 09 | 12 | 13 | 14 | 16 | 17 | 18 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **01 (5–6)** | — | no¹ | yes | no⁴ | no⁵ | no⁶ | seq⁷ | seq⁷ | no⁹ | yes¹² | no¹³ |
| **06** | no¹ | — | no³ | no⁴ | no⁵ | no⁶ | seq⁷ | seq⁷ | no¹⁰ | yes¹² | no¹⁴ |
| **07** | yes | no³ | — | no⁴ | no⁵ | no⁶ | seq⁷ | seq⁷ | yes | yes | no¹⁵ |
| **08** | no⁴ | no⁴ | no⁴ | — | no⁵ | no⁶ | seq⁷ | seq⁷ | no⁴ | yes | no⁴ |
| **09** | no⁵ | no⁵ | no⁵ | no⁵ | — | no⁶ | no⁸ | no⁸ | no⁵ | yes | no¹⁶ |
| **12** | no⁶ | no⁶ | no⁶ | no⁶ | no⁶ | — | no⁸ | no⁸ | no⁶ | no⁶ | no⁶ |
| **13** | seq⁷ | seq⁷ | seq⁷ | seq⁷ | no⁸ | no⁸ | — | yes | seq¹¹ | yes | seq¹⁸ |
| **14** | seq⁷ | seq⁷ | seq⁷ | seq⁷ | no⁸ | no⁸ | yes | — | yes | yes | yes |
| **16** | no⁹ | no¹⁰ | yes | no⁴ | no⁵ | no⁶ | seq¹¹ | yes | — | yes | no¹⁷ |
| **17** | yes¹² | yes¹² | yes | yes | yes | no⁶ | yes | yes | yes | — | yes |
| **18** | no¹³ | no¹⁴ | no¹⁵ | no⁴ | no¹⁶ | no⁶ | seq¹⁸ | yes | no¹⁷ | yes | — |
```

New notes:

```markdown
13. **01 × 18 share `src/codegen/erlang.zig` and, for 18's step 3, `src/codegen/beam_asm.zig` and
    `src/codegen/beam/**`.** 18 takes `ComptimeModule` / `emitComptimeModule` as a carve-out for its
    steps 1–2, which 01 has no open row in; step 3 adds an untyped comptime mode to `beam_asm.zig`
    and must run **after 01 step 6**. 18 also re-records the 7 `----- COMPTIME ERLANG` snapshots in
    each of the four `snapshots/codegen/` directories 01 owns.
14. **06 × 18 share `src/comptime/infer.zig`.** 18 edits two call sites (`:2341`, `:3475`) and the
    memo cache around `:3447-3472`; 06 owns the file. 18 after 06, or the maintainer hands 18 those
    lines as a carve-out.
15. **07 × 18 share `snapshots/comptime/**`.** 07 restructures the directory (3 of 4 copies
    deleted); 18 re-records the 20 files in it that carry a `----- COMPTIME ERLANG` section. Either
    order works, not both at once.
16. **09 × 18 share `src/comptime/runtime/persistent_erl.zig`.** 09 owns it; 18 adds two frame
    commands and a resident prelude to it. 18 after 09's remaining steps, or the maintainer hands 18
    the eval-protocol half as a carve-out — 09's open rows (2, 4, 5, 5.4) are elsewhere.
17. **16 × 18 share `buildModule` in `src/comptime/{template_eval,decorator_eval}.zig`.** 16 step 5
    changes the module atom and threads the owner's path and declaration name through the same
    function 18 restructures (it stops being per call site). Sequence them: 16 step 5 after 18
    step 2 is the cheaper order — 18 makes the module per declaration, which is exactly the key 16's
    `erlDeclAtom(owner_path, .tpl, decl_name, hash)` wants.
18. **13 × 18.** The libraries need no source change; their builds get faster and their comptime
    replies must not change. 13 re-runs after 18 lands only to confirm that.
```

### `fronts.md` — Unowned items (rows this front takes over or hands back)

```markdown
| ~~`src/comptime/template_eval.zig`, `src/comptime/decorator_eval.zig` (owned by 1.0.2-beta comptime-dispatch, landed)~~ — **claimed by [`18-comptime-on-beam`](./18-comptime-on-beam/README.md)** | — | — | 18 |
| **The comptime evaluator's compiler-side cost is ≈ 15 ms per evaluation, unattributed** — `buildModule` renders the module twice (`template_eval.zig:333-338`, `decorator_eval.zig:231-236`) and the trace list is passed unconditionally (`infer.zig:3475`, `:2341`); `writeModule` stages and renames a file per evaluation | `src/comptime/{template_eval,decorator_eval}.zig` | 18 comptime-on-beam | 18 step 2, or a profiling follow-up |
| **`TemplateEvalCtx.build_root` is accepted and discarded** (`template_eval.zig:92`, `decorator_eval.zig:74`), so comptime artefacts land under the process's cwd rather than the build root | `src/comptime/{template_eval,decorator_eval}.zig` | 18 comptime-on-beam | 18 step 2, or 09 |
```
