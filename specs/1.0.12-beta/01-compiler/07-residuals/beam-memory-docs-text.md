# The `docs.md` text for `@BeamMemory` — supplied by front 17, placed by front 07 (step 6)

Front 17 writes no `docs.md`; this file is the text it supplies. Both parts are true on feat
(17 step 1: `keyed = true`, decision 167's refusal off the BEAM). The figures are 1.0.10's
`17-beam-memory/design.md` §4, §6 and `run/beam_memory_ets_keyed`; none is a promise.

---

## Part 1 — `docs.md` § Bindings

### Under `### val — immutable binding`, after the first two fences

> A `val` is immutable: assigning to it — in a `fn` body or at module level — is a compile-time
> error, and the hint names `var`. The rule is the same one node already enforced at run time
> (`const`); it now holds on every target before any code is emitted.
>
> ```botopink
> val x: i32 = 0;
> // x = 1;   error: `x` is a `val` and cannot be assigned
> ```

### Replacing `### var — mutable binding` (today a two-line fence)

> A `var` may be reassigned. Inside a `fn` it is a local; at module level it is **one value per
> execution context** — the whole program on commonJS and wasm, the **process** on erlang and
> beam. Two writes through a `fn` and one read print `2`:
>
> ```botopink
> var hits: i32 = 0;
>
> pub fn bump() { hits = hits + 1; }
>
> pub fn main() { bump(); bump(); @print(hits); }
> ```
>
> On the BEAM the annotation `#[@BeamMemory.<member>]` widens where a module `var` lives beyond the
> process (§ `@BeamMemory`). Off the BEAM the annotation is refused where it is written —
> ``error: `#[@BeamMemory]` has no meaning on the commonJS backend`` — because a target with one
> execution context has no BEAM storage to name; a `var` there is one value for the whole program.
> A hand-written `import { beam } from "std"` — the host primitives themselves — is
> `std-unsupported-on-target` there for the same reason (decisions 43, 167).

### A new `### @BeamMemory — where a module var lives on the BEAM`, the validation half

> `#[@BeamMemory.<member>]` above a module `var` names its memory on erlang and beam. The member
> is one of `ProcessDict` (the default, which a bare `var` already means — writing it out loud
> records the choice where it is read), `Ets` or `PersistentTerm`. The only argument is
> `keyed = true | false`, default `false`, and it is a `Dict`-only argument: an `i32` has no key and
> neither has a list, which stores its whole value. Every part is checked at `botopink check`:
>
> ```botopink
> #[@BeamMemory.ProcessDict]        var explicit: i32 = 0;   // the default, said out loud
> #[@BeamMemory.Ets]                var hits: i32 = 0;
> #[@BeamMemory.PersistentTerm]     var buildVersion: i32 = 101;
> #[@BeamMemory.Ets(keyed = true)]  var counts: Dict<string, i32> = Dict.empty();
>
> // #[@BeamMemory.Etz] var x: i32 = 0;
> //   error: unknown member `Etz` in `@BeamMemory` — expected `ProcessDict`, `Ets` or `PersistentTerm`
> // #[@BeamMemory.Ets(keyd = true)] var x: i32 = 0;
> //   error: unknown argument `keyd` — expected `keyed`
> // #[@BeamMemory.Ets(keyed = true)] var n: i32 = 0;
> //   error: `keyed` needs a keyed container — an `i32` has no key
> // #[@BeamMemory.Ets] val x: i32 = 0;
> //   error: `#[@BeamMemory.Ets]` needs a `var` — `x` is a `val`
> ```
>
> The annotation takes the plain form only: `#[…] val add = fn …` and the other `val` shorthands
> are refused at the annotation.

---

## Part 2 — the three modes (`docs.md` § `@BeamMemory`)

The second paragraph carries decision 42: `keyed` unwritten on a `Dict` is **not** a warning —
replacing the whole container is a thing authors legitimately want — so the behaviour and the cost
are stated here, where the default is documented, and nowhere else.

> **`ProcessDict`** — one value per BEAM process, in the process dictionary: no setup, no owner,
> erased when the process ends. It is what a bare `var` means, and the spelling exists so that a
> file whose other bindings are `Ets` can say "per-process, on purpose" where it is read. A request
> handler that counts under `ProcessDict` counts its own requests only.

> **`Ets`** — one value per node, in a named public ETS table the module owns through a registered
> owner process, so the table survives the process that first touched it and is re-created and
> re-seeded from the declaration if the owner dies. `hits += 1` and `hits = hits + 1` on an `i32`
> or `i64` are one atomic `ets:update_counter`; any other read-modify-write — `hits = hits * 2 + 1`,
> or `+=` on an `f64`, `bool` or `string` — is refused, because two processes running it would
> lose one of the two writes. The initialiser must be a literal or a `comptime` expression: it is
> re-run at a moment nobody chose. **`Ets` is cache and counting memory, not where the truth
> lives** — a balance, an order, a paid session belong in a supervised process or a database.
> Under **`keyed = false`** (the default) a `Dict` is stored as **one** value: a write copies the
> whole dict, and two processes writing *different* keys at the same time lose one of the writes —
> measured, 20 000 writes each to two keys finished at `19 996` and `20 000`. Under
> **`keyed = true`** each key is its own row: the seed is `Dict.empty()` or
> `Dict.ofEntries([#("a", 1)])` of literals, a row is read as `counts.at(k)` and written as
> `counts = counts.insert(k, v)`, and nothing else names the var — measured, two processes writing
> 20 000 times each to their own key finish at `20000` and `20000`; at 10 keys a write is 5×
> cheaper, at 10 000 keys 5 000×. Choose `keyed = true` whenever more than one process writes;
> keep the default when the dict is replaced whole.

> **`PersistentTerm`** — one value per node, written **once, at load**, read everywhere for the
> cost of a function call. A write after load is a compile-time error with the hint
> `#[@BeamMemory.Ets(keyed = true)]`: at run time a `persistent_term:put` scans every process heap
> (measured, 810 ns against 17 ns for a read), and the module's load hook **re-runs on every hot
> code reload**, so a run-time write would be erased by the next reload anyway. It is the mode
> for a routes table, a scanned-component list, configuration read at bootstrap — anything the
> decorators emit at load and nothing changes afterwards. Store a handler by **name**, not as a
> function value: a `fun` belongs to the module version that created it and dies with it on
> reload.

If `17-b` or `17-c` widens the keyed surface, the `keyed = true` sentence follows the answer.
</content>
</invoke>
