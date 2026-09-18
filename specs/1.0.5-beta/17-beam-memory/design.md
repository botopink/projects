# The design — module-level `var` and `@BeamMemory`

The argument behind [front 17](./README.md), with the evidence that produced it. Every number here was
measured on 2026-09-18 at `botopink-lang` `bef762b`, in a detached scratch worktree — OTP 29 /
erts 17.0.6, node v25.8.0, wasmtime 45.0.0, 16 cores. Where something was **not** measured, the line
says so.

The maintainer's reading copy of this document, in Portuguese and with the discussion that produced
each decision, is unversioned; this file is the record the front implements against.

---

## 1. The separation that makes the design work

**The language** defines what a module `var` is, in one sentence valid on all four targets:

> A module-level `var` is **one value per execution context**.

| target | the execution context is |
|---|---|
| commonJS | the node process |
| wasm | the module instance |
| erlang / beam | **the BEAM process** |

**The annotation** is how the BEAM is told to *widen* that beyond the process:

```botopink
var scratch: i32 = 0;                                       // per execution context

#[@BeamMemory.ProcessDict]    var explicit: i32 = 0;        // the same, said out loud
#[@BeamMemory.Ets]            var hits: i32 = 0;            // one per node, mutable
#[@BeamMemory.PersistentTerm] var buildVersion: i32 = 101;  // one per node, written at load
```

**On commonJS and wasm the annotation is a no-op** — not out of laziness: their execution context
*is* already the whole program, so there is nothing to widen. That is what lets the annotation be
BEAM-specific without splitting the language: it exists exactly where a difference exists. A bare
`var` therefore has a portable meaning, and the annotation is what it says it is — a choice of reach
on the BEAM. No annotation is mandatory.

## 2. The name, and where the annotation has to live

`storage` was rejected because it suggests disk. All three are **memory**: the process dictionary is
the process heap, ETS is memory off the heap, `persistent_term` is node-global memory — and OTP's
"persistent" means *persists between calls*, not *between runs*. Nothing here survives a restart.
`@BeamMemory` says the target **and** says memory, and it follows the shape the language already
uses for `@External.Erlang`: **family = the concern, member = the specific**.

**The spelling already parses.** `#[@BeamMemory.Ets(keyed = true)]` on a `fn` checks clean at
`bef762b`: `parser.zig:900` builds the `Family.Member` name and `parser.zig:962` accepts
`keyed = true` as a labelled argument. What does not exist is the **carrier**: `#[…]` before a
top-level `val` is `unexpected '#'` (the annotated-declaration `switch` at `parser.zig:450` has no
`.val` arm), and `var` at module level is `unexpected 'var'`. `ast.ValDecl` (`ast.zig:1891-1909`) has
neither `mutable` nor `annotations`, while `ast.Stmt.Kind.localBind` (`ast.zig:563`) **has** `mutable`
and `commonJS.zig:2366` already reads it. Sizing this work as "a parser change plus three erlang
lowerings" gets the first half right and the second half backwards.

### 2.1 Two layers, not one builtin

The maintainer's standing rule is that the core stays generic and library-specific knowledge lives in
libraries. Measured against this design, the rule splits it cleanly in two, and the split is an
improvement:

