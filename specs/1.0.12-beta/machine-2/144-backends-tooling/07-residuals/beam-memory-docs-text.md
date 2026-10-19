# The `docs.md` text for `#[beamMemory]` — supplied by front 17, placed by front 07 (step 6)

Front 17's text for `docs.md` (17 writes none), rewritten to decision 547 (the module `var` one value for the whole
program; `keyed: true`, the per-process placement and `ProcessDict` removed; the annotation accepted off the BEAM, with
no effect) and spelt `#[beamMemory(…)]` (663). The `PersistentTerm` figures are 1.0.10's `17-beam-memory/design.md` §6;
none a promise. Quoted blocks are the text to place, verbatim.

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

> A `var` may be reassigned. Inside a `fn` it is a local; at module level it is **one value for the whole program**,
> on every target — on erlang and beam a one-row ETS table, on commonJS a variable, on wasm a permanent root. Two
> writes through a `fn` and one read print `2`:
>
> ```botopink
> import {io.terminal} from "std";
>
> var hits: i32 = 0;
>
> pub fn bump() { hits = hits + 1; }
>
> pub fn main() { bump(); bump(); terminal.print(hits); }
> ```
>
> Its data is immutable: a `Dict` is changed by writing the new one back, `counts = counts.insert(k, v)`. A
> reassignment that reads the `var` it writes (`hits = hits + 1`) is atomic on the BEAM, so two processes writing at
> once lose nothing and the answer is commonJS's and wasm's; a plain `x = v` is one write. A module `var` whose type
> holds an `Async` is refused where it is declared, on every target. The annotation `#[beamMemory(.<member>)]` picks
> how the BEAM holds a module `var` (§ `beamMemory`); off the BEAM it is accepted and has no effect — the `var` means
> the same on every target (decision 547).

### A new `### beamMemory — how the BEAM holds a module var`, the validation half

> `#[beamMemory(.<member>)]` above a module `var` names how erlang and beam hold it. The member is one of two, a closed
> enum: `Ets` (the default, which a bare `var` already means) or `PersistentTerm`; any other value is refused at the
> annotation. Every part is checked at `botopink check`:
>
> ```botopink
> #[beamMemory(.Ets)]                var hits: i32 = 0;   // the default, said out loud
> #[beamMemory(.PersistentTerm)]     var buildVersion: i32 = 101;
>
> // #[beamMemory(.Etz)] var x: i32 = 0;
> //   error: unknown member `Etz` in `beamMemory` — expected `Ets` or `PersistentTerm`
> // #[beamMemory(.Ets)] val x: i32 = 0;
> //   error: `#[beamMemory(.Ets)]` needs a `var` — `x` is a `val`
> ```
>
> The annotation takes the plain form only: `#[…] val add = fn …` and the other `val` shorthands
> are refused at the annotation.

---

## Part 2 — the two members (`docs.md` § `beamMemory`)

> **`Ets`** — the default: one value for the whole program in a one-row ETS table. The program's runtime creates every
> module `var`'s table at boot, in a process that lives as long as the program, and runs the initializers once; a table
> never belongs to the first process that touches the `var`, so it never dies with it. A reassignment that reads the
> `var` it writes is read, computed and written back against the value read (`ets:select_replace`), retried when another
> process wrote in between, so no write is lost; a plain `x = v` is one insert. **`Ets` is cache and counting memory,
> not where the truth lives** — a balance, an order, a paid session belong in a supervised process or a database.

> **`PersistentTerm`** — for a `var` written rarely and read much: a read costs a function call, and a write scans
> every process heap (measured, 810 ns against 17 ns for a read) — the cost is the writer's to weigh; nothing refuses
> the write. It is the member for a routes table, a scanned-component list, configuration read at bootstrap. Store a
> handler by **name**, not as a function value: a `fun` belongs to the module version that created it and dies with
> it on reload.

`Dict.bump(key, by)` (decision 340) is a plain `Dict` method, `insert(key, (at(key) ?? 0) + by)`, under any member (547).
