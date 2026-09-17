# The JS bridges — JS-1…JS-6

> Carried from `1.0.2-beta/08-js-bridges/` into 1.0.4-beta. `file:line` and counts were measured at that milestone's
> commit — re-locate by symbol. `F1…F12` and bare front numbers are the old numbering: see
> [`../fronts.md`](../fronts.md#old-front-numbers).

A bridge is a node the JS code model carries only because the commonJS / typescript lowering still
produces a shape the model would otherwise forbid. Deleting its **build sites** is the fix, and the
node goes with the last one. Each is named in the model (`BRIDGE —` doc comments in
`src/codegen/js/js_ast.zig`) and in the bridge table of `src/codegen/js/AGENTS.md:60-70`, so a grep
finds every one.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`. Every `file:line` is at
HEAD.

---

## Inventory

Find them with (note the receiver spellings — `b.stmtExpr`, not `stmtExpr` on a writer):

```sh
rg 'stmtExpr\(|\.missing|\.unnamed|\.match = |throw_ = ' src/codegen/commonJS.zig src/codegen/typescript.zig
```

| Bridge | Build sites | Snapshots it pins | Of those, illegal output |
|---|---|---|---|
| JS-1 `Expr.stmt_expr` | 8 (`src/codegen/commonJS.zig` 2220, 2223, 2242, 2249, 2285, 2313, 2505, 2587) | **9** | 9 |
| JS-2 `Expr.missing` | 6 (`src/codegen/commonJS.zig` 1681, 2082, 2133, 2227, 2414, 2945) | 2 | 2 |
| JS-3 `Rest.unnamed` / `Spread.unnamed` | 3 (`src/codegen/commonJS.zig` 1694, 1728, 2359) | 2 | 2 |
| JS-4 `Pattern.match` | 8 (`src/codegen/commonJS.zig` 1709, 1710, 1714, 1717, 1718, 1724, 1734, 1739) | 0 | — |
| JS-5 `TsType.missing` | 1 (`src/codegen/typescript.zig:210`) | 14 | 0 (a `.d.ts` is never executed) |
| JS-6 `Stmt.throw_ = null` | 1 (`src/codegen/commonJS.zig:2224`) | 0 | — |

JS-1/2/3 distinct snapshots = **12** (`destructure_record_parameter_in_fn` is pinned by both JS-2
and JS-3), which is exactly the `node --check` failure set.

### How "illegal output" was measured

Every `----- JAVASCRIPT -- <file>.js` block under `snapshots/codegen/commonJS/` was extracted and run
through `node --check`. At HEAD it rejects exactly these 12 modules (all `main.js`):

`case_multiple_subjects`, `destructure_record_parameter_in_fn`,
`destructure_record_val_binding_with_spread`, `loop_break_with_value`, `loop_continue_in_iteration`,
`loop_even_numbers_with_break`, `loop_filter_with_conditional_break`,
`loop_map_with_break_add_tax`, `loop_map_with_break_simple`,
`narrow_else_if_chain_with_null_checks`, `range_open_ended_range`, `throw_inside_case_arm`.

8 are label `b` and 4 label `a`. The 4 label-`a` ones (`case_multiple_subjects`,
`destructure_record_val_binding_with_spread`, `loop_continue_in_iteration`,
`range_open_ended_range`) print nothing by construction, so **no RUN LOG can ever show them** — deleting the build
site, or a `node --check` gate, is the only way they are ever seen. Of the 8 label `b`, 2 are also
invisible to the cross-backend comparison, because erlang crashes on the same fixture and the pair
reads as agreement (`narrow_else_if_chain_with_null_checks` — erlang's E2;
`destructure_record_parameter_in_fn` — erlang's E1).

(An extractor that does not skip an *empty* code block will report a thirteenth,
`template_end_to_end_cross_module_html_mirrors_the_canonical_example/view.js`; that module's block is
empty and is not a failure.)

## What each bridge stands for, in the language

A bridge is a *language* shape the lowering has no expression form for. Deleting the build site
means teaching one lowering something.

| Bridge | The botopink shape | What the lowering must learn |
|---|---|---|
| JS-1 | a `loop` used as a **value** (a comprehension), and `break <v>` / `continue` / `return` / `throw` inside a loop body or an `if`/`else if` lowered in expression position | lower a value-position `loop` to an expression (an accumulating IIFE, or `.map`/`.filter` where the shape allows) and lower the jumps to *that* expression's control flow, not to a JS `return` wrapped in an arrow. Same family as `return <case>` in a `#[@result]` fn — erlang's E8 |
| JS-2 | a destructuring **parameter** (which takes no default), and a `case` over several subjects | a destructuring parameter emits no `= `; a multi-subject arm builds the conjunction of its per-subject tests, and an arm with no test drops its `if` |
| JS-3 | `{ x, .. }` — a record / list destructuring that **ignores the rest** | an unnamed `..` binds nothing, and JS destructuring already ignores unlisted keys and trailing elements: emit no rest element (see the correction below) |
| JS-4 | `val Circle(r) = shape` / `assert x is Some(n)` — a **pattern in binding position** | a `ctor` destructuring lowers to a real JS test-plus-destructure, not to botopink's own pattern spelling |
| JS-5 | an exported fn's **annotated parameter types**, in the `.d.ts` | read `Param.typeRef` instead of the legacy `Param.typeName` (see the correction below) |
| JS-6 | a bare `throw` with no operand | decide the semantics (rethrow the caught value, or reject it in the checker) and make `Stmt.throw_` non-optional |

---

## JS-1 — `Expr.stmt_expr`: a statement in expression position

Renders the statement with no terminator of its own: the variant at
`src/codegen/js/js_ast.zig:88`, the builder `stmtExpr` at `:686-689`, the emitter arm at
`src/codegen/js/js_emitter.zig:203`, and a unit test that pins `return continue;` at
`src/codegen/js/js_emitter.zig:801`.

The eight build sites, by the statement they wrap: `return` (`:2220`), `throw` (`:2223`), `break`
(`:2242`), `continue` (`:2249`), a local `val` (`:2285`), a destructuring local `val` (`:2313`), a
bare block (`:2505`) and a `for … of` loop (`:2587`).

**What it pins — nine snapshots, every one a `node --check` SyntaxError:**

| Snapshot | Emitted | Label | Visible today? |
|---|---|---|---|
| `loop_map_with_break_simple` | `const dobrados = for (const id of ids) {` | b | yes (empty RUN LOG) |
| `loop_even_numbers_with_break` | `const processamento = for (const i of Array.from(…)) {` | b | yes |
| `loop_filter_with_conditional_break` | `const apenasGrandes = for (const valor of precosBrutos) {` | b | yes |
| `loop_map_with_break_add_tax` | `const precosComTaxa = for (const valor of precosBrutos) {` | b | yes |
| `loop_break_with_value` | `return for (const x of arr) {` | b | yes |
| `throw_inside_case_arm` | `if (_s === "Fail") return return ({ error: "failed" });` | b | yes |
| `narrow_else_if_chain_with_null_checks` | `… else { return  if ((x !== 0)) { … } };` | b | **no** — erlang aborts on the same fixture, so the pair reads as "agreement" |
| `loop_continue_in_iteration` | `(() => { if (((x % 2) !== 0)) { return continue; } })();` | a | **no** |
| `range_open_ended_range` | `(() => { if ((i > 100)) { return return; } })();` | a | **no** |

The last three are the argument for this bridge: three of the nine are invisible to every RUN LOG
comparison the suite can make.

**Caveats found by reading the emitted modules, not just checking them:**

- `loop_continue_in_iteration` lowers `return loop (arr) { x -> if (…) { continue; }; yield x; }` to
  `arr.map(…)`. Making the `continue` parse is not enough: `.map` cannot drop an element, so the
  comprehension must become a filter-map, or it returns the odd numbers as `undefined`.
- `range_open_ended_range` also lowers `loop (x..)` to
  `for (const i of (() => { throw new Error("open-ended range unsupported on commonJS"); })())`. Once
  the `return return` goes, `countUp` still throws on call. That is an unsupported shape, not a
  bridge; the fixture is label `a`, so only a new `b` fixture would show it.
- `throw_inside_case_arm`'s `return return` is not a JS-lowering bug on its own — it is the
  `#[@result]` wrap applied to a whole `case` instead of to each non-jumping arm, which erlang spells
  as `{ok, {error, …}}` ([`../02-erlang/causes.md`](../02-erlang/causes.md), E8). Fix the wrap once,
  in the transform pass, and both spellings go.
- `loop_break_with_value`'s expected value is itself unsettled: `fn find(arr) -> i32` returns a
  list. Settle the return type in [`../06-checker/README.md`](../06-checker/README.md) before
  re-recording its value.

**What deleting it requires:** a botopink `loop` used as a value is a comprehension; lower it to an
expression and lower `break <v>` / `continue` inside it to that expression's control flow. Delete the
eight `b.stmtExpr` calls, then `Expr.stmt_expr` and `Block.Layout.bare`
(`src/codegen/js/js_ast.zig:399`, which `:398` documents as reachable only through `stmt_expr`; its
emitter arm is `src/codegen/js/js_emitter.zig:541`), and the `:801` unit test.

The same language shape is wasm's W4 ([`../03-wasm/causes.md`](../03-wasm/causes.md)) and beam's B7
([`../01-beam/causes.md`](../01-beam/causes.md)).

## JS-2 — `Expr.missing`: an expression the lowering never produced

**What it pins — two snapshots, both SyntaxErrors:**

| Snapshot | Emitted | Build site | Label |
|---|---|---|---|
| `destructure_record_parameter_in_fn` | `function greet({ name, ... } = ) {` (`.snap.md:22`) | `src/codegen/commonJS.zig:1681` gives an object destructuring *parameter* the `= ` of a destructuring assignment with nothing to assign | b |
| `case_multiple_subjects` | `if () return null;` twice (`.snap.md:16-17`) | `src/codegen/commonJS.zig:2945` emits a `case` arm over several subjects (`case a, b { 0, 0 -> …; _, _ -> … }`) with no condition | a — only `node --check` sees it |

**The four remaining sites** — each is either a real absence to spell out or an unreachable case
that should be an error:

| Site | What it is |
|---|---|
| `:2082` | a builtin call's second argument when the call has only one |
| `:2133` | the tail of an unhandled builtin |
| `:2227` | `try` with no operand — the JS twin of `src/codegen/erlang.zig:3176` |
| `:2414` | a `comptime { … }` block with no `break` value (`:2405-2415`) — **the same latent defect as `src/codegen/erlang.zig:3632`**, which is what makes erlang's `comptime_block_with_break` emit `result() -> (X * 2).`. It is unreached on commonJS only because the decl-level path folds `val result = comptime {…}` to `const result = 20;` first. Fix it here rather than waiting for a fixture |

**Why `if ()`:** `buildCondExpr` (`src/codegen/commonJS.zig:2831`) returns `null` for a pattern it
has no test for — its doc comment says so, naming JS-2. The guard path (`:2936`) and the block-body
path (`:2943`) then drop the `if`; the expression-body path at `:2945` does not, and writes
`cond orelse .missing`. In `case_multiple_subjects` both arms hit it: `0, 0` because a multi-subject
pattern gets no test, and `_, _` because a wildcard has none.

**Correction to the earlier analysis:** that row called the fix "a real **disjunction**". The arm
`0, 0 ->` over `case a, b` matches when *both* subjects match — it is a **conjunction** of
per-subject tests (the disjunction is `or`, a different pattern kind, `:1734`).

**What deleting it requires:** a destructuring parameter takes no default; a multi-subject arm builds
the conjunction of its per-subject tests; an arm with no test drops its `if`, as the other two paths
already do; then audit the four sites above. Delete the variant with the last site.

## JS-3 — `Rest.unnamed` / `Spread.unnamed`: a `...` with nothing after it

**What it pins:** `const { x, ... } = p;` (`destructure_record_val_binding_with_spread.snap.md:21`,
label `a`) and the same `...` inside `destructure_record_parameter_in_fn.snap.md:22`. Both are
SyntaxErrors.

Build sites: `buildNamesPattern` (`src/codegen/commonJS.zig:1694`, `.rest = if (n.hasSpread)
.unnamed else null`), the list pattern (`:1728`, a list spread whose name is empty) and an array
literal spread with an empty name (`:2359`). The emitter's `.unnamed` arms are
`src/codegen/js/js_emitter.zig:251` (`writeSpread`) and `:374` (`writeRest`); the variants are
`src/codegen/js/js_ast.zig:204` (`Spread`) and `:257` (`Rest`).

**Correction to the earlier analysis.** The 1.0.1-beta row, and the comment at `:1693`, read this as
"a spread that binds a name, whose name the frontend does not carry", and prescribed carrying the
name through the AST. The fixtures say otherwise — neither source binds a name:

```botopink
val { x, .. } = p;                          // destructure_record_val_binding_with_spread
fn greet({ name, .. }: Person) -> string {  // destructure_record_parameter_in_fn
```

and the parser has no named form for a record rest: on `..` it sets `hasSpread = true` and stops
(`src/parser/decls.zig:1224-1229`, `src/parser/exprs.zig:543-549`), and the AST field is
`hasSpread: bool` (`src/ast.zig:984`). `..` means *ignore the rest*, and JS object and array
destructuring already ignore unlisted keys and trailing elements. So the fix for the two pinned
snapshots is **inside this front's file**: an unnamed rest emits no rest element (`const { x } = p;`,
`function greet({ name })`). No frontend change is needed for them.

