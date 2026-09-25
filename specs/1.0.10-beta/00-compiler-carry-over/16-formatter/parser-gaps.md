# What the formatter rests on, and what each gap costs

The formatter re-prints the AST. Whatever the parser did not record, it cannot print back — so every
red in [`reds.md`](./reds.md) that is a *defect* rather than a disagreement traces to a field that
does not exist. This file names each missing field, reproduces the loss it causes, and measures the
cost of recording it.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`. Every `file:line` and count
was measured at `botopink-lang` `c2dd780` (2026-09-18) in a scratch worktree.

---

## The gaps

| # | What is not recorded | What is lost | Where | Cost |
|---|---|---|---|---|
| G1 | **the order of enum members** | a variant written after a section is hoisted above it | `ast.zig:2135-2141` | **small** — 2 fields, 3 files, no backend touched. See [G1](#g1--the-order-of-enum-members) |
| G2 | **a trailing comment on a record field** | the comment is re-attached to the *next* field; on the last field it is **deleted** | `ast.zig:2084-2097`, `parser/decls.zig:1148-1152` | small — 1 field, 3 files |
| G3 | **any comment on an enum variant** | the comment is **deleted** | `ast.zig:1576-1588` | small — 2 fields, 3 files |
| G4 | **a trailing comment on a method** | the comment is moved below the member | `ast.zig:1213-1236` | small — 1 field, 3 files |
| G5 | **blank lines, and comments, inside an `if` then-branch and inside a lambda body** | the blank lines are **deleted**; a `//` comment there is a **parse error** | two inlined block loops: `parser/exprs.zig:162-179` and `:944-951` | small — delete both loops in favour of `parseStmtListInBraces`. **The parse-error half is [`15-language-surface`](../15-language-surface/README.md)'s** |
| G6 | — (recorded, and not printed) | blank lines inside an `if` **else**-branch are deleted although the parser recorded them | `format.zig:1116-1126` | **one function**, this front's own file |

**G1–G5 are the parser's; G6 is the formatter's**, and together with D1 (see the [README](./README.md))
that makes two defects that need no parser change at all. None of G1–G5 needs a *position*: a member
ordinal, three trailing-trivia slots and two block loops replaced by the one that already has the
options are enough. The phrase "the parser records no member positions" is literally true (`ast.zig`
carries **5** `loc: Loc` fields in total, none of them on a member), but positions are not what the
formatter needs.

### The block-fidelity matrix

`parseBlock` (`parser.zig:698-736`) takes `trackEmptyLines` and `handleComments` as options, and
`parseStmtListInBraces` (`:741-747`) sets both. Two blocks never reach it — each carries its own
inlined loop, written before the options existed — and one that does is not printed back:

| Block | Parsed by | Blank line | `//` comment |
|---|---|---|---|
| fn body | `parseStmtListInBraces` (`decls.zig:451`) | **kept** | **kept** |
| `test` body | `parseStmtListInBraces` (`decls.zig:515`) | **kept** | **kept** |
| `if` **then**-branch | its own loop, `exprs.zig:162-179` | **dropped** | **parse error** |
| lambda body — which is every `loop (…) { x -> … }` body | its own loop, `exprs.zig:944-951` | **dropped** | **parse error** |
| `if` **else**-branch | `parseStmtListInBraces` (`exprs.zig:190`) | **dropped** — recorded, then not printed (G6) | kept |

Measured one probe per row: format a scratch copy and `diff` it; `botopink check` for the comment.

**What *is* preserved, and was worth checking:** a blank line **between members** of a type or
behavior body — `comments: []const []const u8` encodes one as `""` (`ast.zig:1233-1236`) — and a
trailing comment on a **statement** (`val a = 1; // bound here` round-trips).

---

## G1 — the order of enum members

### The loss

```botopink
type Token {
    Bold,
    Size { Sm, Lg }
    Italic,
    Color { Red, Blue }
    Under,
}
```

`botopink format` returns:

```botopink
type Token {
    Bold,
    Italic,
    Under,
    Size {
        Sm,
        Lg,
    }
    Color {
        Red,
        Blue,
    }
}
```