- **Layer 1 — `libs/std/src/beam.bp`, no core change.** The host primitives, exactly as
  `libs/std/src/erlang.bp` already does it: 170 lines of
  `#[@External.Erlang("erlang", "<symbol>")] pub declare fn …`, declared `pub mod erlang;` in
  `root.bp`, and **parsed by the emitter at compile time** to drive emission
  (`codegen/erlang.zig:184-260`, `loadAutoImportedBifsFromPrelude`, whose own comment says *"To add /
  remove / update a BIF: edit `libs/std/src/erlang.bp`. No `.zig` recompile of the table itself is
  needed."*). The target already reaches comptime (`env.zig:542`) with a working diagnostic —
  `std-unsupported-on-target: std/erlang.abs has no '@external' for target 'node'`. Everything §5
  calls "the design" — the `whereis`-guarded `case`, the `try ets:new`, the registered owner — fits
  here, as template text editable without recompiling the compiler. `std/beam` is the natural name,
  because the family covers both BEAM targets.
- **Layer 2 — `#[@BeamMemory.<Mode>]` in the core, and only this: the binding's lowering.** The core
  learns three mode names and how to lower a **read** and a **write** onto layer 1's functions. It
  learns nothing about ETS, `persistent_term` or the process dictionary — none of those words appear
  in `.zig`.

**Why layer 2 cannot be a library decorator**, measured rather than assumed: the decorator mechanism
is real and mature (`rakun/src/decorators.bp:66`, and `#[beamMemory.ets(keyed = true)]` on a `fn`
already parses), but `DeclKind` is `Type | Behavior | Fn | Method | Field` with **no `Val`**
(`builtins.d.bp:424-430`), the `Decl` handle is **read-only** (`:416`), and the only way out is
`@emit` of **new** declarations (`rakun/src/decorators.bp:67-81`). The decorator is additive, and this
work is not: `hits` must become `ets:lookup_element(…)` at every **read** and `hits += 1` must become
`ets:update_counter(…)` at every **write**, at sites spread across the module that only the emitter
sees. That is [question 43](../decisions-pending.md).

## 3. The three modes

| mode | reach | mechanism on the BEAM | dies when |
|---|---|---|---|
| `ProcessDict` *(default)* | one per BEAM process | `put/2`, `get/1` | the process ends |
| `Ets` | one per node, mutable | named public table | its **owner** dies (§5) |
| `PersistentTerm` | one per node, written at load | `persistent_term:put/get` | the node goes down |

None crosses a pod: ETS and `persistent_term` are **per node**, measured (both live in
`nonode@nohost`, and only there). Cross-pod state is §7.

### 3.1 When `Ets` is the right answer — and when it is not

Three conditions **at once**; fail one and the answer is another mode:

1. it is **rewritten at run time** (not only at load);
2. it is **read by more than one process** on the node;
3. **losing it is survivable** — because it re-initialises itself (§5).

The measured example is not hypothetical. `rakun/src/runtime.mjs` is 231 lines, and
`rakun/AGENTS.md:21-22` says why: *"botopink has no top-level mutable state, so the registries those
calls need live in the host"*. Registry by registry:

| registry | lines | `runtime.mjs` | write pattern | mode |
|---|---:|---|---|---|
| `scanned` | 17 | `:16-32` | once at load (decorator-emitted) | `PersistentTerm` |
| `building` + `builds` | 31 | `:33-63` | repeatedly at run time | `Ets` |
| `singletons` | 16 | `:64-79` | repeatedly at run time | `Ets` |
| `props` | 19 | `:80-98` | at bootstrap | `PersistentTerm` |
| `routes` | 13 | `:107-108`, `:113-123` | once at load (decorator-emitted) | `PersistentTerm` |

**96 of the 231 lines** are registry maintenance; the other 135 are host binding that stays. Of
`runtime.bp`'s **16** `@External.Node` declarations, **13** exist only to reach a registry.
`singletons` is the case only `Ets` can take: an instance cache written on every miss and read by
every process on the node. Under `PersistentTerm` each write would scan every process heap; under
`ProcessDict` each request would get its own cache, which is the same as having none.

The other families that land here: **counters and metrics** (`hits += 1` becomes
`ets:update_counter`, the only atomic read-modify-write of the three that needs no message pass),
**per-key rate limits** (`keyed = true`), and **caches of expensive results**.

Note the symmetry with §5: cache, counter and limit are exactly the things that **survive going back
to zero**. If the value is truth that cannot be lost — a balance, an order, a paid session — the
answer is not `Ets` but a supervised process or a database, and the module `var` is being used for
the wrong thing. The sentence for `docs.md`: **`Ets` is cache and counting memory, not where the
truth lives.**

## 4. `keyed` — atomicity, not performance

`keyed` is an **argument of the member**, optional, **default `false`**:

```botopink
#[@BeamMemory.Ets]                var config: Dict<string, string> = dict.empty();  // = keyed false
#[@BeamMemory.Ets(keyed = false)] var config: Dict<string, string> = dict.empty();  // the same, written
#[@BeamMemory.Ets(keyed = true)]  var counts: Dict<string, i32>    = dict.empty();
```

| | `keyed = false` | `keyed = true` |
|---|---|---|
| how it is stored | the whole dict is **one** value | **one row per key** |
| writing one key | read the map, insert, write the map | write the row |
| two concurrent writes, different keys | **one is lost** | both hold |
| touching 1 key of 10 000 | copies 10 000 | copies 1 |

Measured, per write:

| `Dict` size | `keyed = false` | `keyed = true` | ratio |
|---:|---:|---:|---:|
| 10 | 254 ns | 51 ns | 4.9× |
| 1 000 | 25 190 ns | 47 ns | **537×** |
| 10 000 | 301 864 ns | 60 ns | **5 061×** |

And the lost writes are not theoretical: two processes writing **different keys** 20 000 times each
under `keyed = false` finished at `a => 19994`, `b => 20000` — **six writes gone**, silently.

**What the `false` default implies.** The safe mode is the one that must be asked for, so the line
written without thinking is the one that loses concurrent writes. That is acceptable because
non-keyed is what preserves the "one value" semantics the other targets have — but the consequence
has to be written beside the example in `docs.md`, and [question 42](../decisions-pending.md) asks
whether it should also be a located warning. On a scalar type `keyed` is an error: there is no key.

## 5. What the compiler refuses

**(a) Writing a `PersistentTerm` var outside initialisation** — every write scans every process heap
(measured: `persistent_term:put` is 810 ns against 17.53 ns for a read through a 0-arity fn):

```
error: a `PersistentTerm` var is written once, at load
 --> src/router.bp:14:5
  |
14|     routes = routes.insert(path, h);
  |     ^^^^^^ this runs at call time
  |
  = hint: initialise it in the declaration, or use #[@BeamMemory.Ets(keyed = true)] if it changes.
```

There is a second, measured reason: `-on_load` **re-runs on every code reload**, so a value written at
run time is erased by the next hot reload (`999` → `101` after `code:load_file/1`).

**(b) Recomputing from what was just read, under `Ets`** — and this rule is **narrower than it looks**:

```botopink
hits += 1;                 // ok on i32/i64 — ets:update_counter, atomic
hits = hits + 1;           // ok — the compiler recognises the form and emits the same
hits = hits * 2 + 1;       // error — read, recompute, write: one of two runs can be lost
```

`ets:update_counter` answers `{ok, N}` for `i32`/`i64` and **`{error, badarg}` for `f64` (with
increment `1.0` *and* `1`), `bool` and binary**. So "`+=` is atomic" is true for integers and nothing
else; on an `f64` it would have to become lookup + insert, which is precisely the pattern (b)
refuses. That is [question 40](../decisions-pending.md).

*Not a problem, recorded so it does not become one:* `update_counter` on an `i32` at the limit gives
`2147483648`, because Erlang integers are bignums — which is exactly what the erlang backend already
does (`var n: i32 = 2147483647; n = n + 1;` prints `2147483648` on erlang **and** node, and
`-2147483648` on wasm). The pre-existing divergence is not this front's; the consequence is that the
4-tuple `{Pos, Incr, Threshold, SetValue}` form must **not** be used, or `Ets` would diverge from the
erlang backend itself.

**(c) Storing a function under `Ets` or `PersistentTerm`.** A `fun` on the BEAM belongs to the module
that created it: reload the module and the old handler dies with `badfun` — during hot reload, which
is the reason the BEAM exists. Store the **name**:

```botopink
#[@BeamMemory.PersistentTerm(keyed = true)] var routes: Dict<string, HandlerRef> = registry();
```

Policy 3 of [`13-module-identity`](../13-module-identity/README.md) delivers this for free: with one
module per `type`, the atom **is** the handler's stable address. *(The `badfun` is OTP's documented
semantics, not a number measured here.)*

