# The ten red files, classified

Every row was produced by formatting a **copy** of the library in a scratch directory and diffing it
against the committed source; no file under `repository/<lib>/` was written. The compiler was built
in a scratch worktree at `botopink-lang` `c2dd780`. Comment and code token streams were compared
lexically (string- and comment-aware) so that "nothing was lost" is a measurement, not an impression.

**Verdicts** — the three of step 1 of the [README](./README.md):

| | Meaning |
|---|---|
| **A** | a canonical-form disagreement the **formatter** is right about → [`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md) formats and commits it |
| **B** | a canonical-form disagreement the **library** is right about → a change to `format.zig` |
| **C** | a **defect**: the formatter changes meaning or loses information |

---

## Summary

| | Value |
|---|---|
| red files | **10** — emilia 3, erika 2, jhonstart 3, rakun 2; onze clean |
| **A** — formatter is right | **4** files: `emilia/emilia.bp`, `jhonstart/element.bp`, `jhonstart/html.bp`, `rakun/decorators.bp` |
| **B** — library is right | **2** files: `jhonstart/hooks.bp`, `rakun/runtime.bp` |
| **C** — defect | **4** files: `emilia/root.bp`, `emilia/tokens.bp`, `erika/erika.bp`, `erika/root.bp` |
| changed lines | **923** — emilia 415, erika 267, jhonstart 211, rakun 30 |
| **comments deleted** | **0** across all ten files |
| comments moved or re-aligned | **2** — `jhonstart/hooks.bp` ×1, `rakun/runtime.bp` ×1 |
| blank lines removed | **14** — `tokens.bp` 10, `erika.bp` 3, `html.bp` 1 |
| `default` keywords **deleted** | **3** — `emilia/root.bp`, `erika/root.bp`, `erika/erika.bp` |
| declarations reordered | **13** variants at 4 sites, all in `emilia/tokens.bp` |
| single-statement `if`/`else` blocks unwrapped | **104** — erika 81, `html.bp` 21, `element.bp` 2 |
| all five libraries `check` and `test` green, **before and after** | yes — emilia 17 passed, erika 31, jhonstart 2, rakun 4, onze 8; exit 0 in both states |

**Two defects, and only one of them is what decision 18 named.**

1. **`default` is deleted** (`emilia/root.bp`, `erika/root.bp`, `erika/erika.bp`) — the formatter
   rewrites `pub default mod X;` as `pub mod X;` and `pub default fn f(…)` as `pub fn f(…)`. This
   changes what the program means, and nothing in the repository catches it.
2. **Enum members are reordered** (`emilia/tokens.bp`) — 13 variants hoisted above the sections they
   were written after. Measured on all four backends: **the emitted output is byte-identical**, so
   this is source-level information loss without an observable meaning change today.

**The probes in the [README](./README.md)'s Problem section — a deleted variant comment, a deleted
field comment — fire on constructed input and on none of these ten files.** They are real
(reproduced, idempotent, and explained by [`parser-gaps.md`](./parser-gaps.md) G2/G3), but no library
writes a trailing comment on a member today. That is the difference between the evidence and the
scope: decision 18's four libraries are the evidence; the formatter's soundness is the scope.

**Re-measured 2026-09-26** at compiler `b6ba65a3`, over the five libraries at the meta repository's
pinned commits (`git archive` copies — 09 has reformatted them since, so the ten files above are no
longer red and the whole trees were measured instead: 158 `.bp` files). Every file's tokens and
comments were compared as multisets, and `botopink check` run in all 46 packages before and after.
Two **C** rows no earlier probe had found, both fixed in compiler `0f0be511`:

| | The formatter | Found in | Cause |
|---|---|---|---|
| **G8** | **deletes** a comment written before an enum body's or an enum section's closing `}` | emilia's token module — four `// ── end front NN ──` lines | the section's comments were collected by `parseEnumItem` and freed; the enum's sat in `TypeDecl.bodyComments`, which only the record path printed ([`parser-gaps.md`](./parser-gaps.md#g8--a-comment-before-an-enum-bodys-or-a-sections-closing-brace)) |
| **D2** | **adds** a `catch @panic("assert pattern did not match")` to the handler-less `val assert P = e;` — a form the checker refuses | rakun, 15 of its packages stop compiling after `format` | the parser desugars the form into that handler (decision 8 § 9) and the printer wrote it back; `assertPattern.fatal` marks it |

D2 is the first formatter defect found by the **compile** half of step 1's acceptance rather than by the
token comparison: nothing was lost, something was added, and the result was idempotent.