A *named* list rest (`:1728` with `sp.len > 0`) is already carried and keeps `Rest.binding`. `:2359`
(an array **literal** with a nameless spread) is not reached by any snapshot; decide whether the
parser can produce it and make it an error if not.

**Acceptance for the bridge:** 0 `.unnamed` build sites; both variants and both emitter arms deleted;
both snapshots pass `node --check` and run.

## JS-4 — `Pattern.match`: a botopink pattern as a JS binding target

Eight build sites in `buildPattern` (`src/codegen/commonJS.zig:1704-1743` — lines 1709, 1710, 1714,
1717, 1718, 1724, 1734, 1739: variant binding / fields / patterns, number and string literals, a
number inside a list, `or` and multi), reached from `buildParam` (`:1675`) and
`buildDestructPattern` (`:1745`) — i.e. a `ctor` or `list` destructuring in parameter or `val`
position. `writeMatchPattern` (`src/codegen/js/js_emitter.zig:378`) then writes botopink's own
spelling (`Circle(r)`, `1 | 2`) into JS.

No snapshot reaches it, because the surface that would (`assert x is Some(n)`,
`val Circle(r) = shape`) does not parse — it is one of the three `b/missing` fixtures
(`narrow_assert_pattern_with_print`) whose programs never reach codegen, owned by
[`../06-checker/README.md`](../06-checker/README.md)'s parser-gap step. **Blocked on that parser gap.**
Once it lands, a `ctor` destructuring must lower to a real JS test-plus-destructure, not to a pattern
spelling.

