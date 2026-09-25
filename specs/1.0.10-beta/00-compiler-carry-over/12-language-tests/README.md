# Front 12 — language tests

**Priority:** high — this is the only suite that asserts what a botopink **program does**, on more
than one backend, rather than what the compiler emits. Every unowned row the last two milestones
carried was found by a library failing, not by a test; the cells written since are how that stops.
**Depends on:** nothing to write a cell. Step 2's re-classification needs
[`01-checker`](../01-checker/README.md) and the four backend fronts to have landed *something* — it is
run after each landing, not once
**Owns:** `repository/botopink-lang/tests/language/**` — the cells, their `.out`/`.expect` files,
`expected-failures.txt`, `run.sh` and `AGENTS.md`
**Does not touch:** any compiler source, `libs/std/**`, `examples/**`, any snapshot directory,
`build.zig`, `scripts/**` — except step 3, which needs one `run.sh` change and, if the maintainer
takes option A, one line in `scripts/gate.sh`. A cell that fails is recorded as an expected failure
naming the front that owns the fix, **never** fixed here.

Measured at `botopink-lang` `c2dd780`, 2026-09-18, node v25.8.0, OTP 29.

---

## Current state

```
$ zig build test-language
language tests: 205 passed, 54 expected failures, 0 failed
```

| Kind | `.bp` cells | Runs on |
|---|---|---|
| `test/` — `test "…" { assert … }` blocks | 40 | commonJS, erlang |
| `run/` — a whole program, stdout is the assertion | 6 | commonJS, erlang, wasm |
| `reject/` — must not compile | 22 | once (`check` is target-independent) |
| `modules/` — a whole project with its own `botopink.json` | 3 | commonJS, erlang, wasm |
| **total** | **71** cells, 75 `.bp` files | |

`tests/language/AGENTS.md` is the layout and the rules; it is this front's file and is **stale in one
place**: its status table records "**196 results pass and 61 are expected failures**", classified in
the front-17 worktree on top of `26d4fdc`. The suite is 205/54 at `c2dd780` — seven
`expected-failures.txt` lines were deleted by the checker landings and nine more results now pass.

## Problem

### P1 — every owner row in `expected-failures.txt` names a milestone that no longer exists

