# Front 09 — ecosystem residuals

**Priority:** medium — the migration is done and every library compiles, runs and passes its cell.
What is left is one library with no erlang story, `format --check` red in four of five, and the
decision-8 items the checker has not reached.
**Depends on:** [`01-checker`](../01-checker/README.md) for the decision-8 items (§5.3b section paths,
§5.1 arm bodies) · [`13-module-identity`](../13-module-identity/README.md) for the erlang re-run — it
changes the erlang output layout and makes `botopink run --target erlang` reach a sibling module ·
[`10-cli-residuals`](../../../1.0.5-beta/10-cli-residuals/README.md) for the `.erl` half of `build`/`run`. Steps 1 and 2
can start now
**Owns:** `repository/{emilia,erika,jhonstart,onze,rakun}/**` — sources, `.d.bp`, tests, examples,
their markdown docs and `AGENTS.md` · the submodule pointers of those five in the meta repository
**Does not touch:** `repository/botopink-lang/**` · `repository/vscode-extension/**`
([`11-tooling`](../11-tooling/README.md))

Measured at the five libraries' checked-out commits (emilia `a02b6e8`, erika `97971a7`, jhonstart
`08e4744`, onze `7735d19`, rakun `db7e99c`) against `botopink-lang` `c2dd780`, 2026-09-18.

---

## Delivered, verified here

Re-measured, four of the five acceptance conditions are met across all five libraries, and the
rows that named them are closed.

| Claim | Measurement |
|---|---|
| the 1.0.3 surface, no `record` / `enum` / `interface` keyword and no `record {` literal | `grep -rInE '^\s*(pub\s+)?(record\|enum\|interface)\s+[A-Z]'` over every library's `src/`, `test/` and `examples/`: **no match**. No `while (` in any `.bp` |
| every library's cell passes | `zig build test-libs` → **11 passed, 0 failed, 0 known red, 1 skipped, 2 without tests**. jhonstart's and onze's **erlang** cells run and pass; the skip is rakun's erlang cell |
| the known-broken examples are fixed | **`scripts/known-broken-examples.txt` no longer exists in any library.** All eight example projects build; seven run to completion and rakun's is an HTTP server that does not exit. `emilia-card`, `jhonstart-counter`, `jhonstart-html`, `jhonstart-todo`, `erika-linq` and `onze` all print their output |
| `scripts/known-red-libs.txt` | empty at `botopink-lang` `c2dd780` |

### A row that no longer reproduces

The row read *"commonJS: a sibling-module import inside a dependency is emitted as
`require("../module")` — `emilia-card`, `jhonstart-counter`, `jhonstart-todo` build but fail at run
time `Cannot find module '../module'`"*.

**The symptom is gone.** All three build and run. The emitted text is now
`require("../jhonstart/element.js")`, which resolves from `out/jhonstart/hooks.js`.

It is gone because the libraries route around it, not because the compiler changed:
`jhonstart/src/html.bp:87-92` carries the reason in a comment and writes
`import { Element } from "element";` instead of the bare `import { Element };` shorthand —
"the bare shorthand type-checks, but commonJS lowers it to `require("../module")`, which resolves
inside this package and not when jhonstart is consumed as a dependency". `emilia/src/root.bp:57`
carries the twin comment. **The compiler row belongs to [`04-js`](../04-js/README.md)** and is not
this front's; the ecosystem row is closed, with the workaround documented in both libraries.

## Problem

Four residuals, each reproducible.

### R1 — `format --check` is red in four of five libraries

```
$ for l in emilia erika jhonstart onze rakun; do (cd repository/$l && botopink format --check); done
emilia     src/emilia.bp  src/root.bp  src/tokens.bp   → error: 3 file(s) would be reformatted
erika      src/erika.bp   src/root.bp                  → error: 2 file(s) would be reformatted
jhonstart  src/element.bp src/hooks.bp  src/html.bp    → error: 3 file(s) would be reformatted
onze       (clean)
rakun      src/decorators.bp src/runtime.bp            → error: 2 file(s) would be reformatted
```

**The formatter is stable and idempotent**: running `botopink format` on a copy and re-checking gives
`Unchanged` for every file in all four libraries. The sources were simply never run through it — and
two of the differences are the formatter losing information the parser never recorded, which is the
compiler row the 1.0.4-beta document named.

Classified by reading all four diffs:

| Class | Example | Verdict |
|---|---|---|
| **canonical form** — `import { Token }` → `import {Token}`; a one-line `fn` body expanded to a block; alignment padding in `case` arms removed; a multi-annotation `#[a, b]` split into `#[a]` `#[b]`; a trailing-comma list exploded one item per line | `jhonstart/src/element.bp:22-27` (six one-line `fn`s become six blocks) | run `format`, commit the output |
| **member reorder** — emilia's `Token`: the six payload variants declared **after** the sections (`Hover`, `Focus`, `Active`, `Md`, `Lg`, `Xl`) are hoisted **above** `Text {`, because the AST records variants and sections in two lists and the printer writes variants first | `emilia/src/tokens.bp:37` | **a compiler defect** — the parser records no member position. `01-checker` owns the parser |
| **blank lines dropped** — the empty line between `Text { … }` and `Font { … }` disappears | `emilia/src/tokens.bp` | same defect (no trivia recorded) |
| **trailing comment moved** — `import {Response} from "http"; // sibling module —` `// \`rkRegisterRoute\` names in its signature` : the continuation line, indented to align under the first, is re-emitted at column 0 | `rakun/src/runtime.bp:13-14` | same defect. The comment is not lost, but its indentation is |
| **end-of-line comment unpadded** — `c.set(9);            // G1: …` → `c.set(9); // G1: …` | `jhonstart/src/hooks.bp` | canonical form; harmless |

The 1.0.4-beta unowned row said an end-of-line comment "moves to the next line". At `c2dd780` it does
not — it loses its padding. The reorder and the blank-line loss do reproduce exactly as written.

### R2 — rakun has no erlang story

rakun's cell is the one `skipped` in `test-libs`, and the reason is in its own manifest, not the
compiler's:

```json
"targets": ["commonJS"]
```

Measured at `db7e99c`: **17 `@External.Node` cells in `src/runtime.bp` and 0 `@External.Erlang`** (2
more `External.Node` in `bootstrap.bp` and `root.bp`). `src/runtime.mjs` is **231 lines** — the DI
graph, the router and the HTTP server. emilia and onze each carry exactly one `External.Erlang` and
one `External.node` cell, which is why their erlang cells are green; rakun's surface does not fit an
inline expression.

`rakun/AGENTS.md:89-98` states the blocker as "the CLI has no `.erl` counterpart to `shipMjsSidecars`".
**That is now out of date.** `libs.shipErlSidecars` landed at `botopink-lang` `c01695f` and is wired
into `botopink test` (`modules/compiler-cli/src/cli/test_cmd.zig:189`). What is still missing is:

- the port itself — 231 lines of `runtime.mjs` written as an `.erl` module;
- `botopink build` / `run --target erlang` calling it. `cli/build.zig:215` calls `shipMjsSidecars`
  only; the one-line twin is [`13-module-identity`](../13-module-identity/README.md)'s, which owns
  that file.

### R3 — the decision-8 items the checker has not reached

| Item | Library | Blocked on |
|---|---|---|
| §5.3b — emilia's 27 section annotations become path names (`TokenText` → `Token.Text`, `TokenTextSize` → `Token.Text.Size`) | emilia (`src/tokens.bp`, `src/emilia.bp`'s 31 `case` sites) | [`01-checker`](../01-checker/README.md) N28 — a section is not yet a type named by its path; `tests/language/test/case_sections.bp` is an expected failure on both targets for exactly this |
| §5.1 — arm bodies written `Pattern { body }` instead of `pattern -> value;` | all five (emilia 31 `case` sites in `emilia.bp`, onze 6, jhonstart 1) | nothing — **both forms parse and run at `c2dd780`** (`case a { 0 { 1 } _ { 2 } }` checks green and prints `1`). This is a migration, not a blocker; it is listed so it is done once and not twice |

### R4 — the AGENTS.md files carry claims that have expired

`rakun/AGENTS.md:89-98` (above) is one. Each library's `AGENTS.md` was written when its cell was red
or its example broken; every such row needs re-deriving, because they are what the next reader trusts.

## Steps — one worktree per library

### Step 1 — `format` the four red libraries, and separate the canonical from the defective