The erlang side of the same gap is `destructPatternExpr`'s `.list, .ctor => return Ast.Expr.v("_")`
(`src/codegen/erlang.zig:2865`), which silently matches anything — the erlang front's.

**Acceptance for the bridge:** a fixture destructures a variant in binding position and runs; 0
`Pattern.match` build sites; `MatchPattern` (`src/codegen/js/js_ast.zig:283`) and
`writeMatchPattern` deleted.

## JS-5 — `TsType.missing`: a `.d.ts` parameter with no type

One build site, `namedType` (`src/codegen/typescript.zig:210`:
`return if (name.len == 0) .missing else .{ .name = name };`), and it is the most visible bridge in
the tree — **14** snapshots emit an untyped parameter:

| Snapshot | Emitted |
|---|---|
| `fn_max_via_if_comparison` (source `pub fn max(a: i32, b: i32) -> i32`) | `export declare function max(a: , b: ): i32;` |
| `fn_pub_exported_function` | `export declare function add(a: , b: ): i32;` |
| `import_multi_module_pub_fn_import` | `export declare function double(x: ): i32;` (`.snap.md:18`) |
| `reserved_word_identifiers` | `export declare function delete(with: , class: ): string;` (`.snap.md:33`) |
| `star_fn_pub_typedefs` | `export declare function loadOne(x: ): Promise<i32>;` |
| `external_global_math` | `export declare function floor(n: ): f64;` |

