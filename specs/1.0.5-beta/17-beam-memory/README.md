# Front 17 — beam-memory

**Decided 2026-09-18.** Every question this front opened is answered —
[38 to 44](../decisions-taken.md), plus three the same pass raised and answered: **48** (the
formatter's `var` arm is a named carve-out of `16`, landed here in the same commit as the form),
**49** (this front opens once [`01-checker`](../01-checker/README.md) has committed its step 4) and
**50** (this milestone runs steps 0–3b; steps 4–8 become a spec for the milestone after
[`13`](../13-module-identity/README.md)). **51** answers the one sub-question this design
raised: `keyed = true` is a **`Dict`-only** argument — a `List<T>` under `Ets` stores its whole value, and
`keyed` on one is decision 41's "needs a keyed container" error. Nothing of this front is open; the one
question left from that pass, [52](../decisions-pending.md), belongs to the loop lowering.

**Priority:** high — and startable the moment decision 49's condition is met. The reason it was not
startable before is the finding this front rests on.
A module-level `var` is [decision 28](../decisions-taken.md#28-what-decision-14-left-unassigned)'s
last unlanded half; [`15-language-surface`](../15-language-surface/README.md) measured it and
deliberately did not implement it ("the grammar is trivial; the semantics are the `@BeamMemory`
design"). The semantics are here. What the measurement added is that the carrier cannot land alone:
a module binding that is *assigned* produces broken output on **all three** runnable targets today,
and the compiler says nothing.

**Depends on:** [`13-module-identity`](../13-module-identity/README.md) (it owns `erlang.zig` and
`beam_asm.zig` **wholesale** for its second and third halves — step 4 and step 5 here cannot run
beside it), and a **named carve-out of [`01-checker`](../01-checker/README.md)** for two diagnostics
in `src/comptime/infer.zig`. Steps 0–1 depend on nothing and can start immediately. **Question 43 is answered: two layers** — see
[The two layers](#the-two-layers). The ten host primitives live in `libs/std/src/beam.bp` as
`#[@External.Erlang]` and the core only lowers a binding's read and write onto them, so no line of
`.zig` names ETS, `persistent_term` or the process dictionary. Off the BEAM the **annotation** is a
silent no-op while a hand-written `import { beam } from "std"` stays `std-unsupported-on-target` — the
tension the option came with, decided as (a).

**Owns:** `modules/compiler-core/src/parser.zig`'s top-level declaration dispatch — `:436` (the
`checkShorthand(.val)` arm), `:445-458` (the annotated-declaration lookahead and its `switch`) and
`:531` (`parseValForm`); **not** the `ParseErrorType` enum at `:61-158`, which is
[`15`](../15-language-surface/README.md)'s · the `ValDecl` struct in `src/ast.zig` (`:1891-1909`) —
two new fields, disjoint from the member-trivia fields
[`16-formatter`](../16-formatter/README.md) owns · two named diagnostics in
`src/comptime/infer.zig` beside the record-field rule at `:2742` (carve-out of
[`01`](../01-checker/README.md)) · the top-level-`val` emission site of each backend, one function
each: `commonJS.zig:438` + `buildValDecl` ([`04`](../04-js/README.md)), `wat.zig:2104`
(`emitGlobalVal`) ([`05`](../05-wasm/README.md)), `erlang.zig:3205-3229` (`topValForms`,
`topValEntryExpr`) ([`02`](../02-erlang/README.md) / [`13`](../13-module-identity/README.md)) and the
matching site in `beam_asm.zig` ([`03`](../03-beam/README.md) / [`13`](../13-module-identity/README.md))
· a new `Form` variant in `src/codegen/beam/erl_ast.zig` (`:252-266`) and its arm in
`erl_emitter.zig` · new cases in `src/parser/tests/**` (carve-out of
[`07`](../07-review-backlog/README.md))

**Does not touch:** `docs.md` ([`08`](../08-hygiene/README.md) — this front supplies the text) ·
`tests/language/**` ([`12`](../12-language-tests/README.md) — this front specifies the cells) ·
`libs/std/**` — **including the new `libs/std/src/beam.bp` of step 3b** — and
`repository/{emilia,rakun}/**` ([`09`](../09-ecosystem-residuals/README.md); steps 3b and 8 are
*specification*, not edit) · `src/format.zig`
([`16`](../16-formatter/README.md) — `var` needs a printer arm) · `src/comptime/infer.zig` beyond the
two named diagnostics ([`01`](../01-checker/README.md)) · the module atoms of `buildModule`
([`13`](../13-module-identity/README.md))

**The two exceptions decision 48 and decision 49 write into the lists above.** `src/format.zig` moves
from *does not touch* to a **named carve-out**: one `ValDecl` printer arm reading the new `mutable`
field and one `assertLossless` case, in the same commit that makes `var` parse — because `16-formatter`
has landed (`37d3dc7`) and `09-ecosystem-residuals` has already committed the five libraries formatted,
so an arm arriving one commit late edits committed files. And the `infer.zig` carve-out is granted
**after** `01`'s step 4 is committed, not before: that front holds +208/−23 uncommitted lines in the
same file, beside the same `:2742`.

Paths are relative to `repository/botopink-lang/` unless a row says otherwise. Every count and
`file:line` below was measured on 2026-09-18 at `botopink-lang` `bef762b`, in a detached scratch
worktree — never in `repository/botopink-lang`, never in `.tasks/`. The Erlang numbers are OTP 29 /
erts 17.0.6, the node numbers node v25.8.0, the wasm numbers wasmtime 45.0.0, on a 16-core machine.

---

## Problem

**A module-level binding that is assigned compiles clean and breaks on every target.** This program
passes `botopink check` at `bef762b`:

```botopink
val hits: i32 = 0;
pub fn bump() { hits = hits + 1; }
pub fn main() { bump(); bump(); @print(hits); }
```

| target | emitted | what running it does |
|---|---|---|
| commonJS | `const hits = 0;` (`out/main.js:32`) then `hits = (hits + 1);` (`:35`) | `TypeError: Assignment to constant variable.` |
| erlang | `hits() -> 0.` then `bump() -> Hits = (Hits + 1).` | `main.erl:9:13: variable 'Hits' is unbound` — **the module does not compile** |
| wasm | `(global $hits i32 (i32.const 0))` then `global.set $hits` | `Invalid input WebAssembly code at offset 168: global is immutable: cannot modify it with 'global.set'` |

It is the shape [decision 37](../decisions-taken.md#37-is-a-record-immutable) found for record fields —
checker accepts, backends disagree in the worst available way — one level up, and **still open**: the
rule decision 37 landed covers `p.f = v` only. `val x: i32 = 0; x = 1;` inside a `fn` passes too. The
only immutability diagnostic in the compiler is `infer.zig:2742`
(`a 'Person' is immutable — its field 'age' cannot be assigned`), and it fires on records.

So `var` at module level is not "add a keyword". It is the decision that makes `val` mean something,
on a surface where three backends already emit code that cannot run.

**And the payoff is measured, not asserted.** `rakun/src/runtime.mjs` is 231 lines, and
`rakun/AGENTS.md:22` says why — *"botopink has no top-level mutable state, so the registries those
calls"* (the sentence starts at `:21`). Counted registry by registry, **96 of the 231 lines are
registry maintenance** and 135 are host binding that stays:

| registry | lines | `runtime.mjs` | write pattern | mode |
|---|---:|---|---|---|
| `scanned` | 17 | `:16-32` | once at load (decorator-emitted) | `PersistentTerm` |
| `building` + `builds` | 31 | `:33-63` | repeatedly at run time | `Ets` |
| `singletons` | 16 | `:64-79` | repeatedly at run time | `Ets` |
| `props` | 19 | `:80-98` | at bootstrap | `PersistentTerm` |
| `routes` | 13 | `:107-108`, `:113-123` | once at load (decorator-emitted) | `PersistentTerm` |

Of `runtime.bp`'s **16** `@External.Node` declarations, **13** exist only to reach a registry; the
three that stay (`dispatch`, `dispatchHttp`, `serve`) carry real host behaviour. That is the size of
[decision 17](../decisions-taken.md#17-rakuns-erlang-story)'s container-and-router half, and this front
is what makes it portable instead of ported.

## Current state

| | Value |
|---|---|
| `var` at module level | `error: this token cannot appear here … ^^^ unexpected 'var'` at `1:1` |
| `#[…]` before a top-level `val` | `error: … ^ unexpected '#'` at `1:1` — the annotated-declaration `switch` (`parser.zig:450`) has no `.val` arm |
| `#[@BeamMemory.Ets(keyed = true)]` on a `fn` | **parses** — `Checked in 60.93ms` |
| an unknown builtin annotation (`#[@TotallyMadeUp.Nonsense(whatever = 42)]`) | **parses and checks**, silently |
| `ast.ValDecl` fields | 7; **no `mutable`, no `annotations`** (`ast.zig:1891-1909`) |
| `ast.Stmt.Kind.localBind` | **has `mutable: bool`** (`ast.zig:563`) and `commonJS.zig:2366` already reads it |
| purity analysis in `src/comptime/**` | **none** — `EffectKind` (`ast.zig:2014`) is `result\|future\|generator\|iterator\|asyncGenerator\|context`, the declared return wrappers |
| erlang forms available | `erl_ast.Form` (`:252-266`) = `module\|exports\|import\|no_auto_import\|function\|comment\|blank` — **no attribute form**, so no `-on_load` |
| erlang expressions available | `erl_ast.Expr` (`:18-74`) already has `case_`, `try_catch`, remote `call`, `atom`, `tuple` — the guarded-init shape needs no new node |
| wasm mutability | `wat_ast` already has `mutable: bool` (`wat/wat_ast.zig:216`); `emitGlobalVal` (`wat.zig:2104`) sets it on 3 of 5 paths. The two that do not are `:2112` and `:2134` — the two that break |
| JS mutability | `js_ast.Decl.Kw` (`js/js_ast.zig:324-334`) has `const_` and `let_`; `kw = .let_` appears **nowhere in production codegen** — only in `js_emitter.zig:712`, a test |

## The design this front implements

The full argument, with its evidence, is [`design.md`](./design.md) beside this file. The closed
decisions:

- The family is **`@BeamMemory`**, BEAM-specific; on commonJS and wasm the annotation is a **no-op**,
  because their execution context is already the whole program.
- A bare module `var` is **one value per execution context** — on the BEAM, the **process**.
- Three members: **`ProcessDict`** (default), **`Ets`**, **`PersistentTerm`**.
- `keyed` is an **argument of the member** — `#[@BeamMemory.Ets(keyed = true)]` — optional, default
  **`false`**.
- Under `Ets`, a missing table is **re-created and re-seeded from the declaration**, silently, with a
  `try` around `ets:new` for the creation race.
- Cluster state is **out**: an explicit `libs/std` type with a declared consistency model, not a
  fourth member.

**Three measurements this front brings back that the design has to absorb.** They are written up as
questions 39, 40 and 41 below; none of them reopens a decision, and one of them says a decision does
not have the effect it was taken for.

1. **`-on_load` cannot create an ETS table.** It runs in a temporary process: `persistent_term`
   written there survives the load (`101` and a routes map readable afterwards), an ETS table does
   not (`ets:whereis` → `undefined` immediately). So on erlang, `Ets` has **no load-time moment** and
   the first caller creates the table.
2. **Which makes the silent re-init behave as `ProcessDict`.** Five request processes × 3 increments
   each; each read `3`; after 15 increments the counter reads **0**. `ets:info(…, owner)` confirms the
   re-creating process becomes the new owner. With a module-emitted registered owner (~15 lines of
   Erlang: `register/2` + `ets:new(…, {heir, Pid, …})` + `give_away`) the same test reads **15**.
3. **`ets:update_counter` covers integers only.** `{ok, 1}` for `i32`/`i64`; `{error, badarg}` for
   `f64` (with increment `1.0` *and* `1`), `bool` and binary. So the rule "`+=` is atomic, `hits =
   hits * 2 + 1` is not" holds for integers and for nothing else.
4. **Most of this does not belong in the core at all** — see [The two layers](#the-two-layers), which
   is a maintainer question (43) and changes what this front owns.

And two costs worth stating before any code is written, both measured over 2 000 000 operations:

| operation | ns/op |
|---|---:|
| a module `val` **as lowered today** (0-arity fn returning a literal) | 2.23 |
| `ets:lookup_element`, no guard | 15.38 |
| `ets:lookup_element` behind `ets:whereis` | 29.76 |
| `ets:update_counter`, no guard | 21.05 |
| `ets:update_counter` behind `ets:whereis` | 35.63 |
| `persistent_term:get` through a 0-arity fn | 17.53 |
| `persistent_term:put` | 810 |

The `whereis` guard is **+94 %** on a read and **+69 %** on an increment (re-measured in a second
program: 14.84 → 29.59 ns, **+99.4 %**). It is 15 nanoseconds and nobody will notice; it is also the
operation. The design may not describe it as free.

And the `keyed` default, measured rather than reasoned:

| `Dict` size | `keyed = false` | `keyed = true` | ratio |
|---:|---:|---:|---:|
| 10 | 254 ns/write | 51 ns/write | 4.9× |
| 1 000 | 25 190 ns/write | 47 ns/write | **537×** |
| 10 000 | 301 864 ns/write | 60 ns/write | **5 061×** |

Two processes writing **different keys** 20 000 times each under `keyed = false` finished at
`a => 19994`, `b => 20000`: **six writes lost**, silently.

## The two layers

**Most of this front does not have to be in the compiler, and the maintainer asked whether it should
be.** Measured, the answer splits the design in two — which is a better factoring than a full builtin
and the reason step 3b exists.

**The precedent is already in the tree.** `libs/std/src/erlang.bp` (170 lines, `pub mod erlang;` at
`libs/std/src/root.bp:30`) is a **target-specific std module** whose body is a table of
`#[@External.Erlang("erlang", "<symbol>")] pub declare fn …`, and the erlang emitter **parses it at
compile time and derives emission from it** — `codegen/erlang.zig:184-260`,
`loadAutoImportedBifsFromPrelude`, whose own comment reads *"To add / remove / update a BIF: edit
`libs/std/src/erlang.bp`. No `.zig` recompile of the table itself is needed."* The target reaches
comptime already (`env.zig:542`, `target: ?[]const u8`, one of `"commonJS"|"erlang"|"beam"|"wasm"`)
and already produces a working diagnostic — measured:

```
error: std-unsupported-on-target: std/erlang.abs has no `@external` for target 'node'
```

*On the name:* the precedent is `std/<name>` and the import that resolves is `import { erlang } from
"std"` (measured). The spelling `erlang.bp`'s own header documents — `import {…} from "std/erlang"` —
**does not resolve** (measured: an unresolved-import warning, which is
[`10-cli-residuals`](../10-cli-residuals/README.md)'s defect). Since the family already covers both
BEAM targets, the sibling module is **`std/beam`**, not `std.erlang`.

**What the library-decorator mechanism can and cannot do**, all measured by reading it:

| | |
|---|---|
| a decorator is recognised **by the shape of its first parameter**, never by name | `infer.zig:583` `isDecoratorParams`; registered at `:618` |
| a lowercase library-style annotation already parses | measured: `#[beamMemory.ets(keyed = true)]` on a `fn` checks clean |
| the reflection handle is **read-only** | `builtins.d.bp:416`, `:467-480`; `decorator_eval.zig:37-49` |
| `DeclKind` is `Type \| Behavior \| Fn \| Method \| Field` — **no `Val`** | `builtins.d.bp:424-430`; and `ValDecl` (`ast.zig:1891-1909`) and `ImplementDecl` (`:2369-2388`) have no `annotations` field at all |
| the only output is `Outcome.ok`, a list of `@emit`ted sources | `decorator_eval.zig:57-64`; `emit` merely appends a source string (`comptime/runtime/prelude.zig:190-193`) |
| contributions are **appended**, never substituted | `comptime.zig:306-316` `spliceContributions`, `:329-344` `parseAndMergeContributions` |
| a decorator body **cannot see the target** | `grep target decorator_eval.zig` → 0; the context is `TemplateEvalCtx{ io, build_root }` (`env.zig:198-201`) |

**And one nuance that cuts the other way.** `@emit` produces source text that is re-parsed by the
ordinary parser, so a decorator can emit a `declare fn` already carrying **both**
`#[@External.Erlang(…)]` and `#[@External.node(…)]` — the per-target choice is then made downstream by
the emitter, which matches `External.<Target>` by literal prefix (`ast.zig:1279-1282`, `:2140-2143`).
That is emilia's shape (`emilia.bp:23-30`). So a decorator **does not need** to see the target; it
emits both arms. What it cannot do is *become* a new target-dispatch mechanism, and it cannot rewrite
how an existing declaration is emitted — which is precisely `@BeamMemory`'s job, since `hits` must
read as `ets:lookup_element` and `hits += 1` must write as `ets:update_counter`, at sites spread
through the module that only the emitter sees.

**So:** layer 1 (the host primitives) is `libs/std/src/beam.bp` and needs **no `.zig`**; layer 2 (the
lowering of a binding's reads and writes onto them) is irreducibly core, and is all this front should
own of it. Under that split the compiler learns **three mode names and how to lower a read and a
write** — and learns nothing about ETS, `persistent_term` or the process dictionary. Question 43.

---

## Steps

**Scope, by decision 50.** Steps **0, 1, 2, 3 and 3b** run in 1.0.5-beta. Steps **4 to 8** — the three
modes' emission, the registered ETS owner, the recomposition and post-load diagnostics, the cells and
the rakun migration — become a spec for the milestone after `13-module-identity`, which owns
`erlang.zig` and `beam_asm.zig` wholesale for the halves they need and has not started. Their text
below stands as written; what changes is when they open. The consequence, said out loud: the 96 lines
of `rakun/src/runtime.mjs` this front promised to remove leave with steps 4–8, not with this wave.

**Two rows the answers rewrite.** Step 1's migration-cost box is **measured and zero** — 82 assignments
to a bare name over `libs/std`, `examples/**` and the five libraries, all 82 to a name the same file
declares `var`, zero to a `val` (decision 38); and step 3 validates the **three** members —
`ProcessDict`, `Ets`, `PersistentTerm` — plus the argument names, which is decision 41 and matches what
this README already answered: the explicit `ProcessDict` is the default said out loud.

### Step 0 — Re-run every measurement at this front's HEAD, and open the five questions

Nothing is edited. The probe harness is one scratch project per form (`botopink new`, one `src/main.bp`,
`botopink check` / `build --target …`), plus three hand-written Erlang modules compiled with `erlc`
and run with `erl -noshell`.

**Acceptance:**
- [ ] The three broken emissions of [Problem](#problem) reproduce at HEAD, each with its exact
      first diagnostic line and the emitted line that produced it
- [ ] Questions **38–43** are opened in [`decisions-pending.md`](../decisions-pending.md) in the
      Measured / Options / Recommendation / Blocks shape, numbered from 38 as that file requires
- [ ] The 96-line rakun count and the emilia reading are re-derived at the libraries' current
      submodule pointers, with the function ranges named — not carried from this README

### Step 1 — `var` parses at module level, and `val` starts meaning what it reads as

Two changes that must land together, because either alone is worse than neither.

1. **The carrier.** A `.@"var"` arm beside `checkShorthand(.val)` (`parser.zig:436`), `.val` added to
   the annotated-declaration `switch` (`parser.zig:450`) so an annotation has somewhere to land, and
   `mutable: bool` + `annotations: []Annotation` on `ast.ValDecl` (`ast.zig:1891`). The precedent is
   already written: `ast.zig:563` gives `localBind` a `mutable` field and `commonJS.zig:2366` reads it
   to pick `let` over `const`. This is the module-level `var` being the local `var` one level up.
2. **The rule.** Assigning to a `val` — local or module-level — is a located error naming `var`,
   emitted beside decision 37's record-field diagnostic at `infer.zig:2742`. **Carve-out of
   [`01-checker`](../01-checker/README.md), named and granted or this step does not open.**

**Acceptance:**
- [ ] `var hits: i32 = 0;` at module level parses; `#[@BeamMemory.Ets] var hits: i32 = 0;` parses
- [ ] `val x: i32 = 0; x = 1;` is a located error naming `var`, in a `fn` body **and** at module level
- [ ] The migration cost is counted the way decision 37 counted its own: `grep` for assignments to a
      `val` over `libs/std`, `examples/**` and the five libraries, with the number in the commit
      message. **Unmeasured today** — decision 37 found 0 field assignments; this is a different query
- [ ] `expectError(src, kind, line, col)` cases in `src/parser/tests/**` (carve-out of
      [`07`](../07-review-backlog/README.md))
- [ ] `scripts/gate.sh --cold` green, and **no snapshot re-records**: every program this step changes
      the meaning of is a program that does not compile today

### Step 2 — commonJS and wasm carry a module `var`, before any BEAM decision is taken

The two targets the annotation does not touch are the two that cost under ten lines, so the language
becomes coherent on two targets while the BEAM questions are still open.

- **commonJS**: `buildValDecl` (reached from `commonJS.zig:438`) picks `kw` from the new `mutable`
  field, exactly as `commonJS.zig:2366` already does for a local.
- **wasm**: `emitGlobalVal` (`wat.zig:2104`) sets `.mutable = true` on the folded-numeric path
  (`:2112`) and the `numberLit` path (`:2134`) when the declaration is a `var`. The field exists
  (`wat/wat_ast.zig:216`); three of the five paths already set it.

**Acceptance:**
- [ ] The [Problem](#problem) program, rewritten with `var`, prints `2` on node and `2` under
      `wasmtime` — the value verified by running it, not read off the emitted code
- [ ] `val` at module level still emits `const` / an immutable global — step 1's rule is what makes
      that safe
- [ ] Re-recorded snapshots in `snapshots/codegen/commonJS/**` and `snapshots/codegen/wasm/**` are
      classified one by one; a `var` appearing in a cell is a cell step 1 just made legal
- [ ] Carve-outs from [`04`](../04-js/README.md) and [`05`](../05-wasm/README.md), one function each

### Step 3 — The annotation is validated, or it is worse than nothing

`#[@TotallyMadeUp.Nonsense(whatever = 42)]` passes `check` today, measured. So the day the carrier
lands, `#[@BeamMemory.Etz]` and `#[@BeamMemory.Ets(keyd = true)]` compile, run, and leave the `var` in
the default mode with nothing said. This is the failure mode
[decision 15](../decisions-taken.md#15-a-lower-case-externalnode-) already named for `#[@external]`
("passes `check`, binds no host, and says nothing") — and here it is worse, because a misread memory
annotation does not fail, it **moves where the state lives**, and step 4's measurement shows
`ProcessDict` and `Ets` are indistinguishable in a single-process test.

`parser.zig:900` already lands the member in the annotation's `name` (`"BeamMemory.Ets"`) and
`parser.zig:962` already accepts `keyed = true` as a labelled argument whose value falls through
positionally. Nothing in the grammar changes; the validation is a lookup.

**Acceptance:**
- [ ] `#[@BeamMemory.<anything else>]` is a located error naming the three members
- [ ] An unknown argument name under a known member is a located error naming `keyed`
- [ ] `keyed` on anything but a `Dict` is a located error — there is no key (decision 51: scalars **and**
      `List<T>`)
- [ ] A `reject/` cell per diagnostic, specified here and handed to
      [`12-language-tests`](../12-language-tests/README.md)

### Step 3b — `std/beam`: the host primitives leave the core

**Blocked on question 43**, and on nothing else — it edits no compiler file. `libs/std/**` is
[`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md)'s under
[decision 17](../decisions-taken.md#17-rakuns-erlang-story), so this front **specifies** the module
and 09 lands it.

A new `libs/std/src/beam.bp` + `pub mod beam;` in `libs/std/src/root.bp`, built the way
`libs/std/src/erlang.bp` already is: `declare fn`s carrying `#[@External.Erlang(…)]` templates, one
per host operation — `pdGet` / `pdPut` / `pdErase`, `etsInit` / `etsGet` / `etsPut` / `etsBump`,
`ptGet` / `ptPut`. **The whole of the design's §6 lives here as template text** — the
`case ets:whereis`, the `try ets:new`, and the registered owner of question 39 — editable without
recompiling the compiler, which is the property `erlang.zig:184-260`'s comment claims for the BIF
table.

**Acceptance:**
- [ ] `import { beam } from "std"` resolves and each declaration is reachable on `erlang` and `beam`
- [ ] On `commonJS` and `wasm` the module reds `std-unsupported-on-target` — the existing gate, not a
      new one. **Note the tension to settle with the maintainer:** the design says the *annotation* is
      a **no-op** off the BEAM, while the std module is a **hard error** there. Both are defensible;
      they must not be decided separately
- [ ] The guarded-init and the owner shapes are byte-compared against the Erlang programs step 0
      measured, and re-run under `erl`
- [ ] **Not** a `.zig` line: if layer 1 needs one, that is the finding, and it goes back to question 43

### Step 4 — erlang: three modes, and the owner question answered first

**Blocked on [`13-module-identity`](../13-module-identity/README.md)** — it owns `erlang.zig` wholesale
for its second and third halves — and on **question 39**, because the answer decides whether the
emitter writes a process.

**If question 43 answers (b)**, most of what follows is *calls into `std/beam`* rather than shapes
built in Zig, and this step shrinks to the read/write lowering. The shapes below are what has to
exist somewhere either way.

What the machine already has: `erl_ast.Expr` (`:18-74`) carries `case_`, `try_catch`, remote `call`,
`atom` and `tuple`, so the guarded-init shape needs no new expression node. What it does not have:
`erl_ast.Form` (`:252-266`) is `module | exports | import | no_auto_import | function | comment |
blank`, so `-on_load(F/0).` needs a **new variant** and its `erl_emitter.zig` arm. And the entry point
is `topValForms` (`erlang.zig:3205`), whose comment states today's lowering — *"A module-level `val`
is a 0-arity function"* — which re-evaluates the initialiser on **every read**: measured,
`val seeded: i32 = registry();` emits `seeded() -> registry().` and `reader() -> seeded().`

| mode | emission | load moment |
|---|---|---|
| `PersistentTerm` | `persistent_term:put({Mod, Name}, Init)` from `-on_load`, `persistent_term:get/1` per read | **works** — measured surviving the temporary loader process |
| `ProcessDict` | `put/2`, `get/1` with the declaration's value as the `undefined` default | none needed |
| `Ets` | the `whereis`-guarded `case` + `try ets:new` of the design, plus whatever question 39 answers | **none exists** — measured |

**Acceptance:**
- [ ] For each mode, one fixture whose emitted `.erl` is compiled with `erlc` and run with `erl`, and
      whose RUN LOG is the value the program actually printed
- [ ] `PersistentTerm`: a `var` written after load is a located error, with the hint naming
      `#[@BeamMemory.Ets(keyed = true)]`. Second reason, measured: `-on_load` **re-runs on every code
      reload**, so a runtime write is erased by the next hot reload (`999` → `101` after
      `code:load_file/1`)
- [ ] `Ets`: the five-request test of question 39 is a fixture, and it reads **15**, not `3` and `0`
- [ ] `+=` lowers to `ets:update_counter` for `i32`/`i64` and is **refused** for every other type
      (question 40), with `hits = hits + 1` recognised as the same form
- [ ] The initialiser rule is `ast.Expr.isComptimeExpr()` (`ast.zig:218`) plus the literal path — **not
      purity**, which is not decidable: `EffectKind` (`ast.zig:2014`) is the declared return wrappers,
      and `fn registry() -> i32 { @print("side effect"); return 7; }` used as a module initialiser
      passes `check` today
- [ ] No use of `ets:update_counter`'s `{Pos, Incr, Threshold, SetValue}` form. It works (measured:
      `2147483647 + 1` → `-2147483648`) and it would make `Ets` diverge from the erlang backend's own
      `i32`, which does not wrap: `var n: i32 = 2147483647; n = n + 1;` prints `2147483648` on erlang
      **and** on node, and `-2147483648` on wasm. That divergence is pre-existing and not this front's

### Step 5 — beam: the same three modes in assembly

**Blocked on [`03-beam`](../03-beam/README.md) closing and on
[`13-module-identity`](../13-module-identity/README.md)**, which owns `beam_asm.zig` wholesale for
steps 7–20.

Measured: the beam target lowers a module `val` to the **same** 0-arity function
(`{function, seeded, 0, 5}` → `{call, 0, {f, 3}}`) and opens the file with `{attributes, []}.`, so the
`-on_load` attribute has a slot and it is empty. Each mode becomes a short run of
`{call_ext, N, {extfunc, ets, …}}` and the guard becomes labels. **Not measured:** how much of
`beam_asm.zig`'s existing machinery covers a two-arm `case` over `ets:whereis`; the step must
re-measure before it is sized.

**Acceptance:**
- [ ] Each mode's beam fixture is byte-compared against the erlang fixture's *behaviour*, not its
      text: same program, same printed value, run under `erl`
- [ ] `{attributes, [{on_load, [{'__bp_load', 0}]}]}` emitted for a module carrying a
      `PersistentTerm` var, and the `.S` loads

### Step 6 — The diagnostics and the documentation text

This front writes no `docs.md`; it supplies the text to [`08-hygiene`](../08-hygiene/README.md).

**Acceptance:**
- [ ] One paragraph per mode, each carrying the sentence the measurement forces:
      `Ets` is cache and counting memory, not where the truth lives · under `keyed = false` a `Dict`
      is stored as **one** value and concurrent writes to different keys are lost (with the 19 994 /
      20 000 figure) · a `PersistentTerm` var is re-seeded on every code reload
- [ ] The `keyed`-on-a-`Dict` warning of question 42, **if** the warning channel exists — measured:
      `grep -rn warning src/comptime/*.zig` → 0, which
      [`decisions-pending.md`](../decisions-pending.md) already records as a defect with no owner. If
      it does not exist, the sentence goes to `docs.md` and this box is struck with that reason

### Step 7 — The language cells

Specified here, written by [`12-language-tests`](../12-language-tests/README.md).

**Acceptance:**
- [ ] One `test/` cell per mode per BEAM target, plus one for a bare `var` on all four
- [ ] One `reject/` cell per diagnostic of steps 1, 3 and 4
- [ ] Every cell that runs on erlang or beam has a RUN LOG produced by running it

### Step 8 — The payoff, specified for `09-ecosystem-residuals`

This front does not edit a library. It writes the migration and hands it over.

**Acceptance:**
- [ ] **rakun**: the mode per registry and the line ranges that go
      (`runtime.mjs:16-32`, `:33-63`, `:64-79`, `:80-98`, `:107-123` = 96 lines) and the 13 of 16
      `@External.Node` declarations in `runtime.bp` that go with them — handed to
      [`09`](../09-ecosystem-residuals/README.md) and registered against
      [decision 17](../decisions-taken.md#17-rakuns-erlang-story)
- [ ] **emilia** is the validation case for `ProcessDict`, not an entry of this front:
      `emilia/src/emilia.bp:23-25` (`get` + `lists:keystore` + `put`) and `:27-30` (`erase`) are a
      read-modify-write and a reset over one key, `'__emilia_sheet'`, whose scope is per-process **on
      purpose** (`emilia.bp:3-8`). `erase` is **not** a blocker: both readers guard
      `case … of undefined -> []; X__ -> X__ end`, so absent and `[]` are indistinguishable and
      `sheet = []` reproduces it. The blocker is that the value is a host list of 2-tuples with
      `keystore` upsert semantics, which needs an ordered dict in `libs/std` — decision 17's half,
      not this one's

---

## Blast radius

- **Step 1 is the only step that changes the meaning of a program that compiles today** — the `val`
  assignment rule. Every other step accepts something that is a parse error or a broken emission now.
- **No snapshot directory is shared with a concurrent front**, provided steps 4 and 5 run after
  [`13`](../13-module-identity/README.md). Steps 2's re-records are in
  [`04`](../04-js/README.md)'s and [`05`](../05-wasm/README.md)'s directories and are a carve-out.
- **`expected-failures.txt`.** Nothing here deletes a line; step 7 adds cells.
  [`12`](../12-language-tests/README.md)'s step 1 re-points the 54 first.

## Notes

- **The grammar was never the problem.** `#[@BeamMemory.Ets(keyed = true)]` already parses on a `fn`
  at `bef762b`. What does not exist is a declaration that can carry an annotation *and* a mutable
  value. Sizing this front as "a parser change plus three erlang lowerings" gets the first half right
  and the second half backwards.
- **The two targets the annotation does not touch are the cheap ones.** commonJS is a `Kw` field that
  already exists and is never used in production codegen; wasm is two `.mutable = true`. That is what
  makes step 2 possible before any BEAM question is answered, and it is the strongest argument for
  splitting this front at step 2 rather than shipping it whole.
- **The design's `Ets` is the half that has to be defended.** Questions 39 and 40 are both about it,
  the 62 of rakun's 96 lines that only `Ets` can take are both about it, and the measurement says the
  mode as designed degrades into the mode it exists to replace. If question 39 is answered (b) — no
  owner process — this front should say so and drop `Ets`, not ship a cache that always misses.
- **The core does not have to learn what ETS is.** `libs/std/src/erlang.bp` is the proof that a
  target-specific std module can drive emission, and the emitter's own comment says its table is
  editable without a `.zig` recompile. Everything the design's §6 describes — the guard, the `try
  ets:new`, the owner — is template text that belongs in `libs/std/src/beam.bp`. What cannot move
  is the read/write lowering, and that is one sentence of core, not a subsystem.
- **Not done here:** typing the annotation into anything ([`01`](../01-checker/README.md)), the
  `libs/std` ordered dict emilia needs ([`09`](../09-ecosystem-residuals/README.md) under decision 17),
  `docs.md` ([`08`](../08-hygiene/README.md)), the formatter arm that prints `var` and the annotation
  back ([`16`](../16-formatter/README.md) — without it `botopink format` deletes them, which is the
  exact defect 16 found in `pub default mod`).

## Decisions the maintainer owes

| # | Question | Blocks | This front's recommendation |
|---|---|---|---|
| 38 | **Is a `val` immutable?** `val x: i32 = 0; x = 1;` passes `check` in a `fn` and at module level; at module level it emits code that throws on node, does not compile on erlang and does not validate on wasm | step 1, and therefore the whole front | **yes** — the same decision as 37, one level up. Without it `var` means nothing, because `val` already allows assignment |
| 39 | **Who creates the ETS table the first time?** `-on_load` runs in a temporary process, so it cannot (measured: `whereis` → `undefined`); `persistent_term` written there survives. With the first caller creating it, 5 requests × 3 increments read `3, 3, 3, 3, 3` and the counter ends at **0**; with a module-emitted registered owner (~15 lines) it ends at **15** | step 4, step 5; 62 of rakun's 96 lines | **emit the registered owner**, and keep the silent re-init as the safety net the maintainer decided on. They do not compete: the guard's `undefined` arm becomes "register an owner" instead of "become the owner" |
| 40 | **`+=` under `Ets` on a non-integer.** `ets:update_counter` answers `{ok,1}` for `i32`/`i64` and `{error, badarg}` for `f64`, `bool` and binary, so rule 5(b) ("`+=` is atomic, `hits = hits * 2 + 1` is not") is true for integers only | step 4; the `docs.md` text | **refuse `+=` under `Ets` when the type is not an integer**, with 5(b)'s diagnostic. One checker line, and it keeps the promise 5(b) makes; allowing it makes 5(b) a rule the author cannot predict from what they wrote |
| 41 | **Is a misspelled `@BeamMemory` an error?** `#[@TotallyMadeUp.Nonsense(whatever = 42)]` passes `check` today, silently | step 3 | **yes, in the same commit the annotation is born.** A misread memory annotation does not fail — it moves where the state lives, and question 39's measurement shows `ProcessDict` and `Ets` are indistinguishable in a single-process test |
| 42 | **A `Dict` under `Ets` with `keyed` unwritten** — the default the maintainer chose is `false`, and measured that is 5 061× slower at 10 000 keys and loses concurrent writes (19 994 of 20 000) | step 6 | **a located warning, not an error** — it keeps the default and takes the sentence out of `docs.md`, where it depends on being read. **Conditional:** `src/comptime/**` has no warning channel (`grep -rn warning` → 0), which [`decisions-pending.md`](../decisions-pending.md) already records as an unowned defect |

| 43 | **Where does `@BeamMemory` live — a core builtin, a library annotation function, or two layers?** (the maintainer's question) `libs/std/src/erlang.bp` is already a target-specific std module the erlang emitter parses and derives emission from (`codegen/erlang.zig:184-260`), `env.zig:542` already carries the target into comptime, and the lowercase library spelling already parses. But the decorator handle is read-only (`builtins.d.bp:416`), `DeclKind` has no `Val` (`:424-430`), and the only outcome is `@emit`ted **new** declarations appended to the module (`decorator_eval.zig:57-64`, `comptime.zig:306-344`) | the size of this front, and which half of it is `libs/std` (09, decision 17) rather than core | **(b) two layers.** Layer 1 — the host primitives — is `libs/std/src/beam.bp` with no `.zig` at all; layer 2 — the lowering of a binding's reads and writes — is irreducibly core, because a decorator is additive and cannot rewrite how an existing declaration is emitted. That leaves the compiler knowing three mode names and nothing about ETS, `persistent_term` or the process dictionary. **(c) purely library** is stronger than it looks — a decorator can `@emit` a `declare fn` carrying *both* `@External` arms, so it is portable without seeing the target, and it is implementable today — but it buys `hits()` / `setHits(v)`, not `hits` and `hits += 1`, so decision 28's `var` half stays unbuilt. (b) and (c) are not exclusive: (c) **is** layer 1, so doing it first removes rakun's 96 lines now and leaves the annotation for later |

**And the two the design left open, answered here with a recommendation rather than as questions:**

- **Does `ProcessDict` exist as an explicit spelling, being the default?** **Yes.** It costs one enum
  member and no grammar; "per-process, on purpose" is a real and load-bearing intent — emilia's
  stylesheet **must** be per-process, and in a file whose neighbours are `Ets` the absence of an
  annotation cannot distinguish a choice from an oversight; and it is the only spelling that records
  the choice where it is read, in the emitted erlang, where `put/get` and `ets:*` look nothing alike.
- **Does cluster stay out?** **Yes, confirmed**, with an argument that does not need CAP: inside a
  **single node**, with no partition, `keyed = false` already lost 6 writes in 40 000. If one node
  needed an explicit argument to pick its atomicity model, a `Cluster` member with no argument at all
  would hide a larger choice behind a smaller word.

---

## Rows for `fronts.md`

**Ownership table:**

```markdown
| **17** [`beam-memory`](./17-beam-memory/README.md) | `modules/compiler-core/src/parser.zig`'s top-level declaration dispatch (`:436`, `:445-458`, `:531`) — **not** the `ParseErrorType` enum (`:61-158`, **15**'s) · the `ValDecl` struct in `src/ast.zig` (`:1891-1909`) · two diagnostics in `src/comptime/infer.zig` beside `:2742` (carve-out of **01**) · one emission function per backend: `commonJS.zig:438`+`buildValDecl` (**04**), `wat.zig:2104` `emitGlobalVal` (**05**), `erlang.zig:3205-3229` (**02**/**13**), the matching `beam_asm.zig` site (**03**/**13**) · a new `Form` variant in `src/codegen/beam/erl_ast.zig:252-266` and its `erl_emitter.zig` arm · new cases in `src/parser/tests/**` (carve-out of **07**). **Not** `libs/std/src/beam.bp` — specified by step 3b, landed by **09** | `snapshots/codegen/{commonJS,wasm}/**` — only cells step 2 makes legal; `snapshots/codegen/{erlang,beam}/**` only after 13 | not started — steps 0–1 ready with 01's carve-out; step 2 after 1; steps 4–5 **after 13**, and step 4 needs decision 39 |
```

**Conflict notes:**

| With | Verdict | Why |
|---|---|---|
| **01 checker** | **no — carve-out or the front does not open** | `src/comptime/infer.zig` is 01's. This front needs **two diagnostics** beside decision 37's at `:2742`: assignment to a `val`, and the `Ets` initialiser rule. The same shape [`14`](../14-comptime-on-beam/README.md) was granted for two `evaluate(…)` call sites. Separately, step 3's annotation validation is the annotation grammar, which [decision 15](../decisions-taken.md#15-a-lower-case-externalnode-) assigns to 01 — register it there rather than restate it |
| **02 erlang · 03 beam** | **no** | Steps 4 and 5 rewrite `topValForms` and the beam equivalent. Both files are additionally [`13`](../13-module-identity/README.md)'s **wholesale** for its halves 2–3, so this front's BEAM half runs **after 13**, beside 02 and 03 rather than against them |
| **04 js · 05 wasm** | **seq — one function each** | `buildValDecl` (reached from `commonJS.zig:438`) and `emitGlobalVal` (`wat.zig:2104`). Neither front owns the rest of what step 2 touches, and both changes are one field read. Recommended: granted by name, landed in step 2 before 04 and 05 re-record anything of their own |
| **06 comptime-dedup** | yes | No shared file; this front re-records no `snapshots/comptime/**` cell |
| **07 review-backlog** | **carve-out** | `src/parser/tests/**` — the new `expectError` cases are this front's, the existing ones stay 07's, named in the commit |
| **08 hygiene** | **seq — 17 supplies, 08 edits** | `docs.md` is 08's. Step 6 writes the three paragraphs and hands them over. And step 6's warning depends on the warning-channel defect `decisions-pending.md` records as unowned |
| **09 ecosystem-residuals** | **seq — 17 specifies, 09 lands** | `libs/std/**` and `repository/{emilia,rakun}/**` are 09's. **Step 3b's `libs/std/src/beam.bp` is specified here and written there** — it is the layer-1 half of question 43 and needs no compiler change. Step 8 produces the migration, including the 96 lines and 13 declarations rakun sheds, and registers it against [decision 17](../decisions-taken.md#17-rakuns-erlang-story) rather than doing it |
| **10 cli-residuals** | yes | No shared file |
| **11 tooling** | **seq, one row** | The language server renders parse diagnostics and hovers a binding. Step 1's `var` and step 3's kinds change both; 11 re-runs `modules/language-server/snapshots/lsp/` (114) afterwards. Nothing for 11 to implement |
| **12 language-tests** | **seq — 17 specifies, 12 writes** | `tests/language/**` is 12's. Steps 3, 4 and 7 specify the cells; 12 writes them, after its own step 1 re-points `expected-failures.txt` |
| **13 module-identity** | **no — 13 first** | 13 owns `erlang.zig` and `beam_asm.zig` wholesale for halves 2–3 and re-records **318** cells there. Steps 4 and 5 run after it. Step 5(c) of the design — storing a handler by **name**, not as a `fun` — is 13's policy 3 delivering for free: with one module per `type`, the atom is the stable address |
| **14 comptime-on-beam** | yes | No shared file. Both use the resident erlang runtime, neither edits the other's half |
| **15 language-surface** | **seq — 15 landed, 17 inherits** | 15 measured module-level `var` and deliberately did not implement it: *"It needs a `.@"var"` arm in `parser.zig:441`, beside `checkShorthand(.val)`, and a `mutable` field on `ast.ValDecl`, which has none."* This front is that sentence's other half. 15 keeps the `ParseErrorType` enum and `print.zig`, so step 3's new kinds are registered with 15 |
| **16 formatter** | **seq — 17 first, 16 prints** | Without a `format.zig` arm, `botopink format` deletes the `var` keyword and the annotation — the exact class of defect 16 found in `pub default mod` (`pub default mod` → `pub mod`, then reporting the broken file clean). Recommended: each form lands with its round-trip confirmed, and the arm is 16's |

**Front-table row (`overview.md`):**

```markdown
| [`17-beam-memory`](./17-beam-memory/README.md) | high | Module-level `var` and the `#[@BeamMemory.…]` annotation that gives it storage on the BEAM — [decision 28](./decisions-taken.md#28-what-decision-14-left-unassigned)'s last unlanded half, which [`15-language-surface`](./15-language-surface/README.md) measured and left to the semantics. The carrier cannot land alone: `val hits = 0;` reassigned passes `check` and then throws on node, **does not compile** on erlang and does not validate on wasm, because the only immutability rule in the compiler is decision 37's record-field one. The annotation's spelling already parses on a `fn`; what is missing is a declaration that can carry an annotation and a mutable value. The payoff is measured — **96 of `rakun/src/runtime.mjs`'s 231 lines** and **13 of its 16 `@External.Node` declarations** are registry maintenance that this removes rather than ports — and so is the warning: `-on_load` cannot create an ETS table, so the `Ets` mode as designed degrades into the `ProcessDict` it exists to replace (5 requests × 3 increments → the counter reads **0**), unless the module emits an owner. And the maintainer's own rule cuts the front in half: `libs/std/src/erlang.bp` already proves a target-specific std module can drive emission without a `.zig` recompile, so the host primitives belong in a sibling `std/beam` and only the read/write lowering is irreducibly core — question 43 |
```