Run `botopink format` over emilia, erika, jhonstart and rakun and commit the output — **except** where
the diff is one of the three information-losing classes in [R1](#r1--format---check-is-red-in-four-of-five-libraries).
For those, do not commit the reordered or de-trivia'd file: record it here against
[`01-checker`](../01-checker/README.md)'s parser rows, and leave the source as written.

Concretely, emilia's `src/tokens.bp` **must not** be formatted until the parser records member
positions — formatting it reorders a public enum's variants.

**Acceptance:**
- [ ] `botopink format --check` passes in erika, jhonstart, onze and rakun
- [ ] emilia's `format --check` passes for `src/emilia.bp` and `src/root.bp`; `src/tokens.bp` is
      excluded with a one-line reason in `emilia/AGENTS.md` naming the parser row
- [ ] Each library's cell and each of its examples still passes after formatting — run, not assumed
- [ ] `botopink format` run twice is a no-op everywhere (idempotency, re-verified per library)
- [ ] The three information-losing classes are registered in
      [`01-checker`](../01-checker/README.md)'s README with the file and line that shows each

### Step 1 — landed

Four commits, one per library, each through its own pre-commit gate; onze was already clean.

| library | commit | changed lines | `format --check` | `check` | cells |
|---|---|---|---|---|---|
| emilia | `3e7ab05` | 385 (260+/125−) — `emilia.bp`, `tokens.bp` | 2 red files → **exit 0** | 0 | 17 → 17 |
| erika | `02f4344` | 259 (145+/114−) — `erika.bp` | 1 red → **exit 0** | 0 | 31 → 31 |
| jhonstart | `78e01ca` | 204 (111+/93−) — `element.bp`, `hooks.bp`, `html.bp` | 3 red → **exit 0** | 0 | 2 → 2 |
| rakun | `6567b14` | 26 (7+/19−) — `decorators.bp`, `runtime.bp` | 2 red → **exit 0** | 0 | 4 → 4 |
| onze | — | 0, already clean | exit 0 | 0 | 8 → 8 |

**874 changed lines over 8 files**, not the 890 the handover from
[`16-formatter`](../16-formatter/README.md) measured — because this was measured at `bef762b`, which
carries front 14's merge as well as `37d3dc7`. The red-file counts shrank against this README's too
(emilia 3→2, erika 2→1): 16's fixes took files off the list before this front reached them.

**What was verified rather than assumed**, and this is the part that matters, because this front
commits a machine's rewrite of five human-written libraries:

- **Token-stream equality, per file.** The word-and-literal token sequence is byte-identical before
  and after in all eight files. Every delta is punctuation: brace pairs collapsed where
  `if (c) { x; }` becomes the expression form (erika 81, jhonstart 23), semicolons and trailing
  commas, and in emilia `#[a, b]` split into `#[a]` `#[b]` at 3 sites. **0 reordered members, 0
  deleted `default`** (emilia's `root.bp`: 3 before, 3 after).
- **Emitted output unchanged.** Each of the six example projects was built at HEAD and at the
  formatted source and `diff -r`'d: emilia-card, erika-linq, jhonstart-{counter,html,todo}, rakun —
  all byte-identical. Nothing changed behaviour, so nothing went back to front 16.
- `zig build test-libs` re-run from the main checkout after the four commits: **11 passed, 0 failed,
  0 known red, 1 skipped** (rakun's erlang, step 2's subject), **2 without tests** — the baseline
  exactly.

**One fidelity loss survives, and it is registered rather than worked around:**
`rakun/src/runtime.bp:13` — the continuation line of a trailing comment was indented to align under
the first, and the formatter re-emits it at column 0. Text intact, alignment gone. It is the last live
member of step 1's R1 classes and belongs to the trivia row of
[`16-formatter`](../16-formatter/README.md), which now owns the AST's trivia fields.

**Two documents were re-derived in the same commits**, because both had become false:
`emilia/AGENTS.md` still carried *"`botopink format` is not applied to `tokens.bp`"* — decision 34
withdrew the exemption and `37d3dc7` removed its cause; and `rakun/AGENTS.md` claimed a library cannot
ship an erlang host module because the CLI has no `.erl` counterpart to `shipMjsSidecars`, which is
false: `libs.shipErlSidecars` is at `modules/compiler-cli/src/cli/libs.zig:564`, called from
`test_cmd.zig:194`.

### Step 2 — rakun's erlang cell: decide, then act

**Superseded 2026-09-18 by [decision 17](../../../1.0.5-beta/decisions-taken.md#17-rakuns-erlang-story): none of A, B
or C.** The maintainer answered that rakun supports **every** target and that `libs/std` grows the
portable primitives its container, router and server rest on — so the gap is not rakun's to close
alone, and the work is scoped as its own thing rather than as a residual here. The table below is kept
as the measurement of what each option would have cost; **do not act on it**. What is still this
front's: the `"targets"` key and the `allow_fail` rows stop being the place the gap is recorded, and
`rakun/AGENTS.md:89-98` says what decision 17 says. One consequence is already measured, in step 1
above: the CLI half is **not** a blocker — `libs.shipErlSidecars` exists and is called.

| | Option | Cost |
|---|---|---|
| A | Port `runtime.mjs` to an `.erl` host module shipped beside it (`src/sidecars/`), add `@External.Erlang` to the 17 cells, drop `"targets"` | The real fix. 231 lines of DI/router/HTTP in erlang, plus the `build`/`run` half that [`13-module-identity`](../13-module-identity/README.md) owns |
| B | Keep `"targets": ["commonJS"]` and say in `rakun/AGENTS.md` and in this README that rakun is a node-only framework by design | Free, honest, and closes the row. The CI's `allow_fail: true` erlang rows go too — a row that is allowed to fail forever is noise |
| C | Port the **container and router only** (`rkScan`, `rkSingleton`, `rkProp`), leaving the HTTP server node-only, and widen `targets` for the tests that do not touch it | A real erlang cell for the part of rakun that is the framework, with the transport still node's |

**Acceptance:**
- [ ] The option is chosen and written in `rakun/AGENTS.md`, replacing `:89-98`
- [ ] If A or C: `zig build test-libs` reads **12 passed, 0 failed, 0 skipped** (or names what is still
      out and why), and the shipped `.erl` is verified by removing it and seeing `{error,undef}` return
- [ ] If B: `rakun`'s CI erlang rows are deleted, not left `allow_fail`
- [ ] Either way, the 1.0.4-beta unowned row *"a library cannot ship an erlang host module"* is struck
      — it closed at `botopink-lang` `c01695f`

### Step 3 — decision 8's remaining source migration

After [`01-checker`](../01-checker/README.md) lands N28 (§5.3b) — the §5.1 arm rewrite needs nothing
and can go first.

1. Rewrite every `case` arm to `Pattern { body }` across the five libraries.
2. emilia: the 27 section annotations become path names, and `src/emilia.bp`'s `case` over `Token`
   binds sections by path.

**Acceptance:**
- [ ] No `pattern -> value;` arm left in any library's `.bp`
- [ ] `tests/language/test/case_sections.bp` passes (its `expected-failures.txt` lines are deleted by
      [`01-checker`](../01-checker/README.md), not here) **before** emilia's §5.3b rewrite starts
- [ ] Every library's cell and examples green after each rewrite

### Step 4 — re-run the erlang cells after the output layout changes

[`13-module-identity`](../13-module-identity/README.md) changes the erlang and BEAM module atom and the
output layout, and makes `botopink run --target erlang` reach a sibling module. Every library's erlang
cell executes that output.

**Acceptance:**
- [ ] `zig build test-libs` re-run after 13 lands: no cell worse than it is now
- [ ] Each library's own gate (its examples included) re-run on `--target erlang`
- [ ] Any new red is registered in [`13-module-identity`](../13-module-identity/README.md), not fixed
      here

### Step 5 — re-derive every library's `AGENTS.md`

Each of the five carries claims written when the cell was red. Re-derive them by running, and delete
what closed.

**Acceptance:**
- [ ] No `AGENTS.md` names a blocker that does not reproduce — starting with `rakun/AGENTS.md:96-98`
      (`shipMjsSidecars` has an `.erl` counterpart since `c01695f`)
- [ ] Every command an `AGENTS.md` tells a reader to run, runs
- [ ] The five submodule pointers bumped in the meta repository in one sweep, after each library's
      branch merges into its own `feat`

## Gate

- [ ] Per library: its own `scripts/git-hooks` gate green (cell + examples)
- [ ] `zig build test-libs` from `botopink-lang`, no cell worse than 11 passed / 0 failed / 1 skipped
- [ ] `botopink format --check` green per library, or the exclusion recorded with its parser row
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Branch `fix/ecosystem-residuals` in each library; no push, no merge, no submodule bump until the
      maintainer's sweep

## Blast radius

- **Step 1 rewrites whitespace in 10 files across four libraries** and nothing else — every cell and
  example is re-run to prove it. emilia's `src/tokens.bp` is deliberately excluded because formatting
  it **reorders six public enum variants**.
- **Step 2 option A adds an `.erl` host module to rakun** and changes `zig build test-libs` from
  `11 passed / 1 skipped` to `12 passed / 0 skipped`. Option B deletes CI rows.
- **Step 3 touches every `case` in the ecosystem** — emilia 31 sites in one file, onze 6, jhonstart 1
  — and emilia's §5.3b rewrite changes 27 annotations and the type they name.
- **Step 4 changes nothing in the libraries**; it is a measurement that either passes or hands a row
  back to [`13-module-identity`](../13-module-identity/README.md).

<a id="decisions-the-maintainer-owes"></a>

## Decisions the maintainer owes

1. **rakun's erlang story** — step 2's A, B or C. Until it is answered, one of the eleven library cells
   is a skip whose reason lives in a manifest key.
2. **Whether emilia's `src/tokens.bp` is excluded from `format --check` or the parser is fixed first.**
   Excluding it means the repo has a file the formatter would corrupt; fixing it first means
   [`01-checker`](../01-checker/README.md) carries a parser row this front cannot close.

## Notes

- The five libraries are the only consumers of the language that are not the compiler's own tests. Every
  regression this milestone's unowned rows describe was found by one of them failing — which is the
  reason step 4 exists at all.
- The `require("../module")` workaround is documented in `jhonstart/src/html.bp:87-92` and
  `emilia/src/root.bp:57`. If [`04-js`](../04-js/README.md) fixes the bare-shorthand lowering, both
  comments and both explicit `from` clauses can go — a follow-up, not a row here.
- `jhonstart/examples/jhonstart-app` has no `botopink.json`; it is a host application, not a botopink
  project, and `botopink build` correctly refuses it. Say so in `jhonstart/AGENTS.md` (step 5) so the
  next reader does not read it as a broken example.

---

## Rows for `fronts.md`

**Ownership table:**

```markdown
| **09** [`ecosystem-residuals`](./README.md) | `repository/{emilia,erika,jhonstart,onze,rakun}/**`; their meta submodule pointers | the libraries' own test outputs and examples | not started — steps 1–2 ready; step 3 after 01, step 4 after 13 |
```

**Conflict notes** (against the other thirteen fronts):

| With | Verdict | Why |
|---|---|---|
| **01 checker** | **seq** — 01 first for step 3 | Step 3's §5.3b rewrite needs N28 (a section as a type named by its path); step 1 registers three parser/trivia rows with it. No file is shared — 09 never edits `repository/botopink-lang/**` |
| **02 erlang · 03 beam · 04 js · 05 wasm** | **seq** | 09 runs the compiled output of all of them. A backend landing re-runs 09's cells; no file is shared. 04 owns the bare-`import` lowering both jhonstart and emilia work around |
| **06 comptime-dedup · 07 review-backlog · 08 hygiene · 11 tooling · 12 language-tests** | yes | No shared file, no shared snapshot directory |
| **10 cli-residuals** | **seq** — 10 first | 10's step 1 (an unresolved `import` is a located error) reds any library whose `from` names nothing. Measured at `c2dd780` by that front: none does. Re-run 09's cells after it lands |
| **13 module-identity** | **no** — 13 first for step 4 | 13 changes the erlang/BEAM output layout and makes `run --target erlang` reach a sibling module; every library's erlang cell executes that output. It also owns the `shipErlSidecars` call site in `cli/build.zig` that step 2 option A needs |
| **14 comptime-on-beam** | **seq** | Every library uses decorators and templates, so it runs their comptime bodies. Nothing shared by file; re-run 09's cells after it |

**Front-table row (`overview.md`):**

```markdown
| [`09-ecosystem-residuals`](./README.md) | medium | not started | What the ecosystem migration left: `format --check` red in four of five libraries (canonical form in most files, but emilia's `Token` has its six payload variants hoisted above its sections and rakun loses a comment's indentation — the parser records no member positions or trailing trivia), rakun's erlang cell skipped by its own `targets` key because 17 host cells are node-only and `runtime.mjs` is 231 lines, decision 8's §5.1 arms and emilia's §5.3b section paths, and five `AGENTS.md` files naming blockers that have closed |
```

---

## Handed over by `16-formatter` (2026-09-18, `37d3dc7`)

**The format step is unblocked, and it is smaller than it was.** Measured on scratch copies of the
five libraries at `37d3dc7`: **890** changed lines (emilia 389, erika 261, jhonstart 210, rakun 30,
onze already clean), down from 923 — and, more to the point, the diff no longer **loses** anything:
**0** reordered enum variants (was 13 at four sites) and **0** deleted `default` keywords (was 3, in
emilia's and erika's `root.bp` and in erika's `erika.bp`). All five are idempotent, `botopink check`
exits 0 on each, and the cells pass (emilia 17, erika 31, jhonstart 2, onze 8, rakun 4).

So formatting and committing the libraries is now a layout change, not a content change. Re-measure
before committing — the numbers above are from the formatter as landed, and this front commits the
result.
