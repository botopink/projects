# Front 16 — formatter

**Priority:** **high** — raised from the medium decision 18 implied. The standing intent is that
**everything stays formatted**, and measured, `botopink format` **deletes the `default` keyword**:
on a package whose handle and handler names differ it silently breaks every consumer, and
`format --check` then reports the broken file as clean. A gate that rewrites programs cannot be
turned on. This front answers whether the formatter is sound first.
**Depends on:** nothing. It can start immediately — steps 1 and 2 edit no source file at all.
**Owns:** `modules/compiler-core/src/format.zig` · `modules/compiler-core/src/format/**` (the 239
formatter tests, unowned through 1.0.4-beta) · the four member-trivia and member-order fields of
`modules/compiler-core/src/ast.zig` and the sites that fill them in
`modules/compiler-core/src/parser/decls.zig` — **a carve-out of [`01-checker`](../01-checker/README.md)**,
named in [Rows for `fronts.md`](#rows-for-frontsmd)
**Does not touch:** `repository/{emilia,erika,jhonstart,onze,rakun}/**`
([`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md) — this front formats **copies** in a
scratch directory and never commits a library file) · `modules/compiler-cli/src/cli/format_cmd.zig`
([`10-cli-residuals`](../10-cli-residuals/README.md)) · the rest of `src/parser/**` and all of
`src/comptime/**` ([`01-checker`](../01-checker/README.md)) · `src/codegen/**` (fronts 02–05)

Paths are relative to `repository/botopink-lang/` unless a row says otherwise. Every count and
`file:line` below was measured at `botopink-lang` `c2dd780` (2026-09-18) in a scratch worktree — never
in `repository/botopink-lang`, never in `.tasks/`.

---

## Problem

**`format --check` is red on four of five libraries, and the formatter is idempotent** — so the reds
are disagreements about the canonical form, not instability:

```
$ for l in emilia erika jhonstart onze rakun; do (cd repository/$l && botopink format --check); done
emilia     src/emilia.bp  src/root.bp  src/tokens.bp   → error: 3 file(s) would be reformatted
erika      src/erika.bp   src/root.bp                  → error: 2 file(s) would be reformatted
jhonstart  src/element.bp src/hooks.bp  src/html.bp    → error: 3 file(s) would be reformatted
onze       (clean)
rakun      src/decorators.bp src/runtime.bp            → error: 2 file(s) would be reformatted
```

Reproduced at `c2dd780`; formatting copies of all five and re-running `format` gives a byte-identical
second pass in every one, which is the idempotence claim, re-measured.

**But four of the ten red files are not disagreements**, and the sharpest one is not the file
decision 18 named. Classified file by file in [`reds.md`](./reds.md):

| | The formatter | Files |
|---|---|---|
| **D1** | **deletes the `default` keyword** — `pub default mod X;` → `pub mod X;`, `pub default fn f(…)` → `pub fn f(…)` | `emilia/root.bp`, `erika/root.bp`, `erika/erika.bp` — 3 occurrences |
| **D2** | **reorders declarations** — 13 enum variants hoisted above the sections they were written after, at 4 sites | `emilia/tokens.bp` |

**D1 changes what the program means.** `pub default mod` names the package handle that `import <pkg>`
resolves to and `pub default fn` names the handler aliased under it (`comptime.zig:914-932`). On a
package where the library name, the module name and the fn name coincide — which is true of emilia
and erika — the loss is masked. On one where they differ it is not:

```
before format:  pub default mod zeta;  ·  pub default fn query(…)   → consumer runs, exit 0
after  format:  pub mod zeta;          ·  pub fn query(…)           → error: unbound variable 'zeta', exit 1
```

`botopink format` can break a downstream consumer silently, and `format --check` then reports the
broken file as clean. **Neither flag is missing from the AST** — `ModDecl.isDefault` (`ast.zig:77`)
and `FnDecl.isDefault` (`ast.zig:1976`) are both recorded and both read by `comptime.zig`. The
formatter simply has no arm for them: its only `default` is the unrelated `BehaviorMethod.is_default`
at `format.zig:1720-1721`. It is a two-arm fix, entirely inside this front's own file.

**And the formatter loses trivia the libraries do not happen to write.** Zero comments are deleted
across the ten red files — but on constructed input:

| | Probe | Output | What happened |
|---|---|---|---|
| a | `type Color { Red, // warm` | `Red,` | the comment is **deleted** |
| b | `type Point(x: i32, // horizontal` `y: i32, // vertical)` | `x: i32,` `// horizontal` `y: i32,` | the first comment is **re-attached to the next field** — it now says something false — and the second is **deleted** |
| c | `fn two(…) { … } // trailing` | `fn two(…) { … }` `// trailing` | the comment is **moved below** the member |

Every result here is **idempotent**: format again and nothing changes. So `format --check` goes green
on a file that has lost a line, which is the property that makes this a front rather than a chore —
and the reason the scope is the formatter's soundness, with decision 18's four libraries as the
evidence rather than the boundary.

## Current state

| | Value | How measured |
|---|---|---|
| libraries red | **4 of 5** — emilia 3 files, erika 2, jhonstart 3, rakun 2; onze clean | `botopink format --check` per library, read-only, at `c2dd780` |
| red files | **10** | the listing above |
| changed lines across the four | **923** — emilia 415, erika 267, jhonstart 211, rakun 30 | `diff -u <lib>/src.orig <lib>/src \| grep -c '^[+-]'` over formatted copies in a scratch directory |
| idempotent | **yes, all five** | format a copy twice; `diff -rq` between pass 1 and pass 2 is empty for every library |
| verdicts | **A 4 · B 2 · C 4** files | [`reds.md`](./reds.md) |
| comments **deleted** in the ten red files | **0** | comment token streams compared lexically, source against formatted |
| `default` keywords deleted | **3** | `pub default mod` ×2, `pub default fn` ×1 |
| declarations reordered | **13** variants at 4 sites, all in `emilia/tokens.bp` | |
| libraries green **before and after** formatting | **5 of 5** — `check` exit 0 and `test` passing in both states (emilia 17, erika 31, jhonstart 2, rakun 4, onze 8) | run, not assumed, on the scratch copies |
| formatter tests | **239** in 8 files — `declarations` 68, `expressions` 49, `literals` 40, `patterns` 34, `comments` 20, `imports` 16, `idempotent` 12 | `grep -c '^test ' src/format/tests/*.zig` |
| tests asserting **no information is lost** | **0** | there is `assertFormat` (output equals an expected text) and `assertIdempotent` (pass 2 equals pass 1) in `src/format/tests/helpers.zig`; neither is violated by deleting a comment |

The per-file classification is [`reds.md`](./reds.md); the compiler-side causes and their costs are
[`parser-gaps.md`](./parser-gaps.md).

## Mechanism

**D1 is the formatter's own.** Nothing is missing: `ModDecl.isDefault` (`ast.zig:74-77`) and
`FnDecl.isDefault` (`ast.zig:1976`) are set by `parser/decls.zig:281`, `:292` and read by
`comptime.zig:914`, `:920`. `format.zig` reads neither — `grep -n default format.zig` returns nine
hits, all of them generic-parameter defaults, field defaults, param defaults, and the one
`BehaviorMethod.is_default` arm at `:1720-1721`. A keyword the parser records and the printer has no
arm for is a **printer** defect, and it is the whole of D1.

**G6 is the formatter's too** — a field the parser records and one of the two statement-sequence
printers does not read. Everything else the formatter cannot print back **is** a field the parser
does not record. Six in all, measured, named and costed in
[`parser-gaps.md`](./parser-gaps.md):

| | Gap | Deciding line | Cost |
|---|---|---|---|
| **G1** | the **order** of enum members: `EnumShape { variants, sections }` are two parallel slices with no ordinal | `ast.zig:2135-2141`; the printer at `format.zig:1847-1848` writes all variants then all sections | **3 files, no backend** with the recommended shape |
| **G2** | a **trailing comment on a record field**: `Field.comments` is leading-only, and `parseFieldList` frees the comments it collected when the next token is `)` | `ast.zig:2091-2094`; the `alloc.free` at `parser/decls.zig:1148-1152` | 3 files |
| **G3** | **any comment on an enum variant**: `EnumVariant` has no comment field at all | `ast.zig:1576-1588` | 3 files |
| **G4** | a **trailing comment on a method**: `BehaviorMethod.comments` is leading-only | `ast.zig:1233-1236` | 3 files |
| **G5** | **blank lines and comments in an `if` then-branch and a lambda body** — two block loops inlined before `parseBlock` grew its options, so neither records `emptyLinesBefore` and a `//` there is a **parse error** | `parser/exprs.zig:162-179` and `:944-951` | 2 call sites in 1 file — **and the parse-error half is [`15-language-surface`](../15-language-surface/README.md)'s** |
| **G6** | an `if` **else**-branch's blank lines are recorded and **not printed**: there are two statement-sequence printers and only `fmtStmtSeq` reads the field | `format.zig:1116-1126` against `:345-368` | **1 function**, this front's own file |

`loop (…) { x -> … }`'s body **is** a lambda body, which is why the `loop` case is the one that gets
noticed. The block-fidelity matrix — which block keeps a blank line, which keeps a comment, and why —
is in [`parser-gaps.md`](./parser-gaps.md#the-block-fidelity-matrix).

One thing the 1.0.4-beta row claimed does **not** reproduce and must not be carried forward as work:
blank lines **between members** are preserved — a member's `comments` slice encodes a blank source
line as `""` (`ast.zig:1233-1236`). The two it named that **do** reproduce are G5 and G6, and neither
is where it said: a blank line survives a fn body and a `test` body, and dies in an `if` branch or a
`loop` body.

[`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md)'s R1 already corrected one of them
from the library side (rakun's continuation comment "loses its padding", it does not move). This front
corrects the rest from the compiler side, and extends it: on a **member**, a trailing comment does
move, and on the last member it is deleted.

## Steps

### Step 1 — Reproduce every red, file by file, and classify it

No source change. For each of the 10 red files, diff the committed source against `botopink format`'s
output **on a copy in a scratch directory** — this front never writes a library file — and give every
category of change one of three verdicts:

| Verdict | Meaning | Where it goes |
|---|---|---|
| **A** | a canonical-form disagreement the **formatter** is right about | [`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md)'s step 1 formats and commits it |
| **B** | a canonical-form disagreement the **library** is right about | a change to `format.zig`, this front's step 6 |
| **C** | a **defect** — the formatter changes meaning or loses information | steps 2–4; it names D1 or a gap G1–G6 |

Write the result into [`reds.md`](./reds.md), one section per file, each category with a count and one
minimal before/after excerpt.

**Acceptance:**
- [ ] All 10 files classified; every category carries a count and an excerpt
- [ ] Every **C** row names D1 or a gap (G1–G6) in [`parser-gaps.md`](./parser-gaps.md) that explains
      it, or adds a seventh with the same evidence standard
- [ ] Every **B** row states what the formatter should print instead, and why the library's spelling
      is the better one — a B with no argument is an A
- [ ] The formatted copy of each of the five libraries **compiles**: `botopink check` exit 0, and each
      library's `botopink test` cell passes. A formatted file that does not compile is a C, whatever
      its diff looks like
- [ ] Idempotence re-measured at this front's HEAD, not quoted from here
- [ ] Not one file under `repository/<lib>/` is modified

### Step 2 — Re-confirm that the hoist does not change meaning

This is what emilia's exemption is waiting on, and it is a measurement, not an opinion. A section
desugars into a synthesised inner enum with a mangled name (`ast.zig:2137-2140`); if any backend
assigned a variant's run-time encoding by its position in the `variants` slice, then hoisting a
variant past a section would change the program, and `format --check` on `tokens.bp` would be a
correctness hold rather than a style question.

**Measured at `c2dd780`, it does not.** emilia was built from both orderings on all four targets and
the emitted output is byte-identical on commonJS, erlang, beam and wasm; `grep -r
'variantIndex\|tag_index\|ordinal'` over `src/codegen/` returns 0 hits; and the `emilia-card` example
produces identical HTML and identical content-derived class hashes either way. The evidence is in
[`reds.md`](./reds.md#emiliasrctokensbp--13-variants-hoisted-above-the-sections).

So the exemption is a **fidelity** hold. This step re-runs the measurement at the front's own HEAD —
because a backend that starts keying on an ordinal turns a style question into a correctness one
silently — and then stops.

**Acceptance:**
- [ ] The four-target comparison is re-run at this front's HEAD and the result written into
      [`parser-gaps.md`](./parser-gaps.md)'s G1 section, with the date
- [ ] If it still holds: G1 stays a fidelity fix, and step 4 is what lifts the exemption
- [ ] If it no longer holds: G1 becomes the front's first implementation step, ahead of D1, and the
      exemption is re-recorded as a **correctness** hold in
      [`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md)'s row
- [ ] A one-line assertion is added somewhere a future reader will meet it: nothing in `src/codegen/`
      may key on a variant's position in `TypeShape.EnumShape.variants`

### Step 3 — Print `default` (D1)


**First, alone, and ahead of everything else**, because it is the only change in this front that fixes
a program the formatter can currently break, and because it touches one file.

Two arms in `format.zig`: the `mod` printer emits `default ` after `pub ` when `ModDecl.isDefault`,
and the fn printer does the same for `FnDecl.isDefault`. No parser change, no AST change.

**Acceptance:**
- [ ] `pub default mod X;` and `pub default fn f() {}` round-trip byte-identically
- [ ] `assertFormat` cases for both, in `src/format/tests/declarations.zig`
- [ ] The minimal package whose handle, module and fn names **differ** — the probe in
      [`reds.md`](./reds.md#emiliasrcrootbp--erikasrcrootbp--erikasrcerikabp--default-is-deleted) —
      still resolves in a consumer after `botopink format`
- [ ] `emilia/src/root.bp`, `erika/src/root.bp` and `erika/src/erika.bp` formatted as copies keep
      their three `default` keywords

### Step 4 — Record order and trailing trivia (G1–G4), and print what is already recorded (G6)

One parser/AST commit, then one formatter commit — never merged, so the first lands
snapshot-byte-identical and the second is reviewed as rendered text.

1. **G1 — order.** Add `order: u32` to `EnumVariant` and `EnumSection`; `parseEnumItem`
   (`parser/decls.zig:811-880`) assigns a running index per body; `format.zig:1847-1848` and
   `:1889-1892` merge the two lists by it. **Recommended over** replacing the two slices with one
   `members` list: that shape is the one the language deserves, but it reaches **35 call sites in 9
   files**, five of which are fronts 02–05's emitters and two are 01's. `order` is additive and every
   existing reader is untouched — and the formatter asks for a merged list either way, so A can
   replace B later without the formatter moving again. The full measurement is in
   [`parser-gaps.md`](./parser-gaps.md#the-cost-measured).
2. **G2 — a field's trailing comment.** `trailingComment: ?[]const u8 = null` on `Field`, captured in
   `parseFieldList` after `trailingComma = this.match(.comma)` and gated on the comment token being on
   the **same line** as the field; the `alloc.free` at `parser/decls.zig:1148-1152` stops destroying
   it. `Field` already carries an additive optional of this shape (`typeLoc`, 06 N30) — follow it.
3. **G3 — a variant's comments.** `comments: []const []const u8 = &.{}` and
   `trailingComment: ?[]const u8 = null` on `EnumVariant`, with the same `""`-means-blank-line
   convention the other members use.
4. **G4 — a method's trailing comment.** `trailingComment` on `BehaviorMethod`, captured at
   `parser/decls.zig:1261` and `:1429`.
5. **G6 — print an `if` else-branch's blank lines.** No parser change: the field is already there.
   `fmtBranchStmts` (`format.zig:1116-1126`) joins with `hardline()` and reads neither
   `emptyLinesBefore` nor the trailing-comment flag, where `fmtStmtSeq` (`:345-368`) reads both.
   Give it the two arms, or delete it in favour of `fmtStmtSeq` if the diff says they are otherwise
   the same. **G5 — the `if` then-branch and the lambda body — is not this front's**: those two
   inlined block loops are a parse error as well as a fidelity loss, and
   [`15-language-surface`](../15-language-surface/README.md) owns them. This front's G6 fix lands
   after 15's G5, or the then-branch still has nothing to print.

**Acceptance:**
- [ ] The three probes in [Problem](#problem) round-trip byte-identically through `botopink format`
- [ ] An `if` **else**-branch keeps its blank lines (G6); an `if` then-branch and a `loop` body keep
      theirs once 15's G5 has landed — asserted, and marked blocked until it has
- [ ] The parser/AST commit is **snapshot-byte-identical** — `jsonStringify` writes an optional
      trivia field only when present (`ast.zig:2108-2110` is the precedent), so no comptime AST
      snapshot moves
- [ ] `zig build test` green from a cold cache after each commit
- [ ] The 35 `.variants()` / `.sections()` call sites are unchanged — `git diff --stat` names
      `ast.zig`, `parser/decls.zig` and `format.zig` and nothing else

### Step 5 — A gate that would have caught D1, G2 and G3

The formatter has 239 tests and **not one of them fails when a comment, or the `default` keyword, is
deleted**: `assertFormat` compares against a text a human wrote, and `assertIdempotent` compares pass
2 against pass 1 — a deletion is idempotent.

Add `assertLossless(src)` to `src/format/tests/helpers.zig`: lex the input and the output, and assert
that **every token in the source appears in the output**, in order — comments and keywords alike,
modulo the separators the canonical form is allowed to add or drop (`;`, `,`, `{`, `}`), which the
helper lists explicitly so the exemption is reviewable. Run it over every existing
`assertFormat` and `assertIdempotent` case (they already carry the corpus) plus the four probes above.

**Acceptance:**
- [ ] `assertLossless` exists and is called by every case in `src/format/tests/comments.zig` and
      `idempotent.zig`
- [ ] It **fails** on the pre-step-4 formatter — demonstrated by running it at the parent commit, and
      the failing count recorded in [`reds.md`](./reds.md)
- [ ] The property is defined over the **whole token stream**, not over comments alone: D1 is a
      deleted keyword, and a comments-only property would have missed it
- [ ] `src/format/tests/AGENTS.md` states the property and why idempotence does not imply it

### Step 6 — The canonical form itself: the **B** rows

Only now, with the defects gone, is the canonical form worth arguing about. Implement each **B** row
from step 1 in `format.zig`, one commit per rule, each with the library excerpt that motivated it as a
test case.

**Acceptance:**
- [ ] Each B row is implemented or withdrawn with a reason written into [`reds.md`](./reds.md)
- [ ] Re-formatting the four libraries' copies after each rule shrinks the 923-line diff, and the new
      number is recorded
- [ ] No A row moved to B without the maintainer's decision — a rule that changes how every library
      looks is a decision, and this front proposes it rather than taking it

### Step 7 — Hand the result over, and say what the exemption is now

`format --check` becoming a repository-wide gate is
[`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md)'s step 1 and, if it needs a per-file
exemption mechanism, `modules/compiler-cli/src/cli/format_cmd.zig` — which is
[`10-cli-residuals`](../10-cli-residuals/README.md)'s file. **There is no exemption mechanism today**:
`format_cmd.zig:50-38` takes either an explicit file list or every `src/**.bp` the scanner's output
names, with no skip list. Decision 18's exemption therefore has to be *built*, and this front names its shape
rather than building it.

**Acceptance:**
- [ ] The A rows are listed in a form 09 can apply file by file
- [ ] The exemption's shape is proposed in one paragraph — recommended: a `botopink.json` key, because
      the manifest is already the consumer surface and a source pragma would be a language change this
      front does not own — and handed to [`10-cli-residuals`](../10-cli-residuals/README.md)
- [ ] After step 4, emilia's `src/tokens.bp` formats without reordering; the exemption is recorded as
      **liftable**, and lifting it is 09's commit, not this front's

## Gate

- [ ] `scripts/gate.sh --cold` green in this front's worktree
- [ ] `assertLossless` green over the whole formatter corpus
- [ ] The parser/AST commit of step 4 lands **snapshot-byte-identical**; the formatter commit
      re-records only what step 1 classified
- [ ] The five libraries' formatted copies compile and their cells pass — run, not assumed, and never
      committed from this front
- [ ] `AGENTS.md` of every directory touched (`src/format/`, `src/format/tests/`, `src/parser/`),
      updated in the same commit
- [ ] Commit on `fix/formatter`; no push, no merge — landing is the maintainer's step

## Blast radius

- **Snapshots.** None from the parser/AST commit if the optional-field convention is followed. The
  formatter commit re-records nothing in `snapshots/**` — the formatter has no snapshot directory; its
  239 tests carry their expected text inline.
- **The libraries.** 923 changed lines across four repositories, which 09 commits, not this front.
  After steps 3 and 4 the number **changes**: three `default` keywords come back and comments that are
  deleted today start being printed — so 09's step 1 must run **after** step 4, or it commits files
  that have lost a keyword or a comment. That ordering is the
  one real dependency this front creates, and it is stated in
  [Rows for `fronts.md`](#rows-for-frontsmd).
- **Front 01.** Step 4 edits `parser/decls.zig`, which 01 owns for its step 4 (a section body carrying
  a `fn`). The sites are disjoint — `parseEnumItem`'s member append and `parseFieldList`'s comment
  free, against 01's section-body grammar — but they are in the same file, so this is a carve-out to
  grant or a sequence to schedule.
- **Fronts 02–05.** Zero, with the recommended G1 shape. With the alternative (`members` as one list)
  it is five emitters and 35 call sites, which is the reason the recommendation exists.
- **Front 15.** G5's two inlined block loops are 15's, and this front's G6 is only half a fix without
  them: the `if` else-branch starts printing its blank lines and the then-branch still does not.

## Notes

- **The front's question is soundness, not tidiness.** Decision 18's four red libraries are its
  evidence, not its scope: a formatter that is idempotent, has 239 tests, and still deletes a keyword
  the program's meaning depends on is the finding. It was found by auditing the formatter, not by
  reading the reds — three of the ten red files carry it and all three still compile and pass, because
  in emilia and erika the name the keyword would alias is the name that already binds.
- **Idempotence is not fidelity, and the test suite conflates them.** `assertIdempotent` passes on a
  formatter that deletes every comment in the file. Step 5 is the smaller half of this front and the
  half that keeps it from happening again.
- **One defect is the formatter's, four are the parser's.** D1 is a missing printer arm for a flag the
  AST already carries — one file, this front's own, and so is G6. G1–G5 are fields the parser does not
  record, and a front that owned only `format.zig` could not fix one of them, which is why the
  carve-out is asked for up front rather than discovered mid-step. G5 is not even this front's: it is
  a parse error too, and [`15-language-surface`](../15-language-surface/README.md) owns it.
- **A library passing is not evidence the formatter is sound.** All five libraries `check` and `test`
  green both before and after formatting, D1 included. Whatever gate 09 turns on has to be stronger
  than "it still compiles".
- **The exemption is a fidelity hold, measured.** emilia's emitted output is byte-identical on all
  four backends from either ordering, so `tokens.bp` is exempt because the formatter loses authored
  grouping, not because it would change the program. Step 2 re-confirms it; step 4 removes the reason
  for it.
- **Not done here:** formatting the libraries (09), the `format --check` gate (09), the exemption
  mechanism (10), and `format.zig`'s idea of a labelled tuple, which
  [`02-erlang`](../02-erlang/README.md) hands over at its README `:107-108` — it is this front's file
  but decision 8's semantics, so it lands after
  [`01-checker`](../01-checker/README.md) types a labelled tuple.

---

## Rows for `fronts.md`

**Ownership table:**

```markdown
| **16** [`formatter`](./16-formatter/README.md) | `modules/compiler-core/src/format.zig` · `modules/compiler-core/src/format/**` · the member-trivia and member-order fields of `modules/compiler-core/src/ast.zig` and the sites that fill them in `src/parser/decls.zig` (`parseEnumItem`, `parseFieldList`, `parseMethodDecl`) — a carve-out of **01**. **Not** `src/parser/exprs.zig`'s two inlined block loops (G5), which are **15**'s | — (the formatter has no snapshot directory; its 239 tests carry their expected text inline) | not started — steps 1–2 edit no source and can start now; step 3 is a two-arm fix in the front's own file; step 4 needs 01's carve-out; **09's format step lands after step 4** |
```

**Conflict notes** (against the other fifteen fronts):

| With | Verdict | Why |
|---|---|---|
| **01 checker** | **seq** — carve-out, or 16 after 01's step 4 | Both edit `src/parser/decls.zig`. The sites are disjoint: 16 takes `parseEnumItem`'s member append (`:811-880`), `parseFieldList`'s comment handling (`:1130-1178`, in particular the `alloc.free` at `:1148-1152`) and the two `method.comments` sites (`:1261`, `:1429`); 01's step 4 takes the section-body grammar. 16 also adds four fields to `src/ast.zig`, which **no front owns**. Recommended: grant 16 the three named functions, as [`14-comptime-on-beam`](../14-comptime-on-beam/README.md) was granted two `infer.zig` call sites |
| **02 erlang · 03 beam · 04 js · 05 wasm** | yes | No shared file with the recommended G1 shape — `format.zig` and `ast.zig`'s new optional fields against `codegen/**`. The alternative shape (one `members` list) would make this **no** for all four: 35 call sites across the five emitters. That is the measurement behind the recommendation, not a preference |
| **06 comptime-dedup** | yes | 06 owns `src/comptime/snapshot.zig` and the comptime snapshot layout; this front writes neither. The parser/AST commit is snapshot-byte-identical, so it does not collide with 06's move even if they land together |
| **07 review-backlog** | yes | 07 owns `src/codegen/tests/**`, `src/comptime/tests/**`, `src/parser/tests/**` and the language server's tests. **`src/format/tests/**` is in none of those lists** — it was unowned through 1.0.4-beta and this front claims it. Worth stating explicitly so step 5 is not read as a carve-out |
| **08 hygiene** | **no** — 08 after 16 | 08's sweeps touch `AGENTS.md` everywhere, including `src/format/` and `src/format/tests/`, which steps 3–5 rewrite. One commit per owning file, after this front |
| **09 ecosystem-residuals** | **seq — 16's steps 3–4 before 09's step 1** | 09 formats and commits the four libraries. Run before step 3, it commits three files from which the formatter has **deleted the `default` keyword** (D1) — emilia's and erika's `root.bp` and erika's `erika.bp` — and, before step 4, a `tokens.bp` whose members it has reordered. Run after, it commits a canonical form that is stable and lossless. 09's R1 classification is this front's step-1 input; the three "information-losing classes" 09 registers against [`01-checker`](../01-checker/README.md) move here, per [decision 18](../decisions-taken.md#18-emilias-tokensbp-and-format---check). No file is shared at any moment — 16 formats copies in a scratch directory |
| **10 cli-residuals** | yes, with a handover | `modules/compiler-cli/src/cli/format_cmd.zig` is 10's, and there is no per-file exemption mechanism in it today. Step 7 proposes the exemption's shape and hands it over; this front edits no line of it |
| **11 tooling** | yes | No shared file. The language server does not call the formatter |
| **12 language-tests** | yes | No shared file. A `format` round-trip is not a language cell |
| **13 module-identity** | yes | 13 owns the two emitters, the CLI's output layout and the module-atom sites; none of them is `format.zig`, `ast.zig`'s trivia fields or `parser/decls.zig`'s member sites |
| **14 comptime-on-beam** | yes | 14 owns `comptime/{template_eval,decorator_eval}.zig`, the eval protocol and one `codegen/erlang.zig` carve-out. No overlap |
| **15 language-surface** | **seq — 15 before 16, with one gap split down the middle** | They share **no function**: 15 takes `parser/exprs.zig`'s `parsePostfixChain`, the grouped-expression arm and the two inlined block loops (`:162-179`, `:944-951`), plus `parser/types.zig` and the lexer; 16 takes `parser/decls.zig`'s member sites and `format.zig`. **G5 is the split**: those two block loops drop a blank line *and* refuse a `//` comment, and the refusal is a parse error, so 15 fixes the loops and 16 prints the result (G6 is the else-branch's printer half). Separately, 15's step 4 makes forms parse that the formatter has never had to print — `(expr).method`, `#(…)[]`, `adder(3)(4)` — and each needs a `format.zig` printer arm, which is the same class of defect this front found in `pub default mod`. Recommended: **15 first**, each new form arriving with its round-trip confirmed |

**Front-table row (`overview.md`):**

```markdown
| [`16-formatter`](./16-formatter/README.md) | high | `format --check` is red on four of five libraries and the formatter is **idempotent**, so the reds look like disagreements about the canonical form. Four of the ten red files are not: `botopink format` **deletes the `default` keyword** — `pub default mod` / `pub default fn`, the package handle and its handler — which silently unbinds every consumer of a package whose names differ, and it **reorders 13 enum variants** above the sections they were written after. Both survive `format --check`, because a deletion is idempotent, and none of the 239 formatter tests would notice. The keyword is a missing printer arm for a flag the AST already carries; the order and three trailing-trivia slots are parser fields whose recommended shape touches 3 files and no backend |
```

---

## Landed — 2026-09-18, merged into `feat` as `37d3dc7`

Five commits on `fix/formatter`, cold gate green. Steps 3, 4 and 5 are done; the three
information-losing classes decision 18 filed here are closed, and the property that would have caught
them exists.

| Commit | What it fixes |
|---|---|
| `098a493` | **D1** — `format` was **deleting** the `default` keyword. Two missing printer arms for flags `ast.zig` already recorded (`ModDecl.isDefault`, `FnDecl.isDefault`), both read by `comptime.zig:914-932` |
| `9d1d067` | **G6** — an `if` branch is printed by the one statement-sequence printer, so an else-branch keeps its blank lines |
| `fed06ac` | **G1–G4, parser half** — a member's written order and its trailing comment are recorded |
| `b0cdf94` | **G1–G4, printer half** — an enum body is the **merge** of `variants` and `sections` by order, so nothing hoists; a field's trailing comment goes after the comma; a variant's comments print; `withTrailingComment` keeps a comment on its own line |
| `a23ae79` | **Step 5** — `assertLossless`, the property the 239 tests did not have |

**The D1 defect was proven both ways, not argued.** A package whose handle, module and handler have
*different* names — `pub default mod zeta;`, `pub default fn query(…)`, a consumer doing
`import zeta` and `zeta "hello"` — ran before formatting and answered `unbound variable 'zeta'` after
it, while `format --check` reported the corrupted library **clean**. The three real occurrences
survived only because in those packages the three names coincide: the loss was masked, not absent.

**Why 239 tests saw none of it.** `assertFormat` asserts equality with a text a human wrote, and
`assertIdempotent` asserts pass 2 equals pass 1 — and **a deletion is idempotent**. `assertLossless`
lexes input and output and asserts token containment, with two written-out exemptions
(`droppable_separators`, and the pre-1.0.3 `val Name = behavior { … }` binding form in exactly that
shape). Order is deliberately not asserted: the first draft did, and failed on five idempotent cases
where the canonical form *moves* a token and loses nothing. Run against this front's parent
(`4841983`) it fails **4 of 5** probes; after the whole front, 0. `assertIdempotent` now calls it, so
the pairing cannot come apart again.

**The ecosystem diff, measured on scratch copies** (no file under `repository/<lib>/` written):
923 → **890** changed lines, **13 reordered variants → 0**, **3 deleted `default` keywords → 0**, all
five libraries still idempotent, `check` exit 0, cells passing (emilia 17, erika 31, jhonstart 2,
onze 8, rakun 4).

**emilia's `tokens.bp` formats without reordering now** — which is what
[decision 18](../decisions-taken.md#18-emilias-tokensbp-and-format---check) held it back for. Under
[decision 34](../decisions-taken.md)'s (c) there is no exemption mechanism to build or to lift: the
file is formatted like every other one, and the hoist that would have been excused no longer happens.

**Still open here:** steps 1–2 (the classification pass) and the printer arms
[`15-language-surface`](../15-language-surface/README.md) hands over below, which are new — the forms
did not parse when this front was written.

---

## Handed over by `15-language-surface` (2026-09-18, `109f6c9`)

**Three printer arms, one class: a form parses and `format` does not print it back.** The first two
lose data, which is the same defect class as `pub default mod` — a deletion is idempotent, so
`format --check` stays green over it:

| Written | `format` prints | Why it matters |
|---|---|---|
| `(i32 \| string)[]` | `i32 \| string[]` | **a different type** — the parentheses are the array's element boundary |
| `adder(3)(4)` | `(4)` | **the receiver is dropped** |
| `xs[0]` | `@[](xs, 0)` | the desugaring leaks; `d["k"]` and `xs[0..2]` are the same node |
| `a ?? 0` | the desugared `if` | pre-existing class, not new: `x is i32` already prints `@is(x)` |

**And the second half of G6 is now yours alone.** After 15's `28e447e` a blank line inside a `loop`
body **survives** `format`; inside an `if` branch it still does not, because `fmtBranchStmts` never
reads `emptyLinesBefore` — the AST has carried it all along.

**Decision 29's other half is written and waiting on you.** 15 holds a 76-line parser patch that
rejects the trailing `;`; it cannot land alone, because it rejects `libs/std`'s embedded prelude and
every compile fails. The coordinated landing is: this front stops printing the `;`, 15 applies the
patch, [`12-language-tests`](../12-language-tests/README.md) migrates its 44 sites, `libs/std` its 51
and [`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md) the siblings' 145 — **245 sites
total**, counted by the compiler, against the ~274 the decision estimated (emilia has **0**, not 30).

---

## Handed over by `09-ecosystem-residuals` (2026-09-18)

**One fidelity loss survived formatting all five libraries** — the only one, after this front's step
4: `rakun/src/runtime.bp:13`, the continuation line of a trailing comment that was indented to align
under the first, re-emitted at column 0. The text is intact; the alignment is not. It is the last live
member of 09's R1 classes, and it belongs to the trivia fields this front now owns.

Everything else came through clean, verified per file by token-stream equality and per project by a
byte-identical `diff -r` of the emitted output — which is the strongest statement this milestone has
that the formatter no longer loses anything: 874 changed lines over 8 files, 0 reordered members, 0
deleted keywords, 11 passed / 0 failed in `test-libs`.