`Italic` and `Under` are **hoisted above** the sections they were written after. This is the emilia
`tokens.bp` case of [decision 18](../../../1.0.5-beta/decisions-taken.md#18-emilias-tokensbp-and-format---check),
reproduced in nine lines.

### The mechanism

`TypeShape.EnumShape` holds two parallel slices with no ordinal between them
(`ast.zig:2135-2141`):

```zig
pub const EnumShape = struct {
    variants: []EnumVariant,
    sections: []EnumSection = &.{},
};
```

`EnumSection` repeats the shape for nested levels (`ast.zig:1595-1601`). The parser appends to one
list or the other as it walks — `parseEnumItem` (`parser/decls.zig:811-880`) takes
`variants: *ArrayList(EnumVariant)` and `sections: *ArrayList(EnumSection)` and pushes onto whichever
the item is. The interleaving is gone at that point.

The formatter then has no choice (`format.zig:1847-1848`):

```zig
for (variants) |v| try lines.append(this.arena, try this.concat(try this.fmtEnumVariant(v), try this.text(",")));
for (sections) |sec| try lines.append(this.arena, try this.fmtEnumSection(sec));
```

and the same at `format.zig:1889-1892` for nested sections. **The formatter is not wrong here; it is
printing everything it was given, in the only order it has.**

The AST's own doc comment states the intent the representation breaks (`ast.zig:1592-1594`):

> Sections nest arbitrarily deep; variants and nested sections **may interleave at any level**.

### The cost, measured

Two shapes, and the difference between them is what makes this a small change instead of a
cross-front one.

| | Change | Files touched | Blast radius |
|---|---|---|---|
| **A** | replace the two slices with one `members: []EnumMember` tagged union | `ast.zig`, `parser/decls.zig`, `format.zig`, **and every reader of `.variants()` / `.sections()`** | **35 call sites in 9 files** — `codegen/{beam_asm,commonJS,erlang,typescript,wat}.zig`, `comptime/infer.zig`, `comptime.zig`, `format.zig`, `parser/tests/surface.zig`. Five of those files belong to fronts 02–05 and two to front 01 |
| **B** | add `order: u32` to `EnumVariant` and to `EnumSection`; the parser assigns a running index per body; the formatter merges the two lists by it | `ast.zig` (2 fields + 0 deinit lines — `u32` owns nothing), `parser/decls.zig` (one counter in `parseEnumItem`), `format.zig` (a merge at `:1847-1848` and `:1889-1892`) | **3 files, no backend, no other front.** The 35 call sites keep reading the two slices unchanged |

**Recommended: B.** A is the representation the language deserves and is the right change to make
*once* — but it is a five-front change made for the formatter's benefit, and 02–05 own those emitters
wholesale for parts of this milestone. B is additive, costs nothing to any reader that does not want
it, and can be replaced by A later without the formatter changing again: the formatter asks for a
merged member list either way.

The measurement:

```
$ rtk proxy grep -rn "\.variants()\|\.sections()" --include=*.zig . | wc -l
35
$ rtk proxy grep -rln "\.variants()\|\.sections()" --include=*.zig . | sort
./codegen/beam_asm.zig
./codegen/commonJS.zig
./codegen/erlang.zig
./codegen/typescript.zig
./codegen/wat.zig
./comptime/infer.zig
./comptime.zig
./format.zig
./parser/tests/surface.zig
```

### Does the reordering change meaning? Measured: no

The ordering is not obviously cosmetic: a section desugars into a synthesised inner enum with a
mangled name (`ast.zig:2137-2140`), and a variant's ordinal is what a numeric backend encoding would
use. If any emitter assigned a run-time encoding by position in `variants`, hoisting would change the
program and emilia's exemption would be a **correctness** hold.

It does not. emilia was built from both orderings on all four targets and the emitted output is
byte-identical on commonJS, erlang, beam and wasm; `grep -r 'variantIndex\|tag_index\|ordinal'` over
`src/codegen/` returns **0** hits; and the `emilia-card` example produces identical HTML and identical
content-derived class hashes either way. The evidence is in
[`reds.md`](./reds.md#emiliasrctokensbp--13-variants-hoisted-above-the-sections).

So the exemption is a **fidelity** hold. Step 2 of the [README](./README.md) re-runs this measurement
at the front's own HEAD, because an emitter that starts keying on an ordinal turns a style question
into a correctness one silently.

## G2 — a trailing comment on a record field

### The loss

```botopink
type Point(
    x: i32, // the horizontal coordinate
    y: i32, // the vertical one
)
```

becomes

```botopink
type Point(
    x: i32,
    // the horizontal coordinate
    y: i32,
)
```

Two things happen: `x`'s comment is **re-attached to `y`** as a leading comment, which says something
false about the program; and `y`'s comment is **deleted**, because there is no next field to absorb
it. The result is idempotent — formatting again changes nothing — so `format --check` goes green on
a file that has lost a line.

### The mechanism

`Field.comments` is leading-only (`ast.zig:2091-2094`):

```zig
/// `//` comments written before the field in a 1.0.3 field list
comments: []const []const u8 = &.{},
```

`parseFieldList` (`parser/decls.zig:1130-1178`) collects comments at the **top** of each loop
iteration, so a comment that follows field *n* on the same line is read as a leading comment of field
*n+1*. And when the loop's next iteration meets `)` instead of a field, the comments it has just
collected are freed (`parser/decls.zig:1148-1152`):

```zig
if (this.check(.rightParenthesis) or this.check(.endOfFile)) {
    for (comments.items) |c| alloc.free(c);
    comments.deinit(alloc);
    break;
}
```

That `alloc.free` is where the last field's comment is destroyed.

### The cost

`Field` already carries an optional, additive slot of exactly this shape — `typeLoc`, added by
06 N30 with `{0,0}` as its synthesised default (`ast.zig:2095-2097`). Adding
`trailingComment: ?[]const u8 = null` follows that precedent: one field, one `deinit` line, one
capture in `parseFieldList` after `trailingComma = this.match(.comma)` gated on "the comment token is
on the same line as the field", and one render in `format.zig`'s field-list printer. **3 files.**
No reader that ignores the field is affected, and `jsonStringify` already writes `comments` only when
present (`ast.zig:2108-2110`), so the comptime AST snapshots do not move.

---

## G3 — any comment on an enum variant

### The loss

```botopink
type Color {
    Red, // warm
    Blue,
}
```

`// warm` is **deleted**. Not moved — deleted.

### The mechanism

`EnumVariant` has no comment field at all (`ast.zig:1576-1588`):

```zig
pub const EnumVariant = struct {
    name: []const u8,
    fields: []Field,
    numeric: bool = false,
    …
};
```

`parseEnumItem` never collects one. A record field at least has a leading slot to be mis-attached to;
a variant has nowhere to put a comment, so the token is skipped and the text is gone.

### The cost

Two fields on `EnumVariant` — `comments: []const []const u8 = &.{}` (leading, the same shape and the
same `""`-means-blank-line convention as `Field.comments` and `BehaviorMethod.comments`) and
`trailingComment: ?[]const u8 = null` — plus the collection in `parseEnumItem` and the render in
`format.zig`'s `fmtEnumVariant` (`:1880-1884`). **3 files**, the same three as G1 and G2, which is
why the [README](./README.md) lands G1–G4 as one parser commit and one formatter commit rather than
four of each.

---

## G4 — a trailing comment on a method

### The loss

```botopink
fn two(self: Self) -> i32 { return 2; } // trailing on a method
```

becomes

```botopink
fn two(self: Self) -> i32 {
    return 2;
}
// trailing on a method
```

The comment survives but moves below the member, where it reads as a leading comment of whatever
comes next. Nothing is deleted; the file is still idempotent.

### The mechanism

`BehaviorMethod.comments` is leading-only (`ast.zig:1233-1236`), written at `parser/decls.zig:1261`
and `:1429`. There is no trailing slot, so the comment is picked up as the *next* member's leading
comment, or — for the last member — by `bodyComments`, the "comment lines after the last member,
before `}`" slice (`ast.zig:2181-2182`), which is why it lands where it lands.

### The cost

`trailingComment: ?[]const u8 = null` on `BehaviorMethod`, captured at the two sites above and
rendered in `format.zig`'s method printer. **3 files.**

---

## G5 — blank lines and comments in an `if` then-branch and a lambda body

### The loss

```botopink
fn h() -> i32 {
    if (1 > 0) {
        println("a");

        println("b");
    };
    loop ([1, 2]) { x ->
        println("a");

        println("b");
    };
    return 1;
}
```

Both blank lines are **deleted**. And a `//` comment in either place is not lost but refused:

```
error: Unexpected token
 --> src/main.bp:3:9
  |
3 |         // a comment inside a loop body
  |         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Unexpected token
```

`docs.md:362` and `:540` write the comment form, so the refusal is a defect against the documents,
not a rule.

### The mechanism

`parseBlock` (`parser.zig:698-736`) is the one block parser, and `BlockParseOptions`
(`parser.zig:685-695`) is where `trackEmptyLines` and `handleComments` live. Two blocks never reach
it, because each was written with its own loop before the options existed:

- the `if` **then**-branch, `parser/exprs.zig:162-179` — `while (!this.check(.rightBrace) …) { const
  expr = try this.parseExpr(alloc); … try stmts.append(alloc, .{ .expr = expr }); }`, with
  `emptyLinesBefore` left at its default `0` and no comment arm;
- the lambda body, `parser/exprs.zig:944-951` — the same shape. **Every `loop (…) { x -> … }` body is
  a lambda body**, which is why the `loop` case is the one that was noticed.

The `if` **else**-branch does reach `parseStmtListInBraces` (`exprs.zig:190`), which is why a comment
there is kept — and its blank lines are still lost, for a different reason: G6.

### The cost

Replace both loops with `this.parseStmtListInBraces(alloc)`. The then-branch keeps its `x ->` binding
peek, which runs before the block and is unaffected. **2 call sites in 1 file**, and both gain the
`useAfterBranchGuard` the rest of the language already has — check that the guard does not red an
existing program before landing, and if it does, call `parseBlock` with the guard off.

**This is a parse error, so the fix belongs to
[`15-language-surface`](../15-language-surface/README.md)**, which owns the parse-error surface and
already holds a carve-out in `parser/exprs.zig`. This front states the formatting consequence and
takes the printing half.

---

## G6 — an `if` else-branch's blank lines are recorded and not printed

### The loss

The else-branch of the probe above loses its blank line although the parser recorded it.

### The mechanism

There are two statement-sequence printers and only one of them reads the field:

| | Reads `emptyLinesBefore` | Used by |
|---|---|---|
| `fmtStmtSeq` (`format.zig:345-368`) | **yes**, `:356-360` | fn bodies, `test` bodies, lambdas |
| `fmtBranchStmts` (`format.zig:1116-1126`) | **no** — it joins with `hardline()` and nothing else | both `if` branches |

`fmtBranchStmts` also has no trailing-comment arm, where `fmtStmtSeq` has one (`:350-355`).

### The cost

**One function, in this front's own file.** Either give `fmtBranchStmts` the two arms `fmtStmtSeq`
has, or delete it and call `fmtStmtSeq` — which is the better shape if the two are otherwise the same,
and the diff says whether they are. No parser change, and it lands with G5 so the then-branch has
something to print.

---

## G7 — a trailing comment on an array or tuple element

### The loss

Found by [`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md)' probe row (d), at the pinned
sibling commit: `erika/examples/erika-linq/src/main.bp:111-113` writes one comment per element, on the
element's own line (`Box(label: "sq", w: 4, h: 4),   // w == h, h > 2`). `botopink format` moves each
one to the line **below**, where it reads as the **next** element's — the same false re-attachment G2
was for a record field, and idempotent, so `format --check` is green over it. Reproduced at compiler
`f58fd392` on the minimal input:

```
val boxes = [          →   val boxes = [
    1, // one                  1,
    2, // two                  // one
    3,                         2,
];                             // two
                               3,
                           ];
```

### The mechanism

The array and tuple literals collect comments into one flat `comments` list plus `commentsPerElem`
(the count **before** each element, then the trailing ones) — `ast.zig:786-802`, filled by the two
literal loops in `parser/exprs.zig` (`:1398-1436` tuple, `:1462-1530` array). A comment token read
after an element's `,` is counted as the next element's leading comment; neither the comment's line nor
a same-line flag reaches the AST, so the printer cannot tell `1, // one` from `1,` / `// one`. This is
G2's mechanism on a different node, and the fix has G2's shape.

### The cost

An additive optional on the two literals — `trailingPerElem: []const ?[]const u8 = &.{}` (one slot per
element, filled only when the comment token is on the same line as the element's last token), omitted by
`jsonStringify` when empty so no parser snapshot moves — and the same-line test after
`this.match(.comma)` in both loops. The printer half is this front's and is small: `elem, // c` in the
open form, which a trailing comment already forces. **The parser half is not this front's**:
`parser/exprs.zig`'s literal loops are [`15-language-surface`](../15-language-surface/README.md)'s file,
and the carve-out this front holds is `parser/decls.zig`'s member sites only. Handed to 15; the printer
lands after it.

---

## What no gap explains

The body-brace expansion in the same probe —

```
-    fn one(self: Self) -> i32 { return 1; }
+    fn one(self: Self) -> i32 {
+        return 1;
+    }
```

— is not information loss. It is the formatter's canonical form: a method body always breaks. That is
a disagreement to settle in [`reds.md`](./reds.md), not a defect. The four red libraries carry
**923** changed lines between them (emilia 415, erika 267, jhonstart 211, rakun 30, by
`diff -u <lib>/src.orig <lib>/src | grep -c '^[+-]'` over formatted copies in a scratch directory);
[`reds.md`](./reds.md) attributes them by category.