**(d) An initialiser that cannot be re-run, under `Ets`** — and the predicate is **not purity**.
`ast.EffectKind` (`ast.zig:2014`) is `result | future | generator | iterator | asyncGenerator |
context`: the declared **return wrappers**, not a side-effect analysis. A plain `fn` that calls
`@print`, writes a file or calls `@External.Node(…)` carries `effect == null`; measured,
`fn registry() -> i32 { @print("side effect"); return 7; }` used as a module initialiser passes
`check`. `grep -in pure comptime/{infer,types,env}.zig` finds only comments.

The decidable predicate already exists, and it is **stronger** than purity: the comptime folder.
`ast.Expr.isComptimeExpr()` (`ast.zig:218`), which the emitters already consult (`erlang.zig:3206`,
`wat.zig:2111`). Measured: `val a: i32 = 1 + 2;` emits `a() -> (1 + 2).` while
`val b: i32 = comptime 3 * 4;` emits `b() -> 12.`. So the rule is *"an `Ets` var's initialiser must be
a literal or a `comptime` expression"* — an expensive pure function should not run at a moment nobody
chose either.

## 6. The ETS owner — the decided auto re-initialisation works, and it does not deliver `Ets`

An ETS table **needs an owning process and dies with it**. The decided behaviour is that a missing
table is re-created and re-seeded from the declaration, silently, with a `try` around `ets:new` for
the creation race. Measured, that behaves exactly as decided — and it turns `Ets` into `ProcessDict`.