**Step 5's demonstration, recorded here as the box asks:** `assertLossless` run against the parent of
the step-4 commits (`4841983`) fails **4 of the 5** probes (the three of the README's Problem plus
D1's two keywords); after the landing, 0.

---

## C — the defects

### `emilia/src/root.bp` · `erika/src/root.bp` · `erika/src/erika.bp` — `default` is deleted

```diff
-pub default mod zeta;
+pub mod zeta;

-pub default fn query(s: string) -> string { return s; }
+pub fn query(s: string) -> string {
+    return s;
+}
```

Three occurrences across three files: one `pub default mod` in each `root.bp`, one `pub default fn`
in `erika/src/erika.bp`.

**It is not a parser gap.** Both flags are recorded:

| | Field | Written by | Read by |
|---|---|---|---|
| `pub default mod` | `ModDecl.isDefault` (`ast.zig:74-77`) | `parser/decls.zig` | `comptime.zig:914` |
| `pub default fn` | `FnDecl.isDefault` (`ast.zig:1976`) | `parser/decls.zig:281`, `:292` | `comptime.zig:920` |

`format.zig` reads **neither**. Its only `default` is `BehaviorMethod.is_default` — the unrelated
`default fn` of a behavior body, printed at `format.zig:1720-1721`. So the two package-default
keywords fall out of the printer because no arm was ever written for them.

**What they drive.** `comptime.zig:914-932`: `pub default mod` names the package **handle** that
`import <pkg>` resolves to, and `pub default fn` names the **handler** aliased under it, which is
what makes `<pkg> "…"` bind. Delete the keywords and the package surface stops existing.

**Why the libraries still pass.** In emilia and erika the library name, the default module's name and
the default fn's name coincide (`erika` / `erika` / `erika`), so the alias the keyword would have
created is the binding that already exists under that name. erika's own source says so: *"the handler
keeps the lib's name so the generic-loader namespace form still resolves through it."* The loss is
masked, not absent. On a minimal package where the names differ:

```
before format:  pub default mod zeta;  ·  pub default fn query(…)   → consumer runs, exit 0
after  format:  pub mod zeta;          ·  pub fn query(…)           → error: unbound variable 'zeta', exit 1
```

**`botopink format` can break a downstream consumer, silently, and `format --check` then reports the
broken file as clean.**

**Fix.** Two arms in `format.zig`'s mod and fn printers, reading the two `isDefault` flags. No parser
change, no AST change — the smallest fix of this front and the only one that is entirely inside the
file the front owns. **It is step 3, the front's first commit**, ahead of G1–G6.

**Regression test.** `assertFormat` over `pub default mod X;` and `pub default fn f() {}`; and
`assertLossless` (step 5) extended from comment tokens to **keyword** tokens would have caught it,
which is an argument for defining the property over the whole token stream rather than over comments
alone.

### `emilia/src/tokens.bp` — 13 variants hoisted above the sections

The case decision 18 exempted. The six named in the decision are the outermost group — `Hover`,
`Focus`, `Active`, `Md`, `Lg`, `Xl`, each `(inner: Token[])` — and they move from the bottom of
`pub type Token { … }` to the top, above its ten sections:

```
before:  Text{} Font{} Color{} Bg{} Pad{} Margin{} Layout{} Flex{} Border{} Effect{}
         Hover(inner: Token[]), Focus(…), Active(…), Md(…), Lg(…), Xl(…)

after:   Hover(inner: Token[]), Focus(…), Active(…), Md(…), Lg(…), Xl(…)
         Text{} Font{} Color{} Bg{} Pad{} Margin{} Layout{} Flex{} Border{} Effect{}
```

Their order relative to each other is preserved.

**It is not those six, and not that level.** The same rule fires at **four** sites and moves **13**
variants: the top level (6), `Color` (`White`, `Black`, `Hex(value: string)` above
`Red`/`Blue`/`Green`/`Gray`), `Bg` (the same three above `Red`/`Blue`/`Gray`) and `Border.Color`
(`Hex(value: string)` above `Red`/`Gray`). Any enum body that writes a variant after a section is
affected, at any depth.

**Cause:** [`parser-gaps.md`](./parser-gaps.md#g1--the-order-of-enum-members) G1 — the AST keeps
variants and sections in two slices with no ordinal, so `format.zig:1847-1848` (and `:1889-1892` for
nested sections) can only print all of one and then all of the other. **The formatter is not sorting;
the interleaving is gone before it runs.**

**Does it change meaning? Measured: no.** emilia was built from both orderings on all four backends:

| target | orig vs formatted |
|---|---|
| commonJS | identical |
| erlang | identical |
| beam | identical |
| wasm | identical |

Nothing in `src/codegen/` keys on a variant ordinal (`grep -r 'variantIndex\|tag_index\|ordinal'` over
`src/codegen/` → 0 hits), and the `emilia-card` example produces identical HTML and identical
content-derived class hashes (`e_5c8cac5e`, `e_2b94acf6`, `e_44fb330f`) either way.

**So step 2 of the [README](./README.md) is answered in advance, and its answer is the good one:**
emilia's exemption is a **fidelity** hold, not a correctness hold. It is graded **C** anyway — a
formatter that moves declarations is categorically different from one that moves whitespace, the
authored grouping is destroyed and unrecoverable, and the property becomes a correctness defect the
moment any backend or tool becomes order-sensitive. `emilia.bp`'s `case t { … }` arms are **not**
reordered, so after formatting the declaration order and the dispatcher order simply disagree.

Other changes in the same file, all **A**: compact one-line sections exploded one per line (~20),
trailing commas added (22), blank lines between sections removed (10). The file goes from 133 lines
to 261.

### `erika/src/erika.bp` — `default`, plus the largest A-diff in the ecosystem

Beyond the deleted `pub default fn`, this file carries 81 of the 104 single-statement `if`/`else`
brace unwraps, closure bodies re-indented by 4 with the closing `});` indented too (≈34 lines), a `;`
appended to a closure's last expression (3) and 3 blank lines removed. Those are A and B rows; the
file is **C** because of the one keyword.

---

## B — the library is right

### `jhonstart/src/hooks.bp`

**All three B rows implemented**: the joined signature by decision 61 rule 4, the exploded empty
closure by rule 2, and `rakun/src/runtime.bp`'s comment column by C-12 (below).

| Change | Count | Why the library is right |
|---|---|---|
| a deliberately wrapped 3-line `reducer` signature joined into **one 122-character line** | 1 | no other line in the file exceeded 100 characters. A formatter that has a break policy for bodies should have one for signatures |
| an empty closure `{ next -> }` exploded to three lines, the middle one **whitespace-only** | 2 | the file had **0** trailing-whitespace lines before and **2** after, and the result is idempotent, so the garbage persists |
| `import { X }` → `import {X}` | 1 | A — the canonical form |
| `;` appended to a closure's last expression | 2 | A |
| a trailing comma removed from a call's argument list | 1 | A |
| an end-of-line comment re-spaced | 1 | A — harmless, and it matches [`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md)'s R1 row |

### `rakun/src/runtime.bp`

One change in the whole file: an aligned end-of-line comment's continuation line, indented to column
31 to sit under the first, is re-emitted at column 0. The **token stream is identical** — nothing is
lost, the comment's alignment is. This is exactly the row
[`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md)'s R1 corrected from the 1.0.4-beta
claim ("moves to the next line" → "loses its padding"), confirmed here from the compiler side.

Graded **B** rather than A because the alignment was authored and a formatter that preserves a
comment's text but not its column is making a choice, not applying a rule. Low priority: it is one
line in one file.

**Closed 2026-09-26** (compiler `0f0be511`, C-12's comment column): a comment continuing a trailing
comment on the next line, from the same source column, prints under the first comment's printed
column. The revision of `runtime.bp` 09 had to re-emit at column 0 (`dcf1938`) now round-trips at
lines 10-15.

---

## A — the formatter is right

| File | Categories (count) | Notes |
|---|---|---|
| `emilia/src/emilia.bp` | `case`-arm alignment padding collapsed (90 lines); `#[A, B]` split into `#[A]` `#[B]` (3); `import { X }` → `import {X}` (1); a method chain joined to one line (1) | token stream equal modulo the three annotation splits; comments intact |
| `jhonstart/src/element.bp` | one-line fn bodies expanded to three lines (6); blank lines inserted between declarations (7); `if (c) { return x; };` → `if (c) return x;` (2); array-literal arguments re-indented deeper | nothing lost |
| `jhonstart/src/html.bp` | `if`/`else` brace unwrap (21); closure and `loop` bodies re-indented +4 (28 lines); `import {X}` (1); 1 blank line removed | the over-indentation is a B-axis complaint, filed below, not a defect |
| `rakun/src/decorators.bp` | a badly wrapped call rejoined: `join(\n ""\n)` → `join("")` (6) | **token stream byte-identical** |

---

## Cross-cutting B candidates

Three rules produce most of the 923 lines and are worth deciding as rules, not file by file. **Each
is a decision the maintainer owes**, because each changes how every library looks:

| Rule | Evidence | Question |
|---|---|---|
| **closure bodies are indented +4, and the closing `});` with them** | inflates erika by 31 lines and `tokens.bp` from 133 to 261 | is a closure's body one level in from the call, or from the statement? |
| **a wrapped signature is joined** | `hooks.bp`'s 3-line `reducer` becomes 122 characters in a file whose longest line was under 100 | is there a line-length budget at all? the formatter has a break policy for bodies and none for signatures |
| **a single-statement `if`/`else` loses its braces** | 104 occurrences across three files | the largest single category in the ecosystem, and the one most likely to be argued about |

None of them loses information. They are listed here so step 5 takes them as one decision each rather
than as 104 diffs.

---

## Secondary formatter-quality defects

Neither changes meaning; both are worth a line in step 5:

1. **Trailing whitespace is emitted.** `hooks.bp` gains two whitespace-only lines from an empty
   closure. Idempotent, so it persists once committed.
2. **`format --check` passes on the formatted tree.** Confirmed: after formatting the copies, all five
   libraries return exit 0. So whatever the canonical form is, it is stable — which is the property
   that makes every row above a decision rather than a bug hunt.