All 54 lines cite 1.0.4-beta front numbers. The runner enforces that a line names an owner
(`AGENTS.md`: "The owner row must exist in the specs … **A cell whose owner is nobody is reported to
the maintainer, not listed against an invented row**"), so a stale owner is a broken contract, not a
cosmetic.

Counted at `c2dd780`:

| Cited owner | Lines | Is now |
|---|---|---|
| `01 step 6` | 21 | split by target: **erlang 12** → [`02-erlang`](../02-erlang/README.md) · **commonJS 5** → [`04-js`](../04-js/README.md) · **wasm 4** → [`05-wasm`](../05-wasm/README.md) |
| `06 N22` (alone or with N19/N20/N21/N28) | 23 | [`01-checker`](../01-checker/README.md) |
| `06 N25` | 3 | [`01-checker`](../01-checker/README.md) |
| `06 N1`, `06 N12`, `06 N18` | 2 each | [`01-checker`](../01-checker/README.md) |
| `06` — `reject/external_lowercase_target.bp` | 1 | **nobody.** It cites "a `fronts.md` unowned item", which is the shape `AGENTS.md` forbids |

By target: 21 erlang, 16 commonJS, 12 `*` (reject), 5 wasm.

### P2 — the suite says nothing about a named type's run-time identity

`grep -rln 'is [A-Z]' test run reject` matches **one** cell (`test/case_arms.bp`). Nothing asserts:

- `Person(name: "Ana", age: 30) == Vec(name: "Ana", age: 30)` — two different types with the same
  fields;
- `p is Person` on a value whose static type is a union or `unknown`;
- `@print(p)` naming the type (`Person(name: "Ana", age: 30)`, decision 8 §7);
- a `case` over a value of a union of two **named** types.

That is the whole subject of [`13-module-identity`](../13-module-identity/README.md) — a type gets a
unique atom and the atom goes **inside the value** — and it has no botopink-level cell. The `case`
cells that exist (`case_variants`, `case_values`, `case_exhaustive`, `case_unknown`) fail *earlier*
than identity today: their `expected-failures.txt` reasons are checker reasons
(`.Variant` arms are not resolved against the matched value's type; an arm body is a lambda the checker
does not unwrap; a union annotation is not a union type yet). **So their current owner is
[`01-checker`](../01-checker/README.md) and that is correct** — but when 01 lands, some of them will
fail again for the run-time reason, and those lines move to
[`13-module-identity`](../13-module-identity/README.md), not to a backend front. Step 2 is that
re-classification, done by running.

### P3 — beam is excluded, and the reason is narrower than the document says

`tests/language/AGENTS.md`'s target table says beam "writes `out/main.S` and stops — a BEAM Assembly
artifact, not a run" and is therefore excluded, "because nothing executes: a `run/` cell would compare
an empty stdout and pass vacuously."

Measured at `c2dd780`, the first half is right and the conclusion is not:

```
$ botopink test --target beam
error: `botopink test` currently supports only the commonJS and erlang targets
 hint: run with `--target commonJS` or set "target": "commonJS" in botopink.json

$ botopink run --target beam
   Compiled in 70.32ms
wrote out/main.S — BEAM Assembly is an artifact; compile with `erlc +from_asm out/main.S` to produce a `.beam`.
$ ls out/
main.S

$ cd out && erlc +from_asm main.S && ls
main.beam  main.S
$ erl -noshell -pa . -eval 'main:main(), halt().'
hi
```

**The beam output executes, in two commands the gate already has** — `erlc` is a dependency of every
erlang cell and of `scripts/beam_export_audit.sh`, which is gate stage 5. What is missing is a runner
step, not a compiler change. That is a decision, not an assumption; see
[Decisions the maintainer owes](#decisions-the-maintainer-owes).

### P4 — the capabilities no cell reaches

`AGENTS.md`'s closing section lists what cannot be tested from botopink at all, with a reason each:
`@Context` / `use`; `pub default mod` / `pub default fn`; `@ExprCustom` / `q.custom`; `.d.bp` shipped
through `botopink.json` `files`; "no external target for the active backend"; `@typeInfo` /
`@makeRecord` / `partial` / `omit` / `pick`; `@panic` / `@todo`. Each of the first four is a
*dependency's* surface — the suite deliberately does not fetch one, because `zig build test-libs` is
that job and this suite must not need the network.

Three of those reasons are worth re-testing rather than carrying:

| Capability | The stated reason | Worth re-measuring because |
|---|---|---|
| `pub default mod` / `pub default fn`, `@ExprCustom`, `.d.bp` via `files` | needs a dependency | a `modules/` cell **is** a whole project. A second project inside it, resolved by a relative `BOTOPINK_LIB_ROOTS`, is a local dependency with no network |
| "no external target for the active backend" | `reject/` runs `check`, which is target-independent | a `run/` cell on one target, expected to fail, says the same thing — and `botopink build --target <t>` is not target-independent |
| `@panic` / `@todo` | a cell that aborts reports no result through `--json` | a `run/` cell compares stdout **and exit status**; an aborting program is exactly what it can assert |

### P5 — the coverage numbers in `AGENTS.md` do not match the suite

Its table sums to 68 cells and its classification line reads 196/61. The suite is 71 cells and 205/54.

## Steps

### Step 1 — repoint every owner row, and give the orphan one

Rewrite all 54 `expected-failures.txt` owner cells to 1.0.5-beta fronts, by the mapping in
[P1](#p1--every-owner-row-in-expected-failurestxt-names-a-milestone-that-no-longer-exists), and settle
`reject/external_lowercase_target.bp`.

That cell asserts that `#[@external(node, "console.log($0)")]` — the lower-case form — is a **located
error**. Today it passes `check`, binds no host and says nothing. Whether it should be an error is a
decision [`08-hygiene`](../08-hygiene/README.md) D3 raises; its implementation site is the annotation
grammar, [`01-checker`](../01-checker/README.md)'s.

**Acceptance:**
- [ ] Every line's owner cell names a 1.0.5-beta front and, where the front has numbered rows, one of
      them
- [ ] The 21 `01 step 6` lines are split 12 / 5 / 4 across
      [`02-erlang`](../02-erlang/README.md), [`04-js`](../04-js/README.md),
      [`05-wasm`](../05-wasm/README.md) — by the target in column 1, not by guess
- [ ] `reject/external_lowercase_target.bp` names a real row, or the cell is deleted with the decision
      that deleted it written in `AGENTS.md`
- [ ] `zig build test-language` still reads 205 passed, 54 expected failures, 0 failed — repointing an
      owner changes no result
- [ ] `AGENTS.md`'s owner-row rule names the 1.0.5-beta fronts

### Step 2 — re-classify after each landing, and route the identity rows

Run the suite after every front of this milestone lands and re-derive each remaining line's **reason**,
not only its owner. A line whose failure has changed shape moves to the front that now owns it; a line
that passes is deleted by the landing front, and the runner already fails if it is not ("now passes:
delete its line").

The rows to watch are the ones in [P2](#p2--the-suite-says-nothing-about-a-named-types-run-time-identity):
after [`01-checker`](../01-checker/README.md) resolves `.Variant` arms and union types, a `case` over
two named types and an `is` on a named type either work or fail because **the value does not know its
own type** — and that is [`13-module-identity`](../13-module-identity/README.md)'s, not a backend
front's.

**Acceptance:**
- [ ] After each landing: the suite run, `0 failed`, and every surviving line's reason re-derived from
      the actual output, quoted in the line
- [ ] No line names a front that has closed
- [ ] The lines that survive [`01-checker`](../01-checker/README.md) with a run-time reason name
      [`13-module-identity`](../13-module-identity/README.md)

### Step 3 — the beam answer, acted on

Decide (below) and implement.

If beam joins the suite: `run.sh` gains a beam path — `botopink run --target beam`, then
`erlc +from_asm out/main.S`, then `erl -noshell -pa out -eval '<mod>:main(), halt().'` — and the `.out`
comparison is unchanged. `test/` cells stay out until `botopink test` accepts the target, which is a
CLI row, not this front's.

If it does not: `AGENTS.md`'s target table is corrected — "the artifact executes after
`erlc +from_asm`; the suite does not run it because \<reason\>" — so the next reader does not re-derive
this.

**Acceptance:**
- [ ] `tests/language/AGENTS.md`'s target table states the measured behaviour of all four targets,
      with the commands
- [ ] If beam is added: every `run/` and `modules/` cell has a beam result, each pass or expected
      failure, and the new expected failures name [`03-beam`](../03-beam/README.md)
- [ ] If beam is added: `erlc` is already a gate dependency (stage 5, `beam_export_audit.sh`) — no new
      tool in the gate, verified by running `scripts/gate.sh --cold` on a machine without anything
      installed beyond what it needed before

### Step 4 — the cells that are missing

Write them, one commit per capability group, each run on every target it declares before it is listed.

1. **Run-time type identity** ([P2](#p2--the-suite-says-nothing-about-a-named-types-run-time-identity)) — a `run/` cell and a `test/` cell:
   two types with identical fields comparing unequal; `is` on a named type through a union and through
   `unknown`; `@print` of a record and of a variant naming the type (§7); a `case` over a union of two
   named types. Expected failures against
   [`13-module-identity`](../13-module-identity/README.md). **These cells are the acceptance evidence
   for that front**, so they are worth writing before it starts, not after.
2. **A local dependency** ([P4](#p4--the-capabilities-no-cell-reaches)) — a `modules/` cell holding two
   projects, the second resolved through a relative `BOTOPINK_LIB_ROOTS`, covering `pub default mod` /
   `pub default fn`, a `.d.bp` shipped through `files`, and `@ExprCustom` / `q.custom`. No network.
3. **`@panic` / `@todo`** — a `run/` cell asserting stdout **and** a non-zero exit.
4. **"no external target for the active backend"** — a `run/` cell on one target, per
   [P4](#p4--the-capabilities-no-cell-reaches).

**Acceptance:**
- [ ] `zig build test-language` green, with the new cells, on every target each declares
- [ ] Every added `expected-failures.txt` line names an existing 1.0.5-beta row
- [ ] Anything with no owner is reported here and to the maintainer, not listed against an invented row
- [ ] `AGENTS.md`'s "what cannot be tested from botopink at all" list loses the entries step 4 covers,
      and each remaining entry keeps its reason

### Step 5 — `AGENTS.md` matches the suite

**Acceptance:**
- [ ] The coverage table's cell counts equal what is on disk, per directory, with the command that
      counted them
- [ ] The classification line quotes the current run (`zig build test-language`) and the commit it was
      run at
- [ ] The "shapes that do not parse" list is re-derived: the entries that now parse — `Pattern { body }`
      arms and §5.3b are listed there as `06 N22` — are struck or moved

## Gate

- [ ] `scripts/gate.sh --cold` green in this front's worktree
- [ ] `zig build test-language` green on every target the suite declares
- [ ] `tests/language/AGENTS.md` updated in the same commit as any cell or owner-row change
- [ ] Commit on `fix/language-tests`; no push, no merge — landing is the maintainer's step

## Blast radius

**None on the compiler**: this front adds no source change and re-records no snapshot. It moves the
number of known-red cells up, which is the point — every line it adds to `expected-failures.txt` is a
promise the language makes and does not keep, made visible to the front that owns it.

Two interactions to plan for:

- **`expected-failures.txt` is shared, delete-only.** Every other front of this milestone deletes a
  line when its row lands, and the runner fails if it does not. Step 1 rewrites all 54 owner cells at
  once, so it must land **before** any front starts deleting — otherwise two commits touch the same
  line.
- **Step 3, if beam is added, roughly doubles the `run/` and `modules/` results** (6 + 3 cells gain a
  target) and adds two subprocess calls per cell to the suite's wall time.

<a id="decisions-the-maintainer-owes"></a>

## Decisions the maintainer owes

1. **Does the suite run beam?** The artifact executes — `botopink run --target beam` then
   `erlc +from_asm out/main.S` then `erl -noshell -pa out -eval 'main:main(), halt().'` prints `hi`,
   measured at `c2dd780` — and `erlc` is already a gate dependency. The cost is a `run.sh` path and
   suite time; the gain is that decision 8's run-time half stops being asserted on beam only by
   `snapshots/codegen/beam/`.
2. **Is a lower-case `#[@external(node, …)]` a located error?** Also
   [`08-hygiene`](../08-hygiene/README.md) D3. One `reject/` cell has been listed against a
   non-existent row since front 17 wrote it; it needs an owner or a deletion.
3. **Does a range pattern's end include its endpoint?** `1...9` in a `case` arm parses and checks green
   at `c2dd780`; `loop (0..4)` is exclusive. Decision 8 does not say, and the cells route around the
   edge (`AGENTS.md`'s closing note). One sentence settles it and unblocks a cell.

## Notes

- **Tests describe the language, not today's compiler.** A scenario the compiler gets wrong stays as
  written and is listed in `expected-failures.txt`. Never rewrite a cell to match current behaviour —
  the rule is in `AGENTS.md` and it is what makes the file an inventory of open promises rather than a
  log.
- `test/case_arrow_arms.bp` exists beside `test/case_arms.bp`: both arm forms parse at `c2dd780`, and
  the suite pins both. Whether the arrow form stays in the language is decision 8's §5.1 reading and
  not this front's to settle; the cell is how a removal would be noticed.
- A cell that needs a git dependency stays out of scope — that is `zig build test-libs`' job, and this
  suite must not need the network. Step 4's item 2 is a *local* second project, which is not the same
  thing.

---

## Rows for `fronts.md`

**Ownership table:**

```markdown
| **12** [`language-tests`](./README.md) | `repository/botopink-lang/tests/language/**` — the cells, `expected-failures.txt`, `run.sh`, `AGENTS.md` | — | not started — step 1 lands before any front deletes an expected-failure line |
```

**Conflict notes** (against the other thirteen fronts):

| With | Verdict | Why |
|---|---|---|
| **01 checker** | yes, **but step 1 lands first** | 32 of the 54 expected-failure lines are 01's, and 01 deletes each as its row lands. The file is shared delete-only; step 1 rewrites every owner cell at once, so it must precede the first deletion |
| **02 erlang · 03 beam · 04 js · 05 wasm** | yes, same rule | 12 / 0 / 5 / 4 of the `01 step 6` lines are theirs after step 1's split. 03 gains lines only if the maintainer adds beam to the suite (step 3) |
| **06 comptime-dedup · 07 review-backlog · 08 hygiene · 11 tooling** | yes | No shared file, no shared snapshot directory. 08's D3 decision is what lets step 1 give `reject/external_lowercase_target.bp` an owner |
| **09 ecosystem-residuals** | yes | Different repositories. The five libraries and these cells exercise the same features from opposite ends |
| **10 cli-residuals** | **seq** — 10 first | 10 step 1 and step 2 change what `check` and `test` reject, which is what `reject/` cells assert. No shared file; re-run the suite after |
| **13 module-identity** | **no** — 12's step 4.1 first, then 13 | Step 4's identity cells are 13's acceptance evidence and should exist before it starts. Step 2 then routes the surviving `is` / union / named-`case` lines to it. 13 also changes the erlang output layout the three `modules/` cells execute |
| **14 comptime-on-beam** | yes | It changes how a comptime body is evaluated; `test/comptime_template.bp`, `test/decorator_emit.bp` and `test/decorator_reflect.bp` run that path and re-run after it. No shared file |

**Front-table row (`overview.md`):**

```markdown
| [`12-language-tests`](./README.md) | high | not started — step 1 first of the milestone | The suite is at 205 passed / 54 expected failures / 0 failed, and every one of those 54 owner rows names a 1.0.4-beta front number, one of them a row that never existed. Plus the cells still missing: nothing asserts that a value knows its own type — the whole subject of `13-module-identity` has no botopink-level test — and beam is excluded on a reason that does not hold: `erlc +from_asm out/main.S` and `erl -eval` run the artifact, with a tool the gate already has |
```

---

## Handed over by `15-language-surface` (2026-09-18, `109f6c9`)

**`tests/language/AGENTS.md:183-186` is now doubly obsolete.** Its `??` and module-`var` lines still
read "deliberately absent (14)", and [decision 28](../../../1.0.5-beta/decisions-taken.md) reversed the first: `??`
parses as of `fb230e5`. The `??` line also repeats the premise this milestone already measured as
false — that `catch` covers it; `catch` is `@Result`-only.

**Cells that can now be written** (the forms landed, the backends have not): `xs[0]` and `xs[0..2]`
reach the unrecognised-builtin path on all four backends until fronts 02–05 lower them, so index cells
belong in `expected-failures.txt` with those owners, not as passing cells.

**Decision 29, when it lands**, moves **44** sites in this suite — not the 88 the decision estimated.
The count is the compiler's, and the migration is coordinated with
[`16-formatter`](../16-formatter/README.md) and [`15-language-surface`](../15-language-surface/README.md).

---

## Landed — 2026-09-18

**This README's premise did not hold: step 1 had already landed at `7ab6a55`**, before this wave
started. Every owner cell in `expected-failures.txt` already named a 1.0.5-beta front, re-checked one
by one against `specs/1.0.5-beta/` — 01 steps 1–8, 02 steps 1/5/6/7, 03 steps 2/4, 05 steps 1/3, 13
steps 2/15/17/18 — and **none is orphaned**. `reject/external_lowercase_target.bp`, "the row that
never existed", is not listed at all any more: `e37186b` made the cell pass and deleted its line.
Steps 2, 3, 4.1 and 5 had landed too (`fcc4b5b`, `eeff1e1`, `7b96ce7`). **The file was safe to delete
lines from all along**, which means the wave's coordination rule — backends report, 12 deletes — was
caution, not a dependency.

| commit | what |
|---|---|
| `aab5489` | the header block re-derived from a run: it still claimed 205/54 at `c2dd780`, with seven `04-js` lines that no longer existed |
| `7bfecf7` | `AGENTS.md`'s "shapes that do not parse" table re-measured — **5 of its 7 rows now parse** |
| `5dfb638` | 7 new cells for decisions 28, 30 and 33 |
| `23eea0b` | the header's numbers and base sha corrected after the cells moved them |

| | before | after |
|---|---|---|
| `run.sh` (commonJS, erlang, wasm) | 218 passed / 53 expected / 0 failed | **250 / 61 / 0** |
| `run.sh --target beam` | 13 / 19 / 0 | **14 / 20 / 0** |
| `expected-failures.txt` lines | 61 | **70** |
| cells on disk | 76 | **83** |

Neither "53 lines" nor "54 rows" was right: the file was at 61 lines, and 53 is how many `--target all`
exercises. **No line was found passing**, before or after.

**Four defects the cells found, and nothing else had:**

1. **beam drops an index silently and exits 0.** The other three targets die loudly (`SyntaxError`;
   `'[]'/2 undefined`; wasm refuses to validate); beam prints the whole array for `xs[0]`, and `ok`
   for `xs[0..2].length` and `rows[1][0]`. A backend that is wrong quietly is the reason a suite
   exists — [`03-beam`](../03-beam/README.md).
2. **commonJS: the optional-binding `if` emits `if (n !== null)` while `?.` answers `undefined`**, so
   `o.inner?.v ?? 9` answers `undefined` on commonJS and `9` on erlang and wasm.
   `test/optional.bp` never saw it because its optionals are explicit `null`s. **No step of
   [`04-js`](../04-js/README.md) named this.**
3. **commonJS: `42.toString()` emits `__bp_print(42.toString())`**, which node refuses — `42.` reads as
   a float — while erlang and wasm print `42`. Recorded in a cell comment rather than asserted,
   because a listed line needs a row.
4. **A tuple label does not survive a generic array method** — `rs.at(0).b` answers `undefined` on
   commonJS, raises `bad map: {1,<<"x">>}` on erlang and `0` on wasm. This one has rows, so it is
   asserted: §6 T4 → `04 step 2`, `02 step 4`.

**Two spec premises that did not reproduce**, both now corrected in the specs rather than here:
decision 28's landing note read as if module-level `var` parses — it does not (`this token cannot
appear here` at `1:1`), and its semantics are [`17-beam-memory`](../17-beam-memory/README.md); and
decision 30's "one lowering in each of fronts 02–05" has no numbered step in any of those fronts, only
a handover section, so the new owner cells read `<front> handover 15` and `AGENTS.md` documents the
convention.

**Deliberately left undone:** the range cells, because decision 36's sentence is still not in
decision 8 §5 and the parser still refuses `1..9` in a pattern. The measurement was extended while
looking: `val r = case 9 { 1...9 { 1 } _ { 0 } }; @print(r);` prints `undefined` on commonJS, `0` on
erlang and **`256` — a heap address — on wasm**; written where its type is known it does not compile
at all. Three backends, three wrong answers; the cell is owed once `01 step 4` lands. Also out:
`d["k"]` (needs `from "std"`, whose own rows would hide the index reason) and `s[1]` (decision 30
leaves a string element's type and printed form open).