- **The module cannot create the table at load.** `-on_load` runs in a temporary process:
  `persistent_term` written there survives the load (`101`, and a routes map readable afterwards), an
  ETS table does not (`ets:whereis` → `undefined` immediately). So on erlang `Ets` has **no load-time
  moment** and the first caller creates the table.
- **Which makes the re-init behave as per-process state.** Five request processes × 3 increments each:
  every request read `3`, and after 15 increments the counter reads **0**. `ets:info(…, owner)`
  confirms the re-creating process becomes the new owner.
- **The way out, measured and working.** A module-emitted **registered owner** — `register/2` (the
  loser of the race kills its candidate and moves on), `ets:new(…, {heir, Pid, …})` and `give_away` —
  ~15 lines of Erlang per module, emitted once. The same five-request test then reads
  `3, 6, 9, 12, 15` and ends at **15**. `{heir, …}` alone also survives the creator's death (measured,
  value intact), but an heir is a process too, so someone must be it. *(The `owner_loop` must
  re-call itself qualified to survive a hot reload — that is how it was written and it worked; the
  unqualified variant breaking was not measured.)*
- **The guard is not free.** Over 2 000 000 operations: `ets:lookup_element` 15.38 ns bare against
  29.76 ns behind `ets:whereis` (**+94 %**), `ets:update_counter` 21.05 → 35.63 ns (**+69 %**);
  re-measured in a second program, 14.84 → 29.59 ns (**+99.4 %**). Fifteen nanoseconds nobody will
  notice — but the design may not call it free, and with a stable owner the guard almost never fires.

The two mechanisms do not compete: the guard's `undefined` arm becomes "register an owner" instead of
"become the owner", and the silent re-init stays as the safety net it was decided to be. That is
[question 39](../decisions-pending.md), the only place where measurement contradicts the effect a
decision was taken for.

`ProcessDict` and `PersistentTerm` have no such problem: the first dies with whoever created it, which
is the point, and the second belongs to the node.

## 7. What gets emitted, on the four targets

```botopink
#[@BeamMemory.Ets] var hits: i32 = 0;
fn record() { hits += 1; }
fn read() -> i32 { return hits; }
```

