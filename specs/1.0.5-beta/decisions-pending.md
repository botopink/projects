# Decisions the maintainer owes — 1.0.5-beta

**Two open — 64 and 65**, both written below, and both opened 2026-09-18 by the front that met them: 64 by
[`09-ecosystem-residuals`](./09-ecosystem-residuals/README.md) while landing `libs/std/src/beam.bp`, 65 by
[`16-formatter`](./16-formatter/README.md) while landing
[decision 61](./decisions-taken.md#61-the-formatters-canonical-layout--four-rules)'s four rules. **63 and 66
were answered 2026-09-19** and have moved to [`decisions-taken.md`](./decisions-taken.md) with their
evidence: 63 as
[an index answers `T`, and an absent key fails](./decisions-taken.md#63-an-index-answers-t-and-an-absent-key-fails-rather-than-answering),
66 as
[`format --check` looks at the whole project](./decisions-taken.md#66-format---check-looks-at-the-whole-project--and-something-has-to-call-it);
the same message raised
[decision 67](./decisions-taken.md#67-the-most-restrictive-behaviour-and-no-configuration-that-bypasses-it),
the standing principle every option list from here is written against — the most restrictive behaviour, and
no configuration that bypasses it. Every question before the two — 38 to 63, and 66 — is answered and
recorded there, which is the record the fronts implement against: 38 to 47 were answered on 2026-09-18
together with four the same pass raised and answered (48, 49, 50, 51), and 52 to 62 followed within the day,
several of them within hours of being written — among them the three that were open when this header last
counted them, 53 opened by `08-hygiene`, 55 by `03-beam` and 56 by `10-cli-residuals`. What is left after
the two is the list of defects with an owner and no row, kept so they are not re-discovered; decision 62
says which three of them are this wave's. Neither of the two is a defect with an owner: 64 is a mechanism
[decision 43](./decisions-taken.md#43-beammemory-lives-in-two-layers--and-off-the-beam-the-annotation-is-a-no-op-while-the-module-is-an-error)
took without naming its dependency, and 65 is how every library *looks* — a call of the class decision 61
was.

**53 and 55 both changed after they were opened**, and the new evidence is in their sections: Zig was
measured (it has *both* spellings, in different positions, so the compiler is the Zig-consistent side and
decisions 20/36 are not), and `yield` beside `break` in a collection loop was measured on all four
backends (four different answers, three of them order-dependent).

---

## 64. How does `@BeamMemory`'s layer 2 reach layer 1, when the erlang backend emits no wrapper?

**Measured** by [`09-ecosystem-residuals`](./09-ecosystem-residuals/README.md) while landing
`libs/std/src/beam.bp`, which is committed and gate-green.
[Decision 43](./decisions-taken.md#43-beammemory-lives-in-two-layers--and-off-the-beam-the-annotation-is-a-no-op-while-the-module-is-an-error)
split the feature in two: **layer 1**, ten `#[@External.Erlang]` primitives in `libs/std`, and **layer 2**,
the core lowering a binding's read and write *onto those primitives*, with no line of `.zig` naming ETS,
`persistent_term` or the process dictionary. Layer 1 exists. The route does not. A qualified std host call
lowers to a call on the std module — `beam:pdPut(Slot, Slot)` — while the emitted `out/std/beam.erl` is
`-module(beam).` **and nothing else**: no export, no function. It is not this module's doing:
`out/std/process.erl` is `-module(process).` plus a `no_auto_import` line and no function either, where
commonJS emits real wrappers (`function cwd() { return process.cwd(); }`). The erlang backend emits **no
wrapper for a host-bound std `declare fn`** at all, so nothing on the BEAM can call layer 1. Front 17's
step 3b therefore cannot meet its fourth acceptance bullet ("re-run under `erl`") today, whatever layer 1
looks like.

**Options.** **(a) Decision 43 gains a dependency:** the erlang backend emits a wrapper per host-bound std
`declare fn` — an `-export` and a body calling the host BIF — as a numbered row of front 02, or of front
13, which owns `erlang.zig` wholesale while its halves 2–3 run; layer 2 waits for it. **(b) Layer 2 emits
`erlang:put/2` and the ETS calls from `.zig`**, which is what decision 43 chose against, and layer 1
becomes documentation rather than the mechanism. **(c) Layer 2 goes with steps 4–5**, already outside this
milestone by [decision 50](./decisions-taken.md#50-17-runs-steps-03b-in-this-milestone-steps-48-become-a-spec-for-the-next),
and the wrapper row is scheduled beside them.

**Recommendation: (a).** The gap is not a `@BeamMemory` problem: *every* host-bound std declaration on the
BEAM has it, `libs/std/src/erlang.bp` included, so the row pays for itself outside this front, and it is
the row that makes decision 43's two layers mean what they say. (b) buys the same behaviour by withdrawing
a decision that was taken on purpose, and it is the version nobody can extend from `libs/std`. (c) is
honest and free, but it leaves layer 1 in the tree with no caller and step 3b's acceptance permanently
unrunnable — the shape decision 50 rejected when it refused "steps 0–2 only".

**Blocks.** Step 3b's fourth acceptance bullet in [`17-beam-memory`](./17-beam-memory/README.md) and every
read/write lowering of its steps 4–5; and whether decision 43's "no line of `.zig` names ETS" survives
contact with the backends.

**Correction, 2026-09-19, re-measured after front 13's half 1 renamed the std atoms.** The finding holds
exactly as stated — zero `-export`, zero function, `undef` at run time, no wrapper for any host-bound std
`declare fn` — and three of the spellings it is written in are stale, so a reader who greps for them finds
nothing:

- **`out/erl/std@beam.erl`**, not `out/std/beam.erl`. **`-module(std@beam).`**, not `-module(beam).`.
  **`std@beam:pdPut(T, T)`**, not `beam:pdPut(Slot, Slot)`. The half-1 rename is why: the std module's atom
  now carries its package.
- **"`-module(beam).` and nothing else" is wrong about the file**, name aside. It is **162 lines** — the
  `-module` attribute, then 161 lines of `beam.bp`'s `////` header re-emitted as blank-separated `%%%`
  comments. Nothing else *executable*, which is the substance; but the emitted header is also why the gap
  is invisible in a listing, and why "and nothing else" should not be read as "a two-line file".
- **`libs/std/src/beam.bp`'s own header carries the same three stale spellings**, in the paragraph
  beginning *"One thing layer 2 cannot yet do through this module, measured"*. That file is
  [`09-ecosystem-residuals`](./09-ecosystem-residuals/README.md)'s and not this question's to edit —
  recorded here so whoever owns it next can re-spell them, since that header is where a reader of layer 1
  meets this finding first.
- **It is step 3b's *third* acceptance bullet that fails, not its fourth**, here and in the Blocks line
  above: the third is the one ending *"and re-run under `erl`"*. The fourth — *"**Not** a `.zig` line"* —
  is **satisfied**: layer 1 landed with no `.zig`, which is decision 43's mechanism holding rather than
  breaking. Option (b) is the one that would fail the fourth bullet, and naming the right bullet is what
  makes that legible.

**And option (b) is now out on principle, not only on preference.**
[Decision 67](./decisions-taken.md#67-the-most-restrictive-behaviour-and-no-configuration-that-bypasses-it)
— the most restrictive behaviour, and no configuration that bypasses it — reads on this question directly:
emitting `erlang:put/2` and the ETS calls from `.zig` is the bypass of a decision already taken, which is
the shape 67 refuses. The live choice is (a) against (c), and that is a question of *when* the wrapper row
runs rather than of whether layer 1 is the mechanism.

**Sub-question, raised by the maintainer 2026-09-19 and deliberately not answered here: does
`libs/std/src/beam.bp` need to be a module separate from `libs/std/src/erlang.bp` at all?** In his words:
*"não sei se precisa de um erlang e um beam separado."* It is a question about this front's shape rather than
about the backend gap, and every measurement points the same way: `@External.Erlang` covers **both** BEAM
targets (`codegen.zig:74-77` maps `.erlang` and `.beam` to the one lookup name), the missing wrapper is
missing in the two files identically, and the program measured above dies in `std@erlang:self()` **before it
ever reaches `pdPut`** — so `beam.bp` is not the module with the problem, it is the module that found it.

- **One module** costs one wrapper row and gives an author one import and one place to add a host primitive.
- **Two modules** keep the memory vocabulary — ten primitives over three storage families, each with a
  policy layer above it — separable from the general BIF table, which is what lets `@BeamMemory`'s layer 1
  be read as a unit and what makes `libs/std/src/beam.bp`'s header the design document it currently is.
- **The strongest fact either way, and it cuts against merging:** `erlang.bp` is **read by the emitter at
  compile time** (`codegen/erlang.zig:184-206`) to build the auto-imported BIF table, so it is *compiler
  input* and not only a declaration list. Merging ten primitives that nothing auto-imports into it makes the
  emitter read declarations that do not concern it, and makes the auto-import table's contents a question of
  which memory primitive someone added last.

It does not block the wrapper row either way: the wrapper is owed **per host-bound `declare fn`**, not per
module.

---

## 65. Does the formatter learn to measure width?

**Measured** by [`16-formatter`](./16-formatter/README.md) while landing
[decision 61](./decisions-taken.md#61-the-formatters-canonical-layout--four-rules)'s four rules. `fmtParams`' `group`
was never missing: **`fits` stops at the first `concat`** and then answers "fits" for any non-negative
budget, so *every* group in the formatter renders flat, and no construct in the language has ever broken
by width. Rule 4 landed by routing around it — a `Doc.widthChoice` whose flat width is measured at build
time against the real column, which is why a method four columns in breaks four columns earlier and why
the trailing ` {` or `;` counts, the boundary being exact at 80/81. The finding is written into
`src/format/AGENTS.md` under *"`fits` does not fit"* so the next reader does not rediscover it. The cost
of the rules that *did* land is the scale to read this against: **607 lines** across the six trees (erika
165, `libs/std` 160, rakun 139, jhonstart 106, onze 37, emilia 0), rule 1 being 428 of them and rule 4
123, with 48 of `libs/std`'s pre-existing because that tree had never been formatted.

**Ecosystem evidence, not only a unit test** (front 09, while reformatting; recorded under question 63 until
that question was answered and moved, because the evidence is this question's):
`libs/std/src/querystring.bp:38` carried a call that an *older* formatter had broken over three lines, and
**both** the pre- and post-decision-61 formatters join it back into **95 columns** against
`LINE_WIDTH = 80`. A broken `fits` does not only fail to break a line — it un-breaks one that was already
broken.

**Options.** **(a) Fix `fits` to measure through `concat`, `nest` and `group`.** Every array literal,
call, type union and comma list then starts breaking at `LINE_WIDTH`, at once — a canonical-form choice
per construct, and several hundred moved lines on top of the 607. **(b) Leave `fits` as it is and keep
adding `widthChoice` per construct**, as rule 4 did: each construct that should break by width gets its
own measured decision, and the general predicate stays a lie the `AGENTS.md` note explains. **(c) Fix
`fits` and gate it**: land the correct predicate with every existing `group` pinned flat, then enable
constructs one at a time, each with its own diff and its own reformat commit.

**Recommendation: (c).** (a) is the honest engineering answer and the wrong landing: it changes how every
library looks in one commit, which is exactly the class of call decision 61 was created to ask the
maintainer rather than assume, and it would arrive mixed into 607 lines of someone else's churn. (b)
leaves the formatter with a predicate that answers wrongly for every caller, so the next person to reach
for `group` is misled again — and the `widthChoice` count only grows. (c) costs one extra step and makes
each construct's canonical form a separate, reviewable choice with its own measurement, which is how
decision 61's four rules were decided in the first place.

**Blocks.** Whether `16-formatter` reopens; the canonical form of every comma list, array literal, call
and type union; and any future reformat of the six trees — each construct enabled is another
`09-ecosystem-residuals` commit.

**Correction, 2026-09-19: the un-breaking has committed evidence, and it is sharper than the line this
record cites.** The `libs/std/src/querystring.bp:38` measurement above — a call joined back to 95 columns —
is one line. The better witness
is `examples/erika-linq/src/main.bp`, which is committed, which `format --check` reds today, and which
`botopink format` turns from six hand-broken lines

```botopink
    return of(people)
        .where({ p -> p.age >= 18 })
        .orderBy({ p -> p.name })
        .select({ p -> p.name })
        .toArray()
        .join(", ");
```

into an **82-column** hybrid — the whole chain joined back onto one line, one argument list pushed out to
its own, and the result still two columns over `LINE_WIDTH = 80`:

```botopink
    return of(people).where({ p -> p.age >= 18 }).orderBy({ p -> p.name }).select(
        { p -> p.name }
    ).toArray().join(", ");
```

The same file emits **88** and **85** column lines by the same route (`…).toArray().fold(` and
`…).toArray().join(`), from chains the author had broken one call per line. And in the same `botopink format`
run a 90-column `fn` **signature** breaks one parameter per line — decision 61's rule 4, the construct that
got a measured width — while a **call** carrying the same arguments is joined to **135** columns. That
contrast is the sharpest statement of what `fits` does: the formatter breaks exactly where someone measured
for it and joins everything else however long the line becomes. It argues for the recommendation rather
than against it — under (b) the list of constructs that un-break committed files is the list of constructs
nobody has reached yet — and it supplies (c) with its first gate: the call, whose flat form is the one
measured above.

**Constraint, 2026-09-19, from the maintainer: the method chain's canonical form is decided, and the current
output is wrong rather than wide.** Shown the erika-linq hybrid above, his words were *"essa formatação tá
errada para esse caso, deveria manter"* — followed by the six hand-broken lines, **one call per line**. So
the target shape is given and this question no longer decides it: a method chain the author broke per call
stays broken per call. What that does to each option is the same in kind and different in cost — under (a)
the chain comes out that way the moment `fits` measures; under (b) the chain is the next `widthChoice`;
under (c) it is the **first** construct enabled, with its expected text already written. What remains open is
exactly the predicate and the staging — `fits` measuring through `concat`/`nest`/`group`, and whether every
existing `group` is pinned flat while constructs are enabled one at a time — and not the chain's layout.

It also re-grades the finding. A formatter that joins a committed chain is not producing an unconventional
layout that a maintainer may prefer differently; it is producing the **wrong** one, against a known target,
in files that are committed. And
[decision 67](./decisions-taken.md#67-the-most-restrictive-behaviour-and-no-configuration-that-bypasses-it)
sharpens the ranking the recommendation already gave: under *the most restrictive behaviour, and no
configuration that bypasses it*, **(b) is the weakest of the three** — it keeps a predicate that answers
wrongly for every caller as the permanent state, with the `AGENTS.md` note standing in for the fix. (c)
remains the recommendation and (a) its honest, worse-staged twin.

---

- **Fronts 03 and 05 carry all three of erlang's `patternNode` defects, and it is verified at line level**
  (front 01, after front 02's `fe87db51`): `commonJS.zig` reads `Pattern.shape` (`:4231`, `:4567`, `:4576`)
  and `Pattern.rest` (`:4239`); `erlang.zig` reads both now; `beam_asm.zig` reads **neither** — its four
  `.shape` hits are all `tdecl.shape`, record against enum — and `wat.zig` reads neither either, its one
  hit being `tdecl.shape`. commonJS is the oracle. And the way to catch them matters: `botopink test`
  reaches neither target, so only a `run/` cell can, which means **`run/case_values.bp` passing on all four
  is not evidence**.
- **The ambient-behavior blind spot is the only half of decision 58 left** (front 01): an interface the
  program does not *declare* is skipped in **both** the inline and the block form, so
  `type Money(cents: i32) implement Display { }` still checks against `libs/std`'s ambient `Display`.
  Closing it needs the interface-member registry and would red every implementation the registry cannot
  open.
- **`ast.Pattern` carries no `Loc`, and two `reject/` fixtures need one** (front 01):
  `reject/case_shorthand_on_unknown.bp` wants `full name` at 11:9 and `reject/case_arity_without_rest.bp`
  wants `height` at 11:9 — the pattern's own column, where only the arm's *body* has a location. Both lines
  survive; giving `Pattern` a `Loc` crosses the parser, the formatter and four backends.
- **A type pattern over a named type lowers to a variant-tag test on every backend** (front 01), so
  `case v { Person { … } Vec { … } }` misses both arms and answers `undefined`. Two `expected-failures`
  lines and three tests, `13 step 17` alone — the checker half is done.
- **`open_case_domain_names` is `i32` + `string`, which is a language rule and not an implementation
  choice** (front 01): `f64`, `bool` and the sized integers are the same unbounded domain, so
  `case x { 0 { … } 1 { … } }` on an `f64` still compiles while the `i32` spelling now reds. It costs no
  migration either way.
- **The LSP's completion `detail` quotes source, so decision 61's rule 4 made it multi-line** (front 09,
  found by a red cold gate at `snapshots/lsp/completion_array_methods.snap.md`): a method's `detail` is the
  **raw source slice** of its signature, and `Array.fold<A>` is one of the nine signatures rule 4 breaks —
  so an editor's completion list now shows a five-line detail **with its indentation**. The snapshot is
  honest and the rule is right; `detail` should render a signature rather than quote source. Front 11's
  row. The snapshot was regenerated rather than leaving `primitives.bp` unformatted to protect a
  completion string.
- **The formatter collapses a single-line triple-quoted sublanguage string** (front 09):
  `html """<div><p>hi</p></div>"""` becomes `html "<div><p>hi</p></div>"` in
  `jhonstart/test/html_test.bp`, deleting eight quote characters at two sites. The cell passes either way,
  but a delimiter the author chose is a spelling decision and not layout — which is why that one file was
  left out of the reformat, and why jhonstart's count is 106 rather than 112. Front 16's.

Findings that sit below the level of a decision — defects with no row, not questions — recorded here
until a front claims them:

- ~~**`src/comptime/**` has no warning channel at all**~~ (`grep -rn warning comptime/*.zig` → 0), and
  three separate obligations want one: decision 8 §1.4, §2.4 and §4.3. It is a `warnings` list on the
  `Env`, rendered like a `TypeError`, and it unblocks all three at once. **Claimed — this is now
  [decision 57](./decisions-taken.md#57-srccomptime-gets-a-warning-channel), a row of
  [`01-checker`](./01-checker/README.md), and the obligations are four: decision 42's `keyed` warning is
  the fourth, though 42's answer is that the warning is not printed.**
- ~~**An inline `implement <Behavior> { }` inside a `type` checks nothing.**~~
  `type Money(cents: i32) implement Display { }` passes — with a local `Display`, and with the
  long-registered `Generator`. Only the separate `implement X for Y` block is covered. No row exists.
  **Claimed — this is now [decision 58](./decisions-taken.md#58-the-inline-implement-behavior---check-is-01-checkers-row):
  the same check as the separate block, a row of [`01-checker`](./01-checker/README.md).**
- ~~**`tests/language/expected-failures.txt`'s distribution paragraph runs two ahead of the file**~~
  (front 02, 2026-09-18): front 04's two deletions were never counted into it — `origin/feat` shows 68
  data lines under a `70 lines` header. Front 12's file; each front decrements its own lines and reports
  the drift rather than rewriting another front's number. **Closed — this is
  [decision 59](./decisions-taken.md#59-whoever-deletes-an-expected-failurestxt-line-recounts-its-header-from-the-file),
  the header was re-derived from the file (58 / 53 / 5), and front 12 re-derived the one sub-claim 59 left:
  the file already says 19, so nothing there is stale.**
- **A yielding condition loop in expression position is still refused on erlang** (front 02):
  `val xs = loop (i < 3) { yield i; i = i + 1; };` gives `ConditionLoopValueUnsupported`, because it
  reaches `exprNode` rather than `mutatingExpr` and so has no variable group to join. commonJS collects
  there. No cell or fixture reaches it.
- **A stale comment in front 04's test** (front 02): `src/codegen/tests/control_flow.zig:517-525` says
  erlang "does not compile it at all (`ConditionLoopValueUnsupported`)", untrue since `a9e9d03`. It is
  04's file, so 02 left it.
- **A block-armed `case` types `void` when its subject is a function parameter** (front 08):
  `fn grade(n: i32) -> string { return case n { 90...100 { "A" } _ { "lower" } }; }` reds
  `type mismatch: expected string, got void`, while the same arms over a literal or a `val` local answer
  `A`, and the `->` arm form works with a parameter. It is the block-arm value path, i.e.
  [`01-checker`](./01-checker/README.md)'s step 4 — whose uncommitted half may already close it; verify
  before writing a row.
- **`Type.assoc()` gets no return type** (front 03) — **one of the three
  [decision 62](./decisions-taken.md#62-the-order-of-what-is-left-in-the-milestone) claims for this wave**: `val c = Counter.zero(); c.bump()` leaves
  `env.instanceLowerings` with no entry, so beam answers `{unresolved_method, bump, 1}` and wasm traps,
  while commonJS and erlang print `1` because neither needs the type. **Reproduces inside one module** —
  not an import row. `val c: Counter` fixes it; writing the return type as `Counter` instead of `Self`
  does not. Front 01.
- **A method on an imported `enum` is emitted as a bare local call on erlang** (front 03):
  `area({'Square',4})` while `geometry.erl` exports `area/1`, so the emitted program does not compile —
  the enum half of `7783fd6` / `1193d3c`. Front 02; pinned as `KNOWN-WRONG (erlang)` in the new fixture.
- **An imported enum's `case self` traps on wasm** (front 03) — `unreachable`, single-module, no
  named-type identity. Front 05, and the same ground as decision 22.
- **Step 5 of `08-hygiene` has no test for its diagnostic**, only for the message: nothing asserts the
  `the <template|decorator> evaluator's erl runtime failed (…): …` text, and the frame-cap failure is
  unreachable from a fixture. Front 07 (`comptime/tests/**`) or front 14 (`template_eval.zig`).
- ~~**`libs/std` is no longer `format --check` clean**~~ — **closed by front 09's `652b624c` and
  `68093afc`, measured 2026-09-19:** all 26 `.bp` of `libs/std/src` answer `Unchanged` at exit 0, and so
  do `builtins_fns.d.bp` and the three `test/*.bp` when they are named on the command line.
- **The continuation line of a trailing comment re-emits at column 0** (front 16, front 09's last R1
  member): text intact, alignment lost. It needs a **recorded comment column**, not a printer arm — a
  comment reaches the AST as text with no column — and its site is `parseDecls`' top-level trailing
  comment, outside front 16's three named functions. No owner.
- ~~**Four layout rows for front 16's step 6**~~ — **absorbed whole: rules 1 to 4 of
  [decision 61](./decisions-taken.md#61-the-formatters-canonical-layout--four-rules) *are* those four
  items, in that order, and all four landed with front 16's step 6.**
- **Front 15's handover note is stale in one line** (front 16): it says a blank line inside an `if`
  branch does not round-trip "because `fmtBranchStmts` never reads `emptyLinesBefore`" — that function
  was deleted by `9d1d067`, and after 15's `28e447e` the then-branch, the else-branch and the `loop`
  body all round-trip. G5/G6 are closed, and `f1881b5` now asserts it.
- **beam drops `.length` on an index or slice receiver**, exit 0 (front 05, found by its second merge)
  — **one of the three [decision 62](./decisions-taken.md#62-the-order-of-what-is-left-in-the-milestone) claims for
  this wave**, and *not* the same fix as [decision 46](./decisions-taken.md#46-dk-on-a-dict-routes-to-lookup): erlang
  gets this right through a type-free runtime helper (`__bp_len(Recv, Member)`, `erlang.zig:4804-4811`)
  that fires when inference recorded nothing, while 46's receiver-kind route runs through
  `instanceLowerings.put`, which fires only at method-call sites and has no index or slice arm:
  `rows[0].length` answers `[1, 2]`, `xs[0..2].length` answers `[10, 20]`, `s[1..3].length` answers `el`
  — each meaning `2`. It is the beam twin of what front 05's `91b1553` fixed on wasm; `beam_asm.zig` is
  front 03's.
- **Two silent wrong answers left on wasm**, listed in `wat/AGENTS.md` (front 05): a string tuple element
  printed as its address — `@print(t.1)` → `256` (means `x`), `@print(row.name)` → `256` (means `SP`).
  The shape is known to `printShapeOf` and not to `isStringExpr`. Front 05's own.
- **Three wasm `expected-failures.txt` reason texts are now false** (front 05): `run/print_formatter.bp`,
  `run/display_print.bp` and `run/type_identity_print.bp` say "prints as its raw heap address"; they now
  **trap**. A line may only be deleted here, never rewritten, so the correction is front 12's.
- **Decision 47 has three backends to move** (front 05): it settled that absent has one spelling, `null`,
  and today wasm, erlang and beam print `undefined` while commonJS prints `null` — and decision 8 §7
  names neither. Also `index_an_index_past_the_end_answers_zero` answers `undefined` on three backends
  and `0` on wasm. Those are rows under 47, not new questions — **the spelling is. The *type* of an
  out-of-range read is not settled by 46 and 47 together, and it is now
  [decision 63](./decisions-taken.md#63-an-index-answers-t-and-an-absent-key-fails-rather-than-answering) —
  answered `T`, with an absent key a **failure** rather than either word, so the cell needs a third rewrite:
  its slug asserts `zero`, its text asserts `undefined`, and the answer is that the program stops.**
- **commonJS already answers §7's F2/F3** (front 05): a class instance carries its constructor's name, so
  `Point(x: 1, y: 2)`, `Shape.Square(side: 4)` and `Shape.Nothing` print correctly there — that backend
  needs no identity work from front 13 for the printed form; wasm, erlang and beam do.
- **An associated `fn` on an `enum` is emitted as a tagged tuple named after it** (front 02, probing the
  neighbourhood of the imported-enum row): `memberCallNode`'s "qualified enum payload constructor" branch
  (`erlang.zig:5351`) fires on any `EnumName.callee(...)` without checking that `callee` names a variant,
  so `Shape.unit()` emits `{unit}` — `erlc` is clean and the program dies with
  `{case_clause,{unit}}` in `area/1`. It reproduces **inside one module** and with or without the
  `val s: Shape` annotation, so it is not an import row. commonJS with the annotation prints the right
  answer; without it, it fails differently (`Shape.unit(...).area is not a function`), which is the
  checker row `dispatch.zig` already pins. Owners: the erlang arm is front 02's or 13's depending on
  ordering, the unannotated half is 01's R6. No `expected-failures.txt` line, no `KNOWN` note and no step
  of front 02's nine covers it. **One of the three [decision 62](./decisions-taken.md#62-the-order-of-what-is-left-in-the-milestone) claims for this wave.**
- **`main/0` is exported only when `main` is `pub`** (front 10): `main/1`, escript's entry, is always
  exported, so `examples/modules` (`fn main()`) carries just `-export(['_botopink_main'/0, main/1]).`
  while the three `tests/language/modules/*` cells (`pub fn main()`) carry both arities. A runner that
  calls `main:main()` therefore fails on the first and works on the other three. The asymmetry is in
  `erlang.zig` — front 02 / front 13 — and it is either a rule that should be written down or a bug; it
  is currently neither.
- **An attribution survived three milestones because nobody re-ran the cell** (front 10): two statements
  in `modules/compiler-cli/**` said `examples/modules` reds on erlang because "the backend emits
  cross-module calls as bare local calls", and that the erlang front would fix it. Both false — the
  emitted calls are qualified and correct, and the defect is the runner's. Corrected in `8babfa5`. The
  pattern is the finding: a `KNOWN` note with no re-run date is a claim, not a measurement.
- **Two `libs/std` headers still name 1.0.4 fronts** for gaps that now pass (front 08):
  `libs/std/test/primitives_gaps_test.bp` and `libs/std/src/primitives.bp:204` (`F5 erlang`,
  `F8 js-bridges`). `libs/std/**` beyond comments is front 01's step 11.

- **Front 13's half 3 claims "`RUN LOG`s that move: 0 — and one that moves is a bug"**, and one moves:
  `print_a_record_and_a_variant_have_no_printed_form_yet_so_they_trap` already prints a composite on
  erlang, so it must move under the identity. The claim is in
  [`13-module-identity`](./13-module-identity/README.md) at two places (its half-3 table and the
  identity-evidence E19 row) and the front that owns the file has to soften it, not delete the cell.
- **Step 5 of front 13 cannot be finished inside the carve-out it was granted.** The comptime atom wants
  the owning *file*, and the evaluator never sees one: `buildModule` gets an `ast.FnDecl` whose `Loc`
  carries a line and a column and no file, and the template registry is a `StringHashMap(ast.FnDecl)`
  with no owner. So `ui@panel__tpl__panel__<hash>` needs the module name carried on
  `env.TemplateEvalCtx` — `src/comptime/env.zig` and `src/comptime.zig`, beyond the module-atom lines of
  `template_eval.zig` / `decorator_eval.zig` that [`fronts.md`](./fronts.md) granted. It is a carve-out to
  grant or a row to move, and front 13 stopped rather than take it.
- **Two statements in front 17's README were overtaken by the decisions that answered them** (found by the
  decision-record audit): its question-42 row still recommends "**a located warning, not an error**" with
  a "**Conditional:** `src/comptime/**` has no warning channel" rider, and its step-6 checkbox still reads
  "the `keyed`-on-a-`Dict` warning of question 42, **if** the warning channel exists". Both halves have
  moved: [decision 57](./decisions-taken.md#57-srccomptime-gets-a-warning-channel) grants the channel and
  [decision 42](./decisions-taken.md#42-a-dict-under-ets-with-keyed-unwritten-keeps-the-default-with-no-warning)
  answers (b) — no warning at all, the sentence goes to `docs.md`. The README is front 17's file and 17
  has not opened; the decisions are the record to implement against.

- **A trailing lambda's one-line body is a parse error at every arity, and three committed example files
  do not parse because of it** (front 16, landing decision 61's rule 3): `executar { ok }` is
  *unexpected `}`* and so is `calcular(fator: 2) { a, b -> a + b }`, while `{ -> 42 }` and
  `{ n -> n * 2 }` in argument position both parse. `examples/jhonstart-app/app/layout.bp`, `app/page.bp`
  and `app/posts/[id]/page.bp` each contain `Link("/posts/1") { "first post" }` — exactly that form — so
  **`botopink format` refuses three files that are committed in the repository**, and they escape
  `format --check` today only because it scans `src/**`. It is why rule 3 of decision 61 stops at
  `arrow_when_empty`. Owners: the form is the parser surface, front 15's ground; the three files are
  front 09's or front 08's.
  **Correction, 2026-09-19, measured file by file:** the three fail at **three different sites**, not all
  at `Link("/posts/1") { "first post" }` — `app/layout.bp:12:28` on `h1 { "my blog" },`,
  `app/page.bp:12:54` on `li { Link("/posts/1") { "first post" } },`, where column 54 is the **inner**
  lambda and not the `Link` call, and `app/posts/[id]/page.bp:32:29` on `h1 { post.title },`. The form is
  one form and the diagnostic is the same in all three (*unexpected `}`*, with the missing-`;` hint), so
  the defect does not multiply; what the single example understates is that only one of the three sites is
  a trailing lambda on a call **with arguments**, and the other two are a trailing lambda on a bare
  element name — so a fix verified against `Link(…) { … }` alone verifies one of the three.
  And the escape is worse than "it scans `src/**`": that directory has no `src/` and no `botopink.json`
  at all, so `format --check` there exits 0 having read nothing — recorded with
  [decision 66](./decisions-taken.md#66-format---check-looks-at-the-whole-project--and-something-has-to-call-it),
  which answers (a) and widens the scan over it.
- **`libs/std/src/builtins.d.bp:116` does not parse**: `fn await(self: Self) -> Result<T, E>;` — `await`
  is a keyword (front 16). Doc-only, so nothing compiles it today, but a repository-wide format or parse
  gate reds on it. Front 01's step 11 / front 08.

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

Numbers are never reused: the next question added here is **68** — 67 is the standing principle the
maintainer raised with 63's answer, and it is in
[`decisions-taken.md`](./decisions-taken.md#67-the-most-restrictive-behaviour-and-no-configuration-that-bypasses-it).