The full 14 (`rg -l ': \)|: ,' snapshots/codegen/commonJS/` at HEAD):
`external_a2_chained_host_call_renders_verbatim`, `external_a3_result_template_owned_declare_fn`,
`external_call_emits_module_symbol`, `external_global_math`, `external_import_binds_symbol`,
`external_target_mixed_with_external_in_one_decl`,
`external_target_template_equivalent_to_external_target_template`, `fn_max_via_if_comparison`,
`fn_pub_exported_function`, `import_cross_module_record_construct_and_assoc_fn`,
`import_multi_module_pub_fn_import`, `reserved_word_identifiers`, `star_fn_pub_typedefs`,
`std_package_order_enum_module_with_type_export`.

**Correction to the earlier analysis.** The 1.0.1-beta row read this as "a `declare fn`'s parameter
types are not carried to the typedef backend". Half the list is ordinary `pub fn`s whose parameters
*are* annotated (`fn_max_via_if_comparison`: `a: i32, b: i32`), and the type is carried — just not in
the field `typescript.zig` reads:

| Step | Site |
|---|---|
| the parser builds a plain parameter with `typeRef` only | `src/parser/decls.zig:1352` — `Param{ .name = name, .typeRef = typeRef, .modifier = modifier, .default = defaultExpr }` |
| `typeName` keeps its default | `src/ast.zig:1022` — `typeName: []const u8 = "",` (only the destructuring forms at `src/parser/decls.zig:1246`, `:1268` fill it) |
| the typedef builder reads `typeName` | `params` (`src/codegen/typescript.zig:191-197`, the read at `:195`) and `delegate` (`:181`) call `namedType(p.typeName)` |
| an empty name becomes the bridge | `:210` |
| the renderer that would have been right already exists | `typeRef` (`src/codegen/typescript.zig:259`), used for enum variant fields at `:121` |

