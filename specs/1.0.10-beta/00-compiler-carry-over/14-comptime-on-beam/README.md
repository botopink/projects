# Front 14 — comptime-on-beam

**Priority: first front of the milestone (maintainer).** The reason is not importance, it is what the
other thirteen fronts gain.

> **Every gate in this project today pays, repeatedly, to recompile a program that does not change.**
> On `erika/examples/erika-linq`, `compile:file` inside the resident node costs **942.2 ms of a
> 1 592.4 ms build** while the comptime body it is compiling runs in **0.99 ms** — and every call
> site compiles the *same* program: 200 call sites of one template produce 200 modules and **1**
> distinct body ([E4](./evidence.md#e4--every-call-site-compiles-the-same-program-again)). Fixing
> that makes every other front's `zig build test`, `test-libs` and `gate.sh --cold` faster, which is
> why it goes first.

Steps 0–2 alone remove **95 % of the erl-side cost — 57 % of `erika-linq`'s whole build** — with no
BEAM work at all ([`options.md` § 7](./options.md#7-recommendation)).

## Order

**14 → 13 → the backends.** Decided by the maintainer.

```
14 comptime-on-beam (steps 0–2)        ← this front
      │
      └──► 13 module-identity   half 1: the atom · half 2: policy 3 · half 3: the identity
                                     │                     (02 and 03 stall while 2–3 run)
                                     └──► 02 erlang · 03 beam

            04 js · 05 wasm — in parallel throughout
```

Why this front is ahead of [`../13-module-identity/`](../13-module-identity/README.md) rather than
beside it: they share `buildModule` (`template_eval.zig:329-343`,
`decorator_eval.zig:227-243`). This front's **step 2** makes the comptime module keyed by the
**declaration** instead of by the call site, which is exactly the key 13's step 5
(`erlDeclAtom(owner_path, .tpl, decl_name, hash)`) wants — so 13 inherits the work instead of
competing for the same function. 1.0.4-beta's analysis already recommended that order; it is now
the order.

## Can steps 0–2 run now? — checked file by file against the fourteen-front cut

**Yes, with two named carve-outs and one sequencing choice.** Each row was checked against the new
ownership, not the cut this front was written against.

| File | Whose, in 1.0.5-beta | Verdict |
|---|---|---|
| `src/comptime/template_eval.zig`, `src/comptime/decorator_eval.zig` | **nobody's.** [`../01-checker/`](../01-checker/README.md) carries 1.0.4's front-06 file list — `src/comptime/{infer,types,env,unify,transform,eval,error}.zig` — and **neither evaluator is in it**; they have been unowned since 1.0.2-beta's comptime-dispatch landed | **free.** This front claims them |
| `src/comptime/runtime/persistent_erl.zig` | [`../08-hygiene/`](../08-hygiene/README.md)'s on paper. But 1.0.4's 09 touched it only in its **group E, delivered**, and **none of its open residual rows names the file** — they are the `primitives.d.bp` comment sweep, one `wat_runtime` mention, a fixture rewrite, the `#[@external(node)]` case rule, `docs.md`, and test comments | **cheap carve-out — proposed explicitly here.** This front takes the **eval-protocol half**: two frame commands and a resident prelude |
| the two evaluator call sites in `src/comptime/infer.zig` | [`../01-checker/`](../01-checker/README.md)'s | **named carve-out.** `decoratorEval.evaluate` at **`:2341`** and `templateEval.evaluate` at **`:3522`** (re-located at `c2dd780`; the front was written against `:2341` / `:3475`), plus the memo cache immediately above the template call site |
| `src/codegen/erlang.zig` — `ComptimeModule` / `emitComptimeModule` | [`../02-erlang/`](../02-erlang/README.md)'s | **uncontested under the maintainer's order** — 02 has not opened. A carve-out of disjoint functions if it does |
| `snapshots/codegen/{beam,commonJS,erlang,wasm}/` — 7 `COMPTIME ERLANG` cells each | 02–05's | **28 cells, uncontested for the same reason** |
| `snapshots/comptime/**` — 20 `COMPTIME ERLANG` cells | [`../06-comptime-dedup/`](../../../1.0.5-beta/06-comptime-dedup/README.md) restructures the directory | **sequencing choice, measured below** |

### The one sequencing choice, measured

`snapshots/comptime/` holds four per-backend copies of each slug — `beam` (202 cells), `erlang`
(337), `node` (337), `wasm` (202), plus one `templates/` cell — and **exactly 5 cells in each of the
four carry a `----- COMPTIME ERLANG` section: 20 in total** (measured at `c2dd780`). 06 deletes
3 of the 4 copies per slug.

| Order | Cells this front re-records under `snapshots/comptime/` |
|---|---:|
| **06 first, then 14** | **5** |
| **14 first, then 06** | **20**, of which 06 then deletes 15 |

**The cheaper order is 06 first** — it saves **15 mechanical re-records**. That is the honest
measurement, and it argues against nothing else in this front: 15 cells is a small price against the
schedule reason, so if the maintainer holds 14 at the front of the milestone, pay it. If 06 happens
to be ready first, take it first.

## Step 3 is deferred, and here is the number

**Step 3 (`.S` + `erlc +from_asm`) waits.** Steps 0–2 take `erika-linq`'s erl-side work from
**960 ms to ≈ 49 ms** — 19×, and 911 ms off a 1 592 ms build. Step 3 takes that ≈ 49 ms to
**≈ 11 ms**: a further **38 ms**, which is **≈ 5.6 % of the 681 ms build that remains once steps 0–2
have landed**. Against that marginal 5.6 %:

- **The renderer it needs does not exist.** The 19 template and 6 decorator host functions are
  `erl_ast.Form` values; `erl_ast.Expr` has **27** variants and its only renderer is
  `codegen/beam/erl_emitter.zig` → Erlang source. `codegen/beam/beam_emitter.zig` has never seen an
  `erl_ast.Expr`. There is no `erl_ast` → `.S` path to extend
  ([E11](./evidence.md#e11--the-beam-backend-has-no-comptime-path)) — the step is **≈ 1 500–2 500
  LOC** and a *second* lowering of every comptime construct.
- **It touches `src/codegen/beam_asm.zig`**, which is [`../03-beam/`](../03-beam/README.md)'s and,
  for steps 7–20, [`../13-module-identity/`](../13-module-identity/README.md)'s **wholesale**. Under
  the maintainer's order both of those come after this front, so step 3 cannot be in the same pass.
- **It still needs a maintainer answer** on which reading of the request governs it (the boxed
  question below).

**Recorded: the marginal gain does not justify the dependency now.** Step 3 reopens after 03-beam
closes, with its number re-measured by step 0's script rather than quoted from here.

## Ownership

**Owns:** `src/comptime/template_eval.zig`, `src/comptime/decorator_eval.zig` (unowned through
1.0.4-beta — [`../fronts.md` § Unowned items](../../../1.0.5-beta/fronts.md#unowned-items)) · the eval-protocol half of
`src/comptime/runtime/persistent_erl.zig` (carve-out of
[`../08-hygiene/`](../08-hygiene/README.md)) · a new `src/comptime/runtime/prelude.zig` · the two
`evaluate(…)` call sites and the memo cache of `src/comptime/infer.zig` (carve-out of
[`../01-checker/`](../01-checker/README.md)) ·
`src/codegen/erlang.zig`'s `ComptimeModule` / `emitComptimeModule` (carve-out of
[`../02-erlang/`](../02-erlang/README.md)) and, for the deferred step 3, the untyped comptime mode of
`src/codegen/beam_asm.zig` (carve-out of [`../03-beam/`](../03-beam/README.md)) · the 48
snapshots carrying a `----- COMPTIME ERLANG` section
**Does not touch:** `src/comptime/eval.zig` (the Zig-folded `comptime` values — 56 `COMPTIME VALUES`
snapshots stay put) · `src/comptime/infer.zig` beyond the two `evaluate(…)` call sites (01) ·
`src/comptime/snapshot.zig` ([`../06-comptime-dedup/`](../../../1.0.5-beta/06-comptime-dedup/README.md)) · the module
atoms of `buildModule` ([`../13-module-identity/`](../13-module-identity/README.md) step 5) ·
`src/codegen/runtime.zig` (02, 03), `wat.zig` (05), `commonJS.zig`, `typescript.zig` (04) ·
`libs/std/**` and
`repository/{emilia,erika,jhonstart,onze,rakun}/**` — **no `.bp` changes anywhere**

One residual 1.0.4's hygiene front left **inside this front's files** and could not sweep:
`template_eval.zig` and `decorator_eval.zig` map every transport error to `EvalFailed`, so
`lastTransportError()` is dead and `erl.stderr.log` is shared and best-effort rather than per-spawn.
Step 2 rewrites the frame protocol; it should close that at the same time.

Paths are relative to `repository/botopink-lang/modules/compiler-core/` unless they start with
`modules/`, `libs/` or `scripts/`, which are relative to `repository/botopink-lang/`. Line numbers
and counts read at `botopink-lang` `0e5ff66` (2026-09-17); re-locate by symbol, re-measure before
quoting. Re-checked at `c2dd780` (2026-09-18): the three counts this front is built on are
**unchanged** — 48 `----- COMPTIME ERLANG` sections, 48 `----- COMPTIME REPLY` sections and 56
`----- COMPTIME VALUES` snapshots — against a suite that has grown to 2 573 cells; the `infer.zig`
call sites have drifted to `:2341` and `:3522`.

---

## Landed — steps 0–2 (`bef762b`); step 3 not attempted

Four commits on `fix/comptimebeam`, cold gate green at the head and at each commit.

| Commit | Step |
|---|---|
| `f0ec351` | **0** — `scripts/comptime_bench.sh`, so the cost is measured by the repository instead of quoted from a document |
| `75d4ede` | **1** — the host glue is compiled once at server warmup. `-import`, not a remote call, **so no snapshot body changes**: byte-identical |
| `bee9b85` | **2** — the capture travels as an ETF argument; one module serves every call site of a declaration |
| `19a3b01` | **2 tail** — a broken erl stream says what broke instead of collapsing into `EvalFailed` |

**Measured** — same machine, OTP 29, same command, minimum of 3 builds:

```
BOTOPINK_LIB_ROOTS=../../repository scripts/comptime_bench.sh \
    --n 0,1,10,50,200 --repeat 3 --reps 10 \
    --project ../../repository/erika/examples/erika-linq
```

| | before | step 1 | step 2 |
|---|---:|---:|---:|
| build, N=200 | 6 172 ms | 4 732 ms | **2 172 ms** |
| ms per evaluation | 29.6 | 22.6 | **9.4** |
| `.erl` modules at N=200 | 200 | 200 | **1** |
| `.erl` bytes at N=200 | 2 833 290 | 2 452 690 | **875** |
| in-node `compile:file`, N=200 | 2 024.9 ms | 1 186.6 ms | **3.8 ms** |
| **erika-linq** build | 1 934 ms | 1 669 ms | **645 ms** |
| erika-linq erl side (compile + load) | **1 039.3 ms** | 882.1 ms | **49.0 ms** |

Step 2's acceptance was 960 ms → ≤ 60 ms for erika-linq. **Met: 1 039 → 49, 21×.**

**Two acceptance numbers were not met, with the cause measured**: build N=200 ≤ 600 ms and
≤ 1 ms/evaluation stayed at 2 172 ms / 9.4 ms. One `emitComptimeModule` per evaluation remains — it is
where the module atom comes from — and **each emission re-parses the embedded `primitives.bp` and
`erlang_bifs.d.bp` preludes** (`collectPrimErlangDispatch`, `loadAutoImportedBifsFromPrelude`, both
documented in `erlang.zig` as per-emission throwaway). **16.1 ms per `buildModule`**, measured over 20
calls; this step cut half of it by removing the second rendering. The other half needs a memo inside
`emitErlangModule` — shared body of [`02-erlang`](../02-erlang/README.md), not this front's
`ComptimeModule` carve-out. Reported, not widened.

**Snapshots.** Counts re-measured after `06-comptime-dedup` restructured them (this README said
48/48/56): **33** `COMPTIME ERLANG`, **33** `COMPTIME REPLY`, **47** `COMPTIME VALUES`. Step 1
re-recorded **zero**. Step 2 re-recorded the 33 `COMPTIME ERLANG` cells and nothing else, each diff
confined to the fence and always the same three things: `main() ->` becomes `main({Arg0}) ->` (or
`{Arg0, Arg1, _}` for a decorator), the inline capture map becomes the bound name, and the same term
reappears line for line as `%% Arg0 = …` — so nothing is lost from the record: the capture is the
input half of the evaluation the reply answers.

**Carve-outs used, named in the commits:** 02's `ComptimeModule`/`emitComptimeModule`; 03's
`codegen/beam/{erl_ast,erl_emitter}.zig` — **additive only**, one `Form.import` variant and the arm
that writes it; 08's eval-protocol half of `persistent_erl.zig`; 11's one script. **01's `infer.zig`
was not touched at all** — zero edits, better than the carve-out allowed.

### Step 3 is not attempted, and the reason is measured

- `beam_asm.zig` is **6 401 lines** with **0** occurrences of `ComptimeModule`, `'__bp_len'`,
  `'__bp_json'` or `'__bp_prim_'`. An untyped mode would cross ~80 type-directed sites
  (`string_locals` 22, `isStringExpr` 16, `numKind` 15, primitive dispatch 14, `num_locals` 11,
  `record_fields` 10, `instance_lowerings` 5).
- **The typed beam backend already fails the case the untyped mode exists to serve**:
  `"a b".split(" ").map({ x -> x.toUpper() })` with `--target beam` assembles and dies at run time
  with `{unresolved_method, toUpper, 1}`, while the same straight-line typed code runs. In a comptime
  body **every** receiver is untyped.
- The file belongs to [`03-beam`](../03-beam/README.md) and
  [`13-module-identity`](../13-module-identity/README.md) entirely, and
  [decision 24](../../../1.0.5-beta/decisions-taken.md#24-does-step-3-of-14-comptime-on-beam-happen-at-all) already
  sequences step 3 after them.

**And the value shrank, measured against the post-step-2 build**: erika's 47.7 ms of `compile:file` is
now paid **once per build**, not 18 times, so step 3 would save ≈ 39 ms of a 645 ms build — ≈ 6 %,
which is the front's own ≈ 5.6 % estimate, now confirmed rather than projected.

### Also reported, not done

- `botopink clean` already removed `tmp/template` and `tmp/decorator` — **verified by running it** —
  so [`10-cli-residuals`](../../../1.0.5-beta/10-cli-residuals/README.md)'s `cli/clean.zig` was left untouched.
- The other half of 08's residual (`erl.stderr.log` per cwd rather than per spawn) is recorded as a
  decision in its `AGENTS.md`; overturning a decision is not sweeping.
- **A flat argument whose lexeme carries `\u{…}` stays a literal in the module.** The emitter renders
  it as Erlang's `\x{…}`, which truncates the code point to one byte (`<<"a\x{263A}b">>` is
  `<<97,58,98>>`). Reproducing that here would be a second — and wrong — definition of what a botopink
  string literal is. It belongs to whoever owns `writeBinaryFromLexeme`.

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

¹ the example does not compile at `0e5ff66` — [`../09-ecosystem-residuals/`](../09-ecosystem-residuals/README.md);
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

Step 0 is a prerequisite for every acceptance below. **Steps 0–2 are this front's scope in
1.0.5-beta.** Step 3 is the maintainer's literal request and is **deferred** — the reason, with the
number, is in § *Step 3 is deferred*: it is worth a further ≈ 5.6 % of the build once steps 0–2 have
landed, and it needs a renderer that does not exist plus a file 03-beam and 13-module-identity own. Detail, fallbacks and estimates in [`migration.md`](./migration.md).

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

### Step 3 — the module reaches the node as BEAM assembly — **deferred** (after [`../03-beam/`](../03-beam/README.md) closes, and after the maintainer answers)

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

## Rows for `fronts.md`

Paste-ready; this front edits neither `fronts.md` nor `overview.md`, both of which are the
maintainer's.

### 1. The ownership row

```markdown
| **14** [`comptime-on-beam`](./README.md) | `src/comptime/{template_eval,decorator_eval}.zig` (unowned through 1.0.4-beta) · the eval-protocol half of `src/comptime/runtime/persistent_erl.zig` (carve-out of 08) · a new `src/comptime/runtime/prelude.zig` · the two `evaluate(…)` call sites and the memo cache of `src/comptime/infer.zig` (carve-out of 01) · `ComptimeModule` / `emitComptimeModule` in `src/codegen/erlang.zig` (carve-out of 02) and, for step 3, the untyped comptime mode of `src/codegen/beam_asm.zig` (carve-out of 03) · one new script in `scripts/` (carve-out of 11) | the 48 snapshots carrying `----- COMPTIME ERLANG` in `snapshots/{codegen,comptime}/**` | **first front of the milestone.** Steps 0–2 can start now with two named carve-outs (01's two `infer.zig` call sites; 08's eval-protocol half of `persistent_erl.zig`); **step 3 deferred** until 03 closes, and it needs a maintainer decision |
```

### 2. The conflict notes

```markdown
- **14 × 01 (checker) — a named carve-out, not a wait.** They share `src/comptime/**`, but
  `{template_eval,decorator_eval}.zig` are **not in 01's file list** (`infer`, `types`, `env`,
  `unify`, `transform`, `eval`, `error`) and have been unowned since 1.0.2-beta. What 14 needs from
  01 is two lines: `decoratorEval.evaluate` at `infer.zig:2341` and `templateEval.evaluate` at
  `:3522` (at `c2dd780`), plus the memo cache above the second. **Hand 14 those; do not sequence the
  fronts.**
- **14 × 02 (erlang).** They share `src/codegen/erlang.zig` in disjoint functions: 14 takes
  `ComptimeModule` / `emitComptimeModule`, which 02 has no open row in. 14 also re-records the 7
  `----- COMPTIME ERLANG` cells in `snapshots/codegen/erlang/`, a directory 02 owns — a carve-out,
  or 02 first.
- **14 × 03 (beam).** **Step 3 only, and step 3 is deferred.** It adds an untyped comptime mode to
  `src/codegen/beam_asm.zig` and to `src/codegen/beam/**`, which 03 owns wholesale — and which
  13-module-identity also owns wholesale for its steps 7–20. **Step 3 reopens after 03 closes.**
  Steps 0–2 are unaffected.
- **14 × 04 and 14 × 05.** They share only the 7 `COMPTIME ERLANG` cells in each of
  `snapshots/codegen/{commonJS,wasm}/` — the same generated Erlang recorded beside a JS or wasm
  program. A snapshot carve-out; no source file is shared.
- **14 × 06 (comptime-dedup).** They share `snapshots/comptime/**`. 06 restructures the directory
  (3 of 4 copies deleted); 14 re-records the cells in it that carry a `----- COMPTIME ERLANG`
  section. **Measured at `c2dd780`: 5 per backend directory, 20 in total.** 06 first → 14 re-records
  **5**; 14 first → 14 re-records **20**, of which 06 then deletes 15. **06 first is cheaper by 15
  mechanical re-records**; 14 first is still correct, and that is the price of the schedule.
- **14 × 08 (hygiene) — a free carve-out, measured.** They share
  `src/comptime/runtime/persistent_erl.zig` on paper. **None of 08's open residual rows names that
  file** (they are the `primitives.d.bp` comment sweep, one `wat_runtime` mention, a fixture rewrite,
  the `#[@external(node)]` case rule, `docs.md` and test comments); the only 1.0.4 group that touched
  it, group E, is delivered. 14 takes the **eval-protocol half** — two frame commands and a resident
  prelude — at no cost to 08. 14 should also close the residual 08 left inside 14's own files: the
  dead `lastTransportError()` and the shared `erl.stderr.log`.
- **14 × 13 (module-identity) — 14 runs first, by the maintainer's order.** They share
  `buildModule` in `src/comptime/{template_eval,decorator_eval}.zig`: 13 step 5 changes the module
  atom and threads the owner's path and declaration name through the same function 14 step 2
  restructures. 14 step 2 first makes the module per **declaration**, which is exactly the key 13's
  `erlDeclAtom(owner_path, .tpl, decl_name, hash)` wants, so 13 inherits the work instead of
  competing for it.
- **14 × 09 (ecosystem residuals).** `seq`. The libraries need no source change; their builds get
  faster and their comptime replies must not change. 09 re-runs after 14 lands only to confirm that.
- **14 × 15 (runtime-type-identity).** They share the file `src/codegen/erlang.zig` in disjoint
  functions — 14's `ComptimeModule` / `emitComptimeModule`, 15's value-shape sites — and, for 14's
  step 3, `beam_asm.zig`'s untyped comptime mode against 15's value-shape sites. Their snapshot sets
  are **disjoint, measured**: none of 14's 48 `COMPTIME ERLANG` cells is one of 15's 130. A carve-out
  is defensible; the letter of the front rule sequences them.
- **14 × 07, 10, 11, 12.** `yes` — no shared file and no shared snapshot directory, except the one
  new script in `scripts/` that 11 owns (a carve-out).
```

### 3. The front-table row

```markdown
| [`14-comptime-on-beam`](./README.md) | **first** | steps 0–2 start now (two named carve-outs); step 3 deferred until 03 closes | Comptime evaluation renders an Erlang **source** module per call site and compiles it in the resident node: 8–52 ms of `compile:file` to run a body that takes 0.05 ms, and 200 call sites of one template produce 200 copies of one program. Costs the options — `.S` + `erlc +from_asm`, `.beam` from Zig, one module per declaration — and recommends compiling once per declaration first |
```

### Unowned items this front takes over

```markdown
| ~~`src/comptime/template_eval.zig`, `src/comptime/decorator_eval.zig` (owned by 1.0.2-beta comptime-dispatch, landed)~~ — **claimed by [`14-comptime-on-beam`](./README.md)** | — | — | 14 |
| **The comptime evaluator's compiler-side cost is ≈ 15 ms per evaluation, unattributed** — `buildModule` renders the module twice (`template_eval.zig:333-338`, `decorator_eval.zig:231-236`) and the trace list is passed unconditionally (`infer.zig:3475`, `:2341`); `writeModule` stages and renames a file per evaluation | `src/comptime/{template_eval,decorator_eval}.zig` | 14 comptime-on-beam | 14 step 2, or a profiling follow-up |
| **`TemplateEvalCtx.build_root` is accepted and discarded** (`template_eval.zig:92`, `decorator_eval.zig:74`), so comptime artefacts land under the process's cwd rather than the build root | `src/comptime/{template_eval,decorator_eval}.zig` | 14 comptime-on-beam | 14 step 2, or 08 |
```

### Decisions the maintainer still owes this front

1. **Which reading of the request governs step 3** (§ *The request*, the boxed question). Under the
   adopted reading step 3 extends `beam_asm.zig` with an untyped lowering mode and reuses it. Under
   the second reading — *"the comptime evaluator must not touch `beam_asm.zig`"* — step 3 needs a
   **second** BEAM lowering owned by `src/comptime/`, which this front does not recommend and has
   not costed. Steps 0–2 are unaffected either way, so the answer is only needed before step 3 opens.
2. **Whether step 3 happens at all.** Steps 0–2 remove 95 % of the erl-side cost — 57 % of
   `erika-linq`'s whole build — with no BEAM work
   ([`options.md` § 7](./options.md#7-recommendation)). If the goal is build time, step 3 is
   optional. If the goal is the principle — *no Erlang source in the compile-time path* — it is not.
   Which is it?
3. **The three carve-outs**, each of which decides whether this front can start in parallel:
   `{template_eval,decorator_eval}.zig` plus the `infer.zig` call sites from
   [`../01-checker/`](../01-checker/README.md), the eval-protocol half of `persistent_erl.zig` from
   [`../08-hygiene/`](../08-hygiene/README.md), and `ComptimeModule` / `emitComptimeModule` from
   [`../02-erlang/`](../02-erlang/README.md).
