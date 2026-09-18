# Front 17 — language test expansion (the rest of the language)

**Priority:** high — every front below 17 is verified by unit tests written in Zig against the
compiler's internals; the only tests written **in botopink**, running the emitted program, are
[`15-language-tests`](../15-language-tests/README.md)'s 34 files, and they cover decision 8 alone.
**Depends on:** [`15-language-tests`](../15-language-tests/README.md) (delivered — the harness,
the layout and `expected-failures.txt` are its) and on
[`12-surface-cutover`](../12-surface-cutover/README.md) (delivered — every cell uses the 1.0.3
surface).
**Owns:** `repository/botopink-lang/tests/language/**` (the new cells and their `AGENTS.md`) ·
the lines it adds to `tests/language/expected-failures.txt`
**Does not touch:** any compiler source, `libs/std/**`, `examples/**`, any snapshot directory,
`build.zig`, `scripts/**` — the `test-language` step and its gate stage already exist and belong to
15. A cell that fails is recorded as an expected failure naming the front that owns the fix, never
fixed here.

---

## Problem

`tests/language/` pins decision 8 and nothing else. Measured at `botopink-lang` `1193d3c`:

| Directory | Files |
|---|---|
| `test/` (assert-based) | 17 |
| `run/` (stdout is the assertion) | 3 |
| `reject/` (must not compile) | 14 |
| **total** | **34** |

All 34 are `case`/patterns, tuples, `loop`, `is`, unions, `unknown` and printing — §2–§7 and §10 of
[decision 8](../08-review-backlog/decision-8-language.md). The features the ecosystem actually runs
on have no botopink-level test at all: comptime parameters and templates (`@Expr`, `@ExprCustom`,
`@expr`), decorators and annotation processors (`#[…]`, `@emit`, `@Decl` reflection), effects
(`#[@result]`, `#[@future]`, `#[@generator]`, `#[@context]`), generics and `behavior` dispatch,
modules (`import`, `pub default`), and host externals (`#[@external(…)]`). Each of those is covered
only by Zig unit tests and snapshots — which pin *what the compiler emits*, not *what the program
does*, and never on more than one backend at a time.

The five libraries are the evidence that this matters: emilia, erika, jhonstart, onze and rakun are
built out of exactly those features, and every regression they have hit
([`fronts.md` § unowned items](../fronts.md#unowned-items)) was found by a library failing, not by a
test.

## Current state

The gap analysis, the capability inventory and the example programs are being authored in
[`15-language-tests/`](../15-language-tests/README.md) — a capability-by-capability reading of the
compiler's own test suites, `libs/std/**`, `docs.md` and the five libraries, each proposed cell with
a program that was run. **That analysis is this front's input**: it says what to write; this front
writes it.

## Steps

### Step 1 — land the inventory

Take the analysis into `tests/language/` as a written plan: which cells, in which directory
(`test/`, `run/`, `reject/`), in which order, and for each one whether it is expected to pass today
or to be an expected failure and whose row makes it pass.

**Acceptance:**
- [ ] every capability in the inventory is either covered by a proposed cell or has one line saying
      why it cannot be tested from botopink

### Step 2 — the cells that pass today

Write them, one commit per capability group. A cell that passes on both targets goes in green.

**Acceptance:**
- [ ] `zig build test-language` green, with the new cells, on `commonJS` and `erlang`
- [ ] no line added to `expected-failures.txt` for a cell in this step

### Step 3 — the cells that fail today

Write the ones the language promises and the compiler does not deliver, and record each in
`expected-failures.txt` against the row that owns it (06's N-rows, 01 step 6, a `fronts.md` unowned
item). A cell whose owner is nobody is reported, not invented.

**Acceptance:**
- [ ] every added line names an existing owner row
- [ ] the runner still fails when a listed test passes (15's rule: delete the line in the same commit)
- [ ] anything with no owner is listed in this README's Notes and in
      [`fronts.md` § unowned items](../fronts.md#unowned-items)

### Step 4 — the backends the cells run on

`tests/language/botopink.json` targets `commonJS` and `erlang`. Say — measured, by running it —
what it would cost to add `beam` and `wasm`, and either add them or record why not.

**Acceptance:**
- [ ] a run of the suite per target, with its result recorded here

## Gate

- [ ] `scripts/gate.sh --cold` green in this front's worktree
- [ ] `zig build test-language` green on every target the suite declares
- [ ] `tests/language/AGENTS.md` updated in the same commit
- [ ] Commit on `fix/language-test-expansion`; no push, no merge — landing is the maintainer's step

## Blast radius

None on the compiler: this front adds no source change and re-records no snapshot. It moves the
number of known-red cells up, which is the point — every line it adds to `expected-failures.txt` is
a promise the language makes and does not keep, made visible to the front that owns it.

## Notes

- Runs in parallel with every compiler front: it shares no source file and no snapshot directory.
  The one shared file is `tests/language/expected-failures.txt`, whose lines 06 and 01 step 6 delete
  as their rows land — a delete-only interaction, but it sequences a landing, not the work.
