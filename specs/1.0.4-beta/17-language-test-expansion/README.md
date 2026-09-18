# Front 17 — language test expansion (the rest of the language)

**Delivered** 2026-09-17/18 (`botopink-lang` merge `2f44b30`, closed out by `8433086`): **37 cells**
beyond front 15's 31, taking `tests/language/` from decision 8 alone to the language the ecosystem
actually runs on. With the three smoke files the suite is 71 files; at the milestone's last
merge (`c2dd780`) it reads **205 passed, 54 expected failures, 0 failed** across every target.

**Owned:** `repository/botopink-lang/tests/language/**` (the new cells and their `AGENTS.md`) · the
lines it added to `tests/language/expected-failures.txt`.
**Touched no compiler source, no `libs/std`, no `examples/`, no snapshot directory, no `build.zig`,
no `scripts/**`** — the `test-language` step and its gate stage are 15's. A cell that fails is
recorded as an expected failure naming the front that owns the fix, never fixed here.

---

## Problem

`tests/language/` pinned decision 8 and nothing else. Measured at `botopink-lang` `1193d3c`: 17
`test/`, 3 `run/`, 14 `reject/` — 34 files, all of them `case`/patterns, tuples, `loop`, `is`,
unions, `unknown` and printing (§2–§7 and §10).

The features the ecosystem is built out of had no botopink-level test at all: comptime parameters and
templates (`@Expr`, `@ExprCustom`, `@expr`), decorators and annotation processors (`#[…]`, `@emit`,
`@Decl` reflection), effects (`#[@result]`, `#[@future]`, `#[@generator]`, `#[@context]`), generics
and `behavior` dispatch, modules (`import`, `pub default`), and host externals
(`#[@external(…)]`) — covered only by Zig unit tests and by snapshots that pin *what the compiler
emits*, not *what the program does*, and never on more than one backend at a time. The five
libraries were the evidence: every regression they hit was found by a library failing, not by a test.

Its input was front 15's phase-2 analysis
([`capability-inventory.md`](../15-language-tests/capability-inventory.md),
[`gap-analysis.md`](../15-language-tests/gap-analysis.md),
[`example-programs.md`](../15-language-tests/example-programs.md),
[`proposed-layout.md`](../15-language-tests/proposed-layout.md)).

## Delivered

| Step | What landed | Commits |
|---|---|---|
| 1 — the inventory | Every capability in the inventory is either covered by a cell or has one line saying why it cannot be tested from botopink. That list is in `tests/language/AGENTS.md` and is reproduced below | `8433086` |
| 2/3 — the cells | 37 cells, one commit per capability group: effects and §9's four rejection rules (`66a3ad3`), comptime parameters, `@Expr` templates and decorators (`d87a021`), §8 host externals (`b3c9691`), closures, recursion, primitives, optionals and sugar (`e4dc92a`), generics and `behavior` dispatch (`258e62f`), the `case` the libraries are written in and §5.3b (`f366376`), §7's formatter table (`1be48e9`) | merge `2f44b30` |
| 4 — the targets | A **`modules/` kind** — a whole project with its own `botopink.json` and `src/` tree, because one file cannot hold a module tree (`f699517`) — and **wasm as a third executable target** for `run/` and `modules/`; **beam measured and refused**: `botopink test` will not run it and `botopink run` writes `out/main.S` and stops, so a `run/` cell would compare an empty stdout and pass vacuously (`89f3761`) | `f699517`, `89f3761` |

### Coverage, as the suite records it

| Area | Cells | Total |
|---|---|---|
| `case` (§5) | 8 test + 1 run + 9 reject | 18 |
| tuples (§6) | 6 test + 1 run + 2 reject | 9 |
| `loop` (§10) | 6 test + 2 reject | 8 |
| effects (§9) | 5 test + 5 reject | 10 |
| comptime, templates, decorators | 3 test | 3 |
| host externals (§8) | 2 test + 1 reject | 3 |
| generics and behaviors (§1) | 1 test + 2 reject | 3 |
| printing (§7) | 3 run | 3 |
| core: closures, recursion, primitives, optionals, sugar, defaults | 8 test | 8 |
| modules | 3 `modules/` cells | 3 |