- **erlang** — the guarded init of §6, `ets:update_counter`, `ets:lookup_element`. Today a module
  `val` is a 0-arity function (`erlang.zig:3205`, `topValForms`), which re-evaluates the initialiser
  on **every read**: `val seeded: i32 = registry();` emits `seeded() -> registry().`
- **beam** — the same three modes in assembly; the `.S` already opens with `{attributes, []}.`, so
  `-on_load` has an empty slot waiting.
- **commonJS** — the annotation is a no-op; the context is already the program: `let hits = 0;`.
  `js_ast.Decl.Kw` (`js/js_ast.zig:324-334`) already has `let_`, used **nowhere** in production
  codegen.
- **wasm** — `(global $hits (mut i32) (i32.const 0))`. `wat_ast` already carries `mutable: bool`
  (`wat/wat_ast.zig:216`); `emitGlobalVal` (`wat.zig:2104`) sets it on 3 of its 5 paths, and the two
  that do not (`:2112`, `:2134`) are the two that break.

## 8. Cluster stays out — now with local evidence

ETS and `persistent_term` are per node. For several pods to share state the BEAM offers `global`, an
owner process with `erpc`, Mnesia, CRDTs — and **every one of them carries a consistency-model
choice**, not a memory choice:

```botopink
#[@BeamMemory.Cluster] var hits: i32 = 0;    // ← what this line cannot answer
```

Two pods, the network partitions, each does `hits += 1`. On healing: `1` or `2`? An `i32` does not
know how to merge; a CRDT counter does, because it keeps per-replica state.

And there is now an argument that does not need CAP at all: inside a **single node**, with no
partition, `keyed = false` already lost 6 writes out of 40 000. If one node needed an explicit
argument to pick its atomicity model, a `Cluster` member with no argument would hide a larger choice
behind a smaller word. Cross-pod state is an explicit `libs/std` type with its model declared at
construction.

## 9. What it pays back

**rakun**: 96 of `runtime.mjs`'s 231 lines and 13 of `runtime.bp`'s 16 `@External.Node` declarations
(§3.1) — the container-and-router half of
[decision 17](../decisions-taken.md#17-rakuns-erlang-story), removed rather than ported. 62 of those
96 lines are the two `Ets` registries, which ties the payoff to question 39.

**emilia** is the validation case for `ProcessDict`, not a migration of this front.
`emilia/src/emilia.bp:23-25` (`get` + `lists:keystore` + `put`) and `:27-30` (`erase`) are a
read-modify-write and a reset over one key, `'__emilia_sheet'`, whose scope is per-process **on
purpose** (`emilia.bp:3-8`). `erase` is **not** a blocker: both readers guard
`case … of undefined -> []; X__ -> X__ end`, so absent and `[]` are indistinguishable and `sheet = []`
reproduces it. The blocker is that the value is a host list of 2-tuples with `keystore` upsert
semantics, which needs an ordered dict in `libs/std` — decision 17's half, not this one's.

## 10. The decisions this design rests on

**Closed by the maintainer**, and surviving measurement: the family name `@BeamMemory`, BEAM-specific
and a no-op elsewhere · a bare `var` is one value per execution context · three members with
`ProcessDict` the default · `keyed` as an argument of the member, optional, default `false` · a
missing ETS table is re-created and re-seeded silently · cluster state stays out.

**Answered here with a recommendation, for confirmation:** `ProcessDict` keeps an explicit spelling
(one enum member, no grammar; "per-process on purpose" is load-bearing — emilia needs it — and in a
file whose neighbours are `Ets`, the absence of an annotation cannot distinguish a choice from an
oversight); and cluster stays out, per §8.

**Open, in [`decisions-pending.md`](../decisions-pending.md):** **38** is a `val` immutable · **39**
who creates the ETS table · **40** `+=` under `Ets` on a non-integer · **41** is a misspelled
`@BeamMemory` an error · **42** a `Dict` under `Ets` with `keyed` unwritten · **43** where
`@BeamMemory` lives — core builtin, library decorator, or the two layers of §2.1.
