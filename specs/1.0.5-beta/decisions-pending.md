# Decisions the maintainer owes — 1.0.5-beta

**Ten open — 38 to 47.** Six were raised by the `@BeamMemory` measurement, one by front 11's
re-verification and three by front 04's; all are listed below. The thirty-seven questions before them are answered, and the record the fronts implement against is
[`decisions-taken.md`](./decisions-taken.md).

Two findings from front 01 (2026-09-18) sit below the level of a decision — they are defects with no
row, not questions — and are recorded here until a front claims them:

- **`src/comptime/**` has no warning channel at all** (`grep -rn warning comptime/*.zig` → 0), and
  three separate obligations want one: decision 8 §1.4, §2.4 and §4.3. It is a `warnings` list on the
  `Env`, rendered like a `TypeError`, and it unblocks all three at once.
- **An inline `implement <Behavior> { }` inside a `type` checks nothing.**
  `type Money(cents: i32) implement Display { }` passes — with a local `Display`, and with the
  long-registered `Generator`. Only the separate `implement X for Y` block is covered. No row exists.

This file stays because the fronts will fill it again. A front that meets a question it cannot answer
from the code writes it here rather than guessing, in the shape the others used:

> **Measured.** What was observed, with the command or program that produced it and the file or commit
> that can be re-read.
>
> **Options.** Each one stated so that choosing between them is possible without reading the code.
>
> **Recommendation.** One, argued — a question with no recommendation is a question the front did not
> finish thinking about.
>
> **Blocks.** The step, front or landed work that waits on the answer.

Numbers are never reused: the next question added here is **48**.

---

## 38. Is a `val` immutable?

**Measured.** `val x: i32 = 0; x = 1;` passes `check` — in a `fn` body **and** at module level. At
module level the emitted program then breaks on all three runnable targets:
`TypeError: Assignment to constant variable.` (node v25), `main.erl:9:13: variable 'Hits' is unbound`
(OTP 29 — **the module does not compile**) and
`Invalid input WebAssembly code at offset 168: global is immutable` (wasmtime 45). The only
immutability rule in the compiler is decision 37's record-field one (`infer.zig:2742`), and it works.

**Options.** (a) `val` refuses assignment with a located diagnostic and `var` allows it — both in the
same change. (b) Only `var` arrives; `val` stays without a rule. (c) Leave it as it is.

**Recommendation: (a).** It is decision 37 one level up: without it `var` means nothing, because `val`
already allows assignment, and three backends keep emitting code that cannot run with nothing said.
The migration cost is probably zero — decision 37 measured 0 field assignments across the ecosystem —
but **the `val`-assignment query was not run**, and step 1 of front 17 must run it.

**Blocks:** the `@BeamMemory` carrier; [`17-beam-memory`](./17-beam-memory/README.md) entirely.

---

## 39. Who creates the ETS table the first time?

**Measured.** `-on_load(F/0)` runs in a temporary process: a `persistent_term` written there survives
the load (`101`, and a routes map readable afterwards), an **ETS table does not** (`ets:whereis` →
`undefined` immediately). With the first caller creating it, 5 request processes × 3 increments each
read `3, 3, 3, 3, 3` and the counter ends at **0** — `ets:info(…, owner)` confirms the re-creating
process becomes the new owner. With a module-emitted **registered owner** (~15 lines of Erlang:
`register/2` + `ets:new(…, {heir, Pid, …})` + `give_away`) the same test reads `3, 6, 9, 12, 15` and
ends at **15**.

**Options.** (a) The module emits a registered owner process, and the silent re-initialisation stays
as the safety net. (b) Only the silent re-initialisation, with `docs.md` saying the whole sentence.
(c) `{heir, …}` alone — but an heir is a process too, so (c) collapses into (a).