So the fix is local to `src/codegen/typescript.zig`: build each parameter's type from
`try self.typeRef(p.typeRef)`. `:132` (`InterfaceDecl` fields) also goes through `namedType`, but
`InterfaceField.typeName` is a real field the parser fills (`src/parser/decls.zig:605`) and is not
part of this bridge.

The emitted `.d.ts` is not executed, so this changes 14 snapshots **without changing any RUN LOG** —
review each diff as the assertion. `src/codegen/js/ts_emitter.zig:66` is the `.missing` arm to
delete; `:266` is a unit test that pins it and must go with it.

**Acceptance for the bridge:** `rg -l ': \)|: ,' snapshots/codegen/commonJS/` is empty; 0
`TsType.missing` build sites; the variant deleted.

## JS-6 — `Stmt.throw_ = null`: a bare `throw`

One build site (`src/codegen/commonJS.zig:2224`,
`.throw_ = if (r) |val| try self.buildExpr(val.*) else null`): a botopink `throw` with no value
becomes `throw;`, a JS SyntaxError. No snapshot reaches it today, so **add one first** — a fixture
that throws bare inside a `try` — then decide the semantics (rethrow the caught value, or reject it in
the checker) and make `Stmt.throw_` non-optional.

The erlang twin of the same absence is `src/codegen/erlang.zig:3175`, a `raw("")` the erlang front
also has to give a real node ([`../02-erlang/raw-rows.md`](../02-erlang/raw-rows.md)). Decide the
semantics once, before either front starts, or the two backends will disagree.

**Acceptance for the bridge:** a fixture exercises bare `throw` on all four backends; `Stmt.throw_`
carries a required operand.

---

## Rule

- A bridge whose output is *illegal* (JS-1, JS-2, JS-3, JS-6) **changes the emitted code and its RUN
  LOG** when it goes — that is the point, and the new snapshot must be a program that runs.
- JS-5 changes 14 `.d.ts` sections and no RUN LOG; each diff is reviewed as the assertion.
- A bridge that is only a shape concern (JS-4, once unblocked) keeps the snapshots
  **byte-identical**; a diff there is a bug found, and it moves to [`causes.md`](./causes.md).
- `src/codegen/js/AGENTS.md` loses the bridge's row (`:65-70`) in the commit that deletes its last
  build site.
