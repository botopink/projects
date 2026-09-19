# Decisions the maintainer owes — 1.0.5-beta

**Four open — 63, 64, 65 and 66**, all written below: 63 by the decision-record audit, 64 and 66 by
[`09-ecosystem-residuals`](./09-ecosystem-residuals/README.md) — one while landing `libs/std/src/beam.bp`,
the other while reformatting the six trees — and 65 by [`16-formatter`](./16-formatter/README.md) while
landing [decision 61](./decisions-taken.md#61-the-formatters-canonical-layout--four-rules)'s four rules.
Every question before them — 38 to 62 — is answered and recorded in
[`decisions-taken.md`](./decisions-taken.md), which is the record the fronts implement against: 38 to 47
were answered on 2026-09-18 together with four the same pass raised and answered (48, 49, 50, 51), and 52
to 62 followed within the day, several of them within hours of being written — among them the three that
were open when this header last counted them, 53 opened by `08-hygiene`, 55 by `03-beam` and 56 by
`10-cli-residuals`. What is left after those four is the list of defects with an owner and no row, kept so
they are not re-discovered; decision 62 says which three of them are this wave's. None of the four open
ones is a defect with an owner either: 63 and 65 are calls of the class decision 61 was — one about what a
form *means* on four backends, one about how every library *looks* — 64 is a mechanism
[decision 43](./decisions-taken.md#43-beammemory-lives-in-two-layers--and-off-the-beam-the-annotation-is-a-no-op-while-the-module-is-an-error)
took without naming its dependency, and 66 is the scope of a gate.

**53 and 55 both changed after they were opened**, and the new evidence is in their sections: Zig was
measured (it has *both* spellings, in different positions, so the compiler is the Zig-consistent side and
decisions 20/36 are not), and `yield` beside `break` in a collection loop was measured on all four
backends (four different answers, three of them order-dependent).

---

## 63. Does an index expression answer `T` or `?T`?

**Measured.** [Decision 30](./decisions-taken.md#30-is-there-an-index-expression) granted `xs[0]` in every position
and [decision 47](./decisions-taken.md#47-absent-has-one-spelling-null) settled the *spelling* of absence (`null`),
but neither says what an index **answers**, and the two documents that name the gap both leave it. Front
15's handover to [`01-checker`](./01-checker/README.md) says it in as many words — inference must type
`xs[0]` by the receiver, "the element type for an array, the value type for a dict, a character for a
string, the member type for a tuple with a constant index — **decide whether the answer is `T` or `?T`**"
— with `ast.zig:1734` assigning the typing to that front; today the checker types it `void`, so
`val first: string = xs[0];` reds with *expected string, got void*. At run time the four backends already
disagree about the out-of-range case: front 12's cell `index_an_index_past_the_end_answers_zero` answers
`undefined` on three backends and `0` on wasm — a third word again, under a slug that names a fourth.
[Decision 46](./decisions-taken.md#46-dk-on-a-dict-routes-to-lookup) settles the *route* of a dict index (`lookup`)
and not its type, and a dict is the one receiver whose natural answer is already optional.

**Options.** **(a) `T`.** An index answers the element type; an out-of-range read is a run-time matter and
each backend answers decision 47's `null` there, unchecked — the shape C and JavaScript have, and the only
one in which `rows[0].name` and `d["k"].name` read as they look. **(b) `?T`.** An index answers an
optional everywhere, so an out-of-range read is *typed*: by
[decision 45](./decisions-taken.md) every `xs[0].field` becomes the error naming `?.`, and every index written in the
ecosystem grows a `?.` or an unwrap. **(c) By receiver:** `T` for an array, a tuple and a string, `?T` for
a `Dict` — because a missing key is a dict's ordinary case and a missing element is an array's bug.

**Ecosystem evidence, not only a unit test** (front 09, while reformatting): `libs/std/src/querystring.bp:38`
carried a call that an *older* formatter had broken over three lines, and **both** the pre- and
post-decision-61 formatters join it back into **95 columns** against `LINE_WIDTH = 80`. A broken `fits`
does not only fail to break a line — it un-breaks one that was already broken.

**Recommendation: (c).** It is the only one that keeps the decisions already taken: `at` returning an
optional stays a *different feature* from indexing, which is decision 30's own argument for adding the
form; decision 46's `lookup` keeps the type it has; and no line in `libs/std`, `examples/**` or the five
libraries grows a `?.`. (b) makes decision 45 fire on `rows[0].name`, which is among the most ordinary
lines the language has, and (a) gives `d["k"]` a type that claims the key is always there. The cost of (c)
is that the answer is receiver-dependent — which decision 46 has already made the index anyway: the
checker records the receiver kind at the site.

**Blocks.** `01-checker`'s `xs[0]` typing row (item 2 of front 15's handover) and, through it, the index
lowering in all four backends; the expected text **and the slug** of
`index_an_index_past_the_end_answers_zero`; and the three per-backend rows under decision 47.

**Correction, 2026-09-19, measured twice on a rebuilt binary.** Two things this question leans on are
larger than it says, and both make the answer more urgent rather than different.

**Decision 46 measured one backend of three, so "a dict index answers `undefined`" is commonJS's answer
alone.** On a `Dict` that **holds** the key, `@print(d["k"])` answers `undefined` on commonJS, brings the
node down on erlang (`{bp_unsupported_index, #{pairs => [{<<"k">>,1}]}, <<"k">>}` thrown from
`__bp_index/2`) and **traps** on wasm (`wasm trap: wasm 'unreachable' instruction executed`) — the three
outputs are written out under
[decision 46](./decisions-taken.md#46-dk-on-a-dict-routes-to-lookup). That changes what option (a) is
being weighed against: the sentence above, that (a) "gives `d["k"]` a type that claims the key is always
there", is a criticism of a backend that *answers*. On two of four targets there is no run-time answer to
claim anything about, so 46's `lookup` route is a prerequisite of whichever of (a), (b) and (c) is chosen,
not a neighbouring row — and (c), which gives a dict index `?T`, is the only option whose *type* matches
what a `lookup` returns.

**And the index's missing type loses its location in arithmetic position.** `val n = xs[0] + 1;` answers

```
error: type mismatch: expected void, got i32
 --> src/main.bp
```

— no line, no column, just the file — while the annotated case (`val first: string = xs[0];`) does carry
one (`3:25`, the index itself). So the cost of leaving `xs[0]` typed `void` is not only a wrong word in a
diagnostic: in the position an index most often appears in, the diagnostic cannot be navigated to, and an
editor has nothing to underline. That belongs to this question's cost rather than to `01-checker`'s
error-location step, because the location is missing precisely where the *type* is.

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
record cites.** The `libs/std/src/querystring.bp:38` measurement — a call joined back to 95 columns,
recorded under [question 63](#63-does-an-index-expression-answer-t-or-t) — is one line. The better witness
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

---

## 66. Does `format --check` look at the whole tree?

**Measured** by [`09-ecosystem-residuals`](./09-ecosystem-residuals/README.md) while reformatting the six
trees for [decision 61](./decisions-taken.md#61-the-formatters-canonical-layout--four-rules). `format --check`'s
default scan is `src/**` minus `.d.bp`, **and that is exactly where the rot collects**: 40 of `libs/std`'s
48 pre-existing out-of-form lines were in places it never looks — 32 in `test/` and 8 in
`builtins_fns.d.bp` — which is how they survived a whole milestone with the gate green. And it is not
historical: `jhonstart/test/html_test.bp` is out of form **today** while `format --check` reports clean.

**Options.** **(a) Widen the scan to every `.bp` and `.d.bp` in a project**, with the two files that cannot
parse handled explicitly: `libs/std/src/builtins.d.bp` (`fn await(…)` — `await` is a keyword) and the three
`examples/jhonstart-app` files whose `Link("/posts/1") { "first post" }` a trailing lambda's one-line body
refuses. Both are recorded in this file already. **(b) Widen it to `test/**` only**, since that is where
40 of the 48 were, and leave `.d.bp` out on the grounds that nothing compiles them. **(c) Leave the scan
and write the convention down** — which is what front 09 did in `libs/std/AGENTS.md` for now.

**Recommendation: (a), gated on the two parse defects.** A formatter gate that does not look at a
directory is a gate that guarantees nothing about it, and the measurement is that the unwatched
directories are precisely the ones that drift. But (a) cannot land before the two files parse — a widened
scan reds on them — so the honest order is: fix the trailing-lambda body and `await`, then widen. (b) buys
most of the coverage for none of that work and is the fallback if either parse defect stalls.

**Blocks.** Nothing today. It decides whether `libs/std`'s convention note becomes a rule the tooling
enforces, and it is the second time in this milestone that a gate's *scope* — not its logic — is what let
something through (`beam_export_audit.sh` was the first: it cannot find a shape no snapshot has).

**Correction, 2026-09-19, measured across every `.bp` in the seven repositories twice: the question is
larger than the measurement it was opened with, in four ways, and two of them change option (a).**

- **There is a third axis of scope, and it holds most of the drift: the nested project.**
  `format --check` fails in **14 of the 27 directories that carry a `botopink.json`**, over **18 files,
  every one of them inside that project's own `src/**`**. So this is neither a `test/**` nor a `.d.bp`
  exemption — it is `src/**`, in a project nobody runs the check in, which no option above covers. Nine of
  the fourteen are outside the compiler: `examples/stdlib-tour`, `emilia/examples/emilia-card`,
  `erika/examples/erika-linq`, `jhonstart/examples/{jhonstart-counter,jhonstart-html,jhonstart-todo}` and
  the three `tests/language/modules/*` cells (`mod_tree` alone contributes four files); five are fixtures
  under `modules/compiler-cli/tests/**` — `backend_exec/numeric`, `backend_exec/records`,
  `mutual_recursion`, `test_tooling/pass` and `test_tooling/fail`. It also contradicts
  `modules/compiler-core/src/format/AGENTS.md:111`. Two things it does **not** contradict: each library's
  own `src/**` is still clean (the drift is in the projects *nested inside* the repositories, not in the
  five libraries front 16's row calls clean), and the three `tests/language/modules/*` cells are front
  12's files rather than 09's — so widening the scan hands rows to a third front.
- **There is no automatic `format --check` gate for `.bp` anywhere**, which makes this question not only
  *what does the scan cover* but *who runs it at all*. `scripts/gate.sh` runs `zig fmt --check` over
  staged `.zig` files and nothing else; `scripts/git-hooks/pre-commit` names neither `format` nor `fmt`;
  none of the three `.github/workflows/*.yml` does either. Every number in this question was produced by
  hand, and nothing in the repository would have produced any of them.
- **A repository-wide scan reds on 12 files that do not parse, not 4 — and 6 of them exist in order not
  to parse.** The four already recorded are `libs/std/src/builtins.d.bp` and the three
  `examples/jhonstart-app` files, which option (a) above counts as *two* because they are two defects.
  Beyond them: six `tests/language/reject/**` cells (`case_bare_name_arm`, `case_constant_pattern`,
  `case_tuple_label`, `loop_while`, `two_effect_markers`, `bodyless_fn_no_return_type`),
  `tests/language/run/optional_null_pattern.bp` —
  [decision 54](./decisions-taken.md#54-a-t-is-matched-by-null-and-a-binder)'s form, which does not parse
  — and `tests/language/test/case_arms.bp`, already carried by `expected-failures.txt`. So option (a)
  needs an **exemption it does not currently mention**: `reject/**` is a corpus whose purpose is to be
  refused, and a formatter gate that reds on it measures the fixtures instead of the tree. Front 16's step
  7 measured the other half of that — **there is no exemption mechanism today**, `format_cmd.zig` taking
  either an explicit file list or every `src/**.bp` the scanner names, with no skip list — and that file is
  [`10-cli-residuals`](./10-cli-residuals/README.md)'s.
- **And the worst answer in the set is a pass.** `jhonstart/examples/jhonstart-app` has no
  `botopink.json` and no `src/`, so `format --check` there prints **zero bytes and exits 0** while three
  of its four `.bp` files do not parse and the fourth is out of form — `main.bp` reports
  `Formatted main.bp` and exit 1 the moment it is named. A vacuous pass is worse than a red: a red is a
  row, and "clean" for a directory the tool never read is the failure this whole question is about, in its
  purest form.

What that does to the recommendation: its **order** survives — exempt and fix before widening, never the
reverse — and its arithmetic does not. "Gated on the two parse defects" is now gated on two fixes (`await`,
the trailing-lambda body), one exemption (`reject/**`), two files that are already declared failures
(`optional_null_pattern.bp`, `case_arms.bp`), a scan that has to find a project with no manifest before any
of it is reached, and a gate that has to exist at all before the scan's scope is worth deciding. (b) —
`test/**` only — is no longer "most of the coverage": it reaches none of the 18 files above, all of which
are in `src/**`.

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
  [question 63](#63-does-an-index-expression-answer-t-or-t); the cell's slug asserts a third answer
  (`zero`) that no decision supports.**
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
  [question 66](#66-does-format---check-look-at-the-whole-tree).
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

Numbers are never reused: the next question added here is **67**.