| Target | `botopink test` | `botopink run` | In the suite |
|---|---|---|---|
| commonJS | yes | yes | every kind |
| erlang | yes | yes | every kind |
| wasm | refused | yes, it executes | `run/` and `modules/` only |
| beam | refused | writes `out/main.S` and stops | **no** |

## Gate

- [x] `scripts/gate.sh --cold` green in this front's worktree
- [x] `zig build test-language` green on every target the suite declares — **205 passed, 54 expected
      failures, 0 failed** at `c2dd780` (node v25.8.0, OTP 29)
- [x] Every added expected-failure line names an owner row that existed when it was written
- [x] The runner still fails when a listed test passes — four lines were deleted by the merge that
      made them pass (`c2dd780`: `test/tuple_fn_field.bp` on both targets, `test/effect_val_assert.bp`
      on both)
- [x] `tests/language/AGENTS.md` updated in the same commit

## What it left, and where

Everything below is **1.0.5-beta `12-language-tests`** unless a row names another front.

### The handoff that has to happen first

**All 54 expected-failure lines name 1.0.4-beta rows.** `tests/language/AGENTS.md` requires the owner
row to exist in the specs, so every line has to be re-pointed as the 1.0.5-beta fronts are written.
The histogram at the close of the milestone:

| Owner as written | Lines | Now owned by |
|---|---|---|
| `01 step 6` | 21 | `02-erlang` · `03-beam` · `04-js` · `05-wasm` — the §7 formatter on three backends, the erlang generator protocol, erlang cross-module calls, `String.toUpperCase`, `ConditionLoopValueUnsupported`, tuple equality on commonJS |
| `06 N22` (alone or combined) | 23 | `01-checker` — the §5.1 `Pattern { body }` arm binding, exhaustiveness, `_` on `unknown`, guarded arms, arms that bind a section (§5.3b) |
| `06 N25` | 3 | `01-checker` |
| `06 N18` | 2 | `01-checker` |
| `06 N12` | 2 | `01-checker` |
| `06 N1` | 2 | `01-checker` |
| `06` (the lower-case external annotation, a 1.0.4-beta unowned item) | 1 | `01-checker` |

`06 N19`, `N20`, `N21` and `N28` carry no line of their own — each appears only inside a combined
`06 N22, 06 N…` owner, counted in the N22 row. 21 + 23 + 3 + 2 + 2 + 2 + 1 = 54.

### Cells not written

| Residual | Note |
|---|---|
| **`crash/`**, the kind [`proposed-layout.md`](../15-language-tests/proposed-layout.md) proposed for a cell that aborts — `@panic` / `@todo` report no result through `--json` | `12-language-tests` |
| **Area sub-directories** — the suite is still flat, one scenario group per file, with the area in the filename prefix | `12-language-tests` |
| **Shapes that do not parse**, found while writing the cells and routed around rather than filed: `(sql """ab""").length` (a template call needs a `val` intermediate before a method); `adder(3)(4)` (calling the result of a call); `(a == b).toString()` inside an argument; a bare `if` inside a decorator body must be the last statement; `??` is not an operator; a module-level `var` does not parse; the array suffix on a labeled tuple type, `#(a: i32, b: string)[]`. **Each would change if the maintainer decides it should parse** | a decision, then `01-checker` |

### What cannot be tested from botopink, and why

Written into `tests/language/AGENTS.md` so the next author does not re-derive it: `@Context` / `use`
(lowers to React hooks on commonJS, no erlang lowering — it needs a host framework); `pub default
mod` / `pub default fn` and `@ExprCustom` / `q.custom` (the package handle and the custom-AST carrier
are a *dependency*'s surface); `.d.bp` files shipped through `botopink.json` `files` (same); "no
external target for the active backend" (`reject/` runs `check`, which is target-independent);
`@typeInfo` / `@makeRecord` / `partial` / `omit` / `pick` (they produce types, and asserting on
emitted text is the snapshots' job); `@panic` / `@todo` (a cell that aborts reports no result). A
cell that needs a git dependency is deliberately out of scope — that is `zig build test-libs`' job,
and this suite must not need the network.

## Blast radius

None on the compiler: this front added no source change and re-recorded no snapshot. It moved the
number of known-red cells up, which is the point — every line it added to `expected-failures.txt` is
a promise the language makes and does not keep, made visible to the front that owns it.