**Recommendation: (a).** (b) is honest and cheap, but then `Ets` does not do what it exists for in the
one measured case that justifies it (rakun's `singletons`), and the right response would be to drop
`Ets` from the mode list rather than ship a cache that always misses. (a) does not reopen the
maintainer's decision: the guard's `undefined` arm becomes "register an owner" instead of "become the
owner".

**Blocks:** steps 4 and 5 of [`17-beam-memory`](./17-beam-memory/README.md); the worth of 62 of the 96
rakun lines; the announced semantics of `Ets`.

---

## 40. `+=` under `Ets` on a type that is not an integer

**Measured.** `ets:update_counter` answers `{ok, N}` for `i32`/`i64` and `{error, badarg}` for `f64`
(with increment `1.0` **and** `1`), `bool` and binary — same table, same call. So the rule "`+=` is
atomic, `hits = hits * 2 + 1` is not" is true for integers only; on an `f64` the `+=` would have to
become lookup + insert, which is the very pattern the rule refuses.

**Options.** (a) Refuse `+=` under `Ets` when the type is not an integer, with the same diagnostic.
(b) Allow it and document the race. (c) Emit a CAS loop with `ets:select_replace` (cost not measured).

**Recommendation: (a).** One checker line, and it keeps the promise the rule makes. (b) turns the rule
into something the author cannot predict from what they wrote.

**Blocks:** the §5 text in `docs.md`; the diagnostic of rule (b) in
[`17-beam-memory`](./17-beam-memory/design.md).

---

## 41. Is a misspelled `@BeamMemory` an error?

**Measured.** `#[@TotallyMadeUp.Nonsense(whatever = 42)]` on a `fn` **passes `check`** with no
diagnostic at all. So the day the carrier exists, `#[@BeamMemory.Etz]` and
`#[@BeamMemory.Ets(keyd = true)]` will be accepted and ignored: the program compiles, runs, and the
`var` stays in the default mode with nothing said. It is the family of failure
[decision 15](./decisions-taken.md#15-a-lower-case-externalnode-) already named for `#[@external]`.

**Options.** (a) Validate `@BeamMemory.<Member>` and the argument names, with a located error naming
the three members. (b) Accept and ignore, as today.

**Recommendation: (a)**, in the same commit the annotation is born. A misread memory annotation does
not fail — it **moves where the state lives**, silently, and question 39's measurement shows
`ProcessDict` and `Ets` are indistinguishable in a single-process test.

**Blocks:** trust in anything written with this annotation; step 3 of
[`17-beam-memory`](./17-beam-memory/README.md).

---

## 42. A `Dict` under `Ets` with `keyed` unwritten

**Measured.** The chosen default is `keyed = false`, and at 10 000 keys that is **5 061× slower** per
write (301 864 ns against 60 ns); two processes writing **different keys** 20 000 times each lost
**six writes** silently (`a => 19994`, `b => 20000`).

**Options.** (a) A located warning when the type is a `Dict` and `keyed` was not written — the default
does not change. (b) The sentence in `docs.md` only.

**Recommendation: (a)**, because it puts the warning where it is read instead of where it must be
looked up. **Conditional:** `src/comptime/**` has no warning channel at all (`grep -rn warning` → 0),
which this file already records above as a defect with no owner; without it, (b) is the only option
and the box is struck with that reason.

**Blocks:** step 6 of [`17-beam-memory`](./17-beam-memory/README.md); the `docs.md` text.

---

## 43. Where does `@BeamMemory` live — core builtin, library annotation-function, or two layers?

**Measured.** The target-specific std module already exists and already drives emission:
`libs/std/src/erlang.bp` (170 lines, `pub mod erlang;` in `root.bp`) is parsed by the emitter at
compile time (`codegen/erlang.zig:184-260`) — *"No `.zig` recompile of the table itself is needed"* —
and the target reaches comptime (`env.zig:542`) with a working diagnostic
(`std-unsupported-on-target: std/erlang.abs has no '@external' for target 'node'`). The decorator
mechanism exists too, and the lower-case spelling already parses (`#[beamMemory.ets(keyed = true)]` on
a `fn` passes `check`). But the reflection model is **read-only** (`builtins.d.bp:416`), `DeclKind` is
`Type | Behavior | Fn | Method | Field` with **no `Val`** (`:424-430`), and the only way out is
`@emit` of **new** declarations (`rakun/src/decorators.bp:67-81`). The decorator is additive;
rewriting a name's reads and writes is not.

**Options.** (a) A full core builtin. (b) **Two layers**: the host primitives in a
`libs/std/src/beam.bp` (`@External.Erlang`, no `.zig`), and in the core only the lowering of the
binding's read and write onto them. (c) Purely library: a `#[beamMemory]` decorator on a `type` that
`@emit`s accessors — zero core, available today, but the author writes `hits()` / `setHits(v)` and
**module-level `var` still does not exist**.

**Recommendation: (b).** It honours the core-stays-generic rule better than (a) — the core stops
knowing what ETS, `persistent_term` and the process dictionary are, and the whole §6 design becomes
template text editable without recompiling the compiler — and it delivers what (c) cannot:
[decision 28](./decisions-taken.md#28-what-decision-14-left-unassigned)'s module `var`. (c) is the
right answer if the goal is only to take rakun's 96 lines out of the host; it is not, if the goal is
`var` in the language.

**One tension that comes with (b), and cannot be decided separately:** the design says the
**annotation** is a no-op off the BEAM, while a target-specific std module is a **hard error** there —
measured (`std-unsupported-on-target: std/erlang.abs has no '@external' for target 'node'`). Both are
defensible; they have to be answered together, and step 3b of the front marks the spot.

**Blocks:** the size of [`17-beam-memory`](./17-beam-memory/README.md), and how much of it belongs to
`libs/std` (front 09 under decision 17) rather than to the core.

---

## 44. Is `optional<i32>` a valid spelling?

**Measured** by [`11-tooling`](./11-tooling/README.md) at `19a3b01`, while fixing the language
server's half of it:

```botopink
val v: optional<i32> = null;   // passes `check` — `optional` is the checker's own internal name
val w: Option<i32>   = null;   // error: "type mismatch: expected Option, got optional"
```

The second line is refused, but with the wrong message: `builtins.d.bp:56-58` documents a pointed
diagnostic (use `?T`), and what comes out is a generic `type mismatch` **that leaks the internal
name** (`infer.zig:4590`). [Decision 2](./decisions-taken.md) already settled that `?T` is the only
optional spelling.

**Options.** (a) Refuse `optional<T>` as well, with the pointed diagnostic the other two spellings are
already owed. (b) Keep it as an undocumented alias.

**Recommendation: (a).** Front 11 has just stopped the server from echoing the internal name back at
users — including a code action that wrote `: optional<i32>` **into the user's file**. Leaving the
checker accepting it re-opens the door from the other side.

**Blocks:** nothing in 11 (the rendering half is fixed). The file is
[`01-checker`](./01-checker/README.md)'s.

---

## 45. Is a member access on a `?T` an error?

**Measured** by [`04-js`](./04-js/README.md) while looking at front 12's tuple-label cell:
`rs.at(0)` types as **`?#(a: i32, b: string)`** — an optional — so `infer.zig:6186`'s
label-to-position rewrite never fires and the backend emits `.b` verbatim. The cell's owner row
(`04 step 2`) is therefore mis-attributed: the fix is in `src/comptime/**`.

Underneath it is a language question nobody has asked: **`.b` on a `?T` is accepted, with no
narrowing and no `?.`**.

```botopink
val rs: #(a: i32, b: string)[] = [ #(a: 1, b: "x") ];
val v = rs.at(0).b;      // accepted today — `rs.at(0)` is `?#(…)`
```

**Options.** (a) A member access on a `?T` is an error naming `?.` — which is what `?.` exists for.
(b) It stays accepted and each backend decides what absent means, which is how the three of them came
to disagree.

**Recommendation: (a).** It is the same shape as decision 37 and question 38: the checker accepts
something the backends then answer differently. And the `?.` spelling already exists, so the
diagnostic writes itself.

**Blocks:** front 12's `§6 T4` cell, whose owner row moves from `04 step 2` to
[`01-checker`](./01-checker/README.md).

---

## 46. What does `d["k"]` answer on a `Dict`?

**Measured.** A `Dict` is a record over `pairs`, so the read a user means is `d.lookup("k")`. The
index expression ([decision 30](./decisions-taken.md#30-is-there-an-index-expression)) gives the
backend no receiver type — `instanceLowerings` has no entry and the checker types the index call
`void` — so commonJS emits a plain property read and the program answers **`undefined`**, silently.

**Options.** (a) [`01-checker`](./01-checker/README.md) records the receiver kind at the index call
site, as it already does for primitive method receivers, and each backend routes a dict index to
`lookup`. (b) The language refuses an index on a dict, and `d.lookup("k")` stays the only spelling.

**Recommendation: (a).** Decision 30's own text says a dict read is `d["k"]` — that is what the
expression was added for. (b) would be defensible if the decision had not already written the form.

**Blocks:** the `d["k"]` half of decision 30 in all four backends; front 12 left the cell out for
exactly this reason.

---

## 47. Is an out-of-range read `undefined` or `null`?

**Measured** on commonJS: `xs.at(9)` is declared `?T` and answers **`undefined`**; `xs[9]` does the
same; but `"abc".charAt(9)` answers **`null`**, through `__bp_string_char_at`. Two spellings of
absence in one backend, and the optional machinery now assumes one of them: front 04 had to loosen
the optional guard to `!=` so that `?.` and `??` agree (question 44's sibling defect).

**Options.** (a) One spelling of absent — an `array_at` prelude helper that answers `null`, matching
the string helper. (b) `?T` means "`null` or `undefined`", which is what `==`/`!=` and the loosened
guard already assume, written down as a rule.

**Recommendation: (a).** (b) works today, but it puts two values behind one type and every future
`===` in a hand-written host template is a bug waiting. The helper is the shape the string path
already uses.

**Blocks:** nothing today — it is a defect with no row, recorded so the next `?T` change does not
re-derive it.
