# Spec 04 — Emitter Centralization

**Version:** 1.0.2-beta
**Priority:** medium
**Continues:** [`../1.0.1-beta/04-emitter-centralization.md`](../1.0.1-beta/04-emitter-centralization.md)
**Depends on:** step 5 is blocked on a parser gap; every other step is scoped to one bridge

---

## Objective

Empty the bridge inventory. A bridge is a node the code model carries only because the lowering
still produces a shape that model would otherwise forbid; deleting its **build sites** is the fix,
and the node goes with the last one. What is left after that is the last hand-written target text
in the tree and the dead scaffolding the migration left behind.

A bridge is not cosmetic. Three of the eleven rows below (JS-1, JS-2, JS-3) pin output that is
*illegal on its target*: **12 commonJS snapshots emit JavaScript that does not parse**, measured
by running `node --check` over every emitted module. Four of those twelve are label `a` fixtures,
so no RUN LOG can ever show them — deleting the build site is the only way they are ever seen. A
fourth row (erlang `raw` — missing value) pins a module `erlc` rejects outright, and two more
(JS-4, JS-6) pin a shape that is illegal but that no fixture reaches yet.

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/codegen/`, except
`snapshots/…` (relative to `modules/compiler-core/`) and `libs/…` (relative to
`repository/botopink-lang/`). Every `file:line` is at HEAD.

## Current state

All four backends build a model and let an emitter render it. Target-text writer calls left in
the backends:

| File | Calls | What they are |
|---|---|---|
| `wat.zig` | 0 | — |
| `typescript.zig` | 0 | — |
| `commonJS.zig` | 3 | none of them target text: `:472` is a `std.debug.print` warning to stderr, `:1302` and `:1475` compose a **comment**'s wording into an arena buffer |
| `erlang.zig` | 2 | `:1584` / `:1587` — the `$stringify(…)` wrapper (step 10) |
| `beam_asm.zig` | 12 | 9 at `:603-617` (the `.S` module preamble, step 9) + 3 at `:2690`, `:2693`, `:2710` (the `#[@External.Beam]` verbatim passthrough, which stays) |

`Ast.Expr.r(` in `erlang.zig`: **13**.

The bridges are named, so a grep finds every one — note the writer grep needs the real receiver
spelling (`aw.writer.`), not `w.`:

```sh
rg 'stmtExpr\(|\.missing|\.unnamed|\.match = |throw_ = ' commonJS.zig typescript.zig
rg 'externCall\(' wat.zig
rg 'Expr\.r\(' erlang.zig
rg -n '\.(print|writeAll|writeByte)\(' beam_asm.zig erlang.zig
```

| Bridge | Build sites | Snapshots it pins | Of those, illegal output |
|---|---|---|---|
| JS-1 `Expr.stmt_expr` | 8 (`commonJS.zig` 2220, 2223, 2242, 2249, 2285, 2313, 2505, 2587) | **9** | 9 |
| JS-2 `Expr.missing` | 6 (`commonJS.zig` 1681, 2082, 2133, 2227, 2414, 2945) | 2 | 2 |
| JS-3 `Rest.unnamed` / `Spread.unnamed` | 3 (`commonJS.zig` 1694, 1728, 2359) | 2 | 2 |
| JS-4 `Pattern.match` | 8 (`commonJS.zig` 1709, 1710, 1714, 1717, 1718, 1724, 1734, 1739) | 0 | — |
| JS-5 `TsType.missing` | 1 (`typescript.zig:210`) | 14 | 0 (a `.d.ts` is never executed) |
| JS-6 `Stmt.throw_ = null` | 1 (`commonJS.zig:2224`) | 0 | — |
| wat `Module.externs` | 4 (`wat.zig` 2428, 2435, 2443, **3634**) | 0 | — |
| erlang `raw` — missing value | **7** (`erlang.zig` 2308, 3174, 3175, 3176, 3184, 3628, 3632) | 1 (`comptime_block_with_break`, a `COMPILE ERROR`) | → spec 03 step 2 |
| erlang `raw` — unreachable | 4 (`erlang.zig` 2967, 2977, 3537, 3768) | 0 | — |
| erlang `raw` — pre-spelled call head | 1 helper (`erlang.zig:3668`), **11** callers (1758, 3448, 3476, 3498, 3509, 3529, 3538, 3543, 3559, 3853, 3875) | all erlang | — |
| erlang `raw` — host template text | 1 (`erlang.zig:1566`) | — | stays |

JS-1/2/3 distinct snapshots = 12 (`destructure_record_parameter_in_fn` is pinned by both JS-2 and
JS-3), which is exactly the `node --check` failure set.

### What each JS bridge stands for, in the language

A bridge is a *language* shape the lowering has no expression form for. Deleting the build site
means teaching one lowering something; the table names which.

| Bridge | The botopink shape | What the lowering must learn |
|---|---|---|
| JS-1 | a `loop` used as a **value** (a comprehension), and `break <v>` / `continue` / `return` / `throw` inside it | lower a value-position `loop` to an expression (an accumulating IIFE, or `.map`/`.filter` where the shape allows) and lower the jumps to *that* expression's control flow, not to a JS `return` wrapped in an arrow. Same family as `return <case>` in a `#[@result]` fn, which is spec 03's E8 |
| JS-2 | a destructuring **parameter** (which takes no default), and a `case` arm with several patterns | a destructuring parameter emits no `= `; a multi-pattern arm builds a real disjunction |
| JS-3 | `val { x, ...rest } = p` — a spread that **binds a name** | the frontend records `ParamDestruct.names.hasSpread` as a `bool`; it must carry the name |
| JS-4 | `val Circle(r) = shape` / `assert x is Some(n)` — a **pattern in binding position** | a `ctor` destructuring lowers to a real JS test-plus-destructure, not to botopink's own pattern spelling |
| JS-5 | a `declare fn`'s **parameter types**, in the `.d.ts` | carry the declared parameter type from the fn decl into `typescript.zig` |
| JS-6 | a bare `throw` with no operand | decide the semantics (rethrow the caught value, or reject it in the checker) and make `Stmt.throw_` non-optional |

## Rule

Every step is one commit.

- A step that deletes a build site whose bridge is *illegal output* (JS-1, JS-2, JS-3, JS-6)
  **changes the emitted code and its RUN LOG** — that is the point, and the new snapshot must be a
  program that runs.
- JS-5 changes 14 `.d.ts` sections and no RUN LOG (a typedef is never executed), so each diff is
  reviewed as the assertion.
- A step that is only a shape concern (JS-4 once unblocked, the erlang refactors, steps 7, 9 and
  10) keeps the snapshots **byte-identical**; a diff there means a bug was found, and it moves to
  [`03-codegen-hardening.md`](./03-codegen-hardening.md).

Update `AGENTS.md` — `codegen/AGENTS.md`, `codegen/js/AGENTS.md`, `codegen/wat/AGENTS.md`,
`codegen/beam/AGENTS.md` — in the same commit as each step, deleting the bridge's row when its
last build site goes.

---

## Step 1 — JS-1 `Expr.stmt_expr`: a statement in expression position

Renders the statement with no terminator of its own (`js/js_ast.zig:88`, builder at `:686-689`,
emitter arm at `js_emitter.zig:203`, and a unit test that pins `return continue;` at
`js_emitter.zig:801`).

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
| `loop_continue_in_iteration` | `return continue;` | a | **no** |
| `range_open_ended_range` | `return return;` | a | **no** |

The last three are the argument for this step: three of the nine are invisible to every RUN LOG
comparison the suite can make.

**What to do:** a botopink `loop` used as a value is a comprehension; lower it to an expression
and lower `break <v>` / `continue` inside it to that expression's control flow. Delete the eight
`b.stmtExpr` calls, then `Expr.stmt_expr` and `Block.Layout.bare` (`js/js_ast.zig:399`, which
`js_ast.zig:398` already documents as reachable only through it; the emitter arm is
`js_emitter.zig:541`).

`throw_inside_case_arm`'s `return return` is not a JS-lowering bug on its own — it is the
`#[@result]` wrap applied to a whole `case` instead of to each non-jumping arm, which erlang
spells as `{ok, {error, …}}`. Coordinate with spec 03 E8: fix the wrap once, in the transform
pass, and both spellings go.

**Acceptance:**
- [ ] 0 `stmtExpr(` in `commonJS.zig`; `Expr.stmt_expr` and `Block.Layout.bare` deleted from
      `js/js_ast.zig`
- [ ] `node --check` passes for all nine modules above
- [ ] The 7 label-`b` snapshots carry a non-empty RUN LOG that is the value the program means
- [ ] `zig build test` green

## Step 2 — JS-2 `Expr.missing`: an expression the lowering never produced

**What it pins:** `function greet({ name, ... } = ) {`
(`destructure_record_parameter_in_fn.snap.md:22` — `commonJS.zig:1681` gives an object
destructuring *parameter* the `= ` of a destructuring assignment with nothing to assign) and
`if () return null;` twice (`case_multiple_subjects.snap.md:16-17` — `commonJS.zig:2945` emits a
`case` arm with a multi-pattern and no condition). Both are SyntaxErrors; `case_multiple_subjects`
is label `a`, so only `node --check` sees it.

**What to do:** a destructuring parameter takes no default; a multi-pattern arm builds a real
disjunction. Then audit the four remaining sites — each is either a real absence to spell out or
an unreachable case that should be an error:

| Site | What it is |
|---|---|
| `:2082` | a builtin call's second argument when the call has only one |
| `:2133` | the tail of an unhandled builtin |
| `:2227` | `try` with no operand — the JS twin of `erlang.zig:3176` |
| `:2414` | a `comptime { … }` block with no `break` value — **the same latent defect as `erlang.zig:3632`**, which is what makes `comptime_block_with_break` emit `result() -> (X * 2).`. It is unreached on commonJS only because the decl-level path folds `val result = comptime {…}` to `const result = 20;` first. Fix it here rather than waiting for a fixture |

**Acceptance:**
- [ ] 0 `Expr.missing` build sites; the variant deleted
- [ ] `destructure_record_parameter_in_fn` and `case_multiple_subjects` pass `node --check` and run

## Step 3 — JS-3 `Rest.unnamed` / `Spread.unnamed`: a rest whose name is not carried

**What it pins:** `const { x, ... } = p;`
(`destructure_record_val_binding_with_spread.snap.md:21`, label `a`) and the same `...` inside
`destructure_record_parameter_in_fn.snap.md:22`. Both are SyntaxErrors. `buildNamesPattern`
(`commonJS.zig:1694`) can only write `...` because the frontend records
`ParamDestruct.names.hasSpread` as a bool, not a name.

**What to do:** carry the spread binding's name through the AST, then fill it in at the three
build sites (1694, 1728, 2359). The emitter's `.unnamed` arms are `js_emitter.zig:251` and `:374`;
delete both variants (`js_ast.zig:204`, `:257`) with the last build site.

**Acceptance:**
- [ ] The frontend carries the name; 0 `.unnamed` build sites; both variants deleted
- [ ] Both snapshots pass `node --check` and run

## Step 4 — JS-6 `Stmt.throw_ = null`: a bare `throw`

One build site (`commonJS.zig:2224`): a botopink `throw` with no value becomes `throw;`, a JS
SyntaxError. No snapshot reaches it today, so **add one first** — a fixture that throws bare
inside a `try` — then decide the semantics (rethrow the caught value, or reject it in the checker)
and make `Stmt.throw_` non-optional. Note the erlang twin of the same absence is
`erlang.zig:3175`, which spec 03 also has to give a real node; decide the semantics once.

**Acceptance:**
- [ ] A fixture exercises bare `throw` on all four backends
- [ ] `Stmt.throw_` carries a required operand

## Step 5 — JS-4 `Pattern.match`: a botopink pattern as a JS binding target

Eight build sites (`commonJS.zig` `buildPattern`, `:1704-1743`, lines 1709, 1710, 1714, 1717,
1718, 1724, 1734, 1739), reached from `buildParam` (`:1675`) and `buildDestructPattern` (`:1745`)
— i.e. a `ctor` or `list` destructuring in parameter or `val` position. `writeMatchPattern`
(`js_emitter.zig:378`) then writes botopink's own spelling (`Circle(r)`, `1 | 2`) into JS.

No snapshot reaches it, because the surface that would (`assert x is Some(n)`,
`val Circle(r) = shape`) does not parse — it is one of the three `COMPILE DIAGNOSTIC` fixtures
spec 03 lists (`narrow_assert_pattern_with_print`). **This step is blocked on that parser gap**;
once it lands, a `ctor` destructuring must lower to a real JS test-plus-destructure, not to a
pattern spelling. The erlang side of the same gap is `destructPatternExpr`'s
`.list, .ctor => return Ast.Expr.v("_")` (`erlang.zig:2865`), which silently matches anything.

**Acceptance:**
- [ ] A fixture destructures a variant in binding position and runs
- [ ] 0 `Pattern.match` build sites; `MatchPattern` (`js_ast.zig:283`) and `writeMatchPattern`
      deleted

## Step 6 — JS-5 `TsType.missing`: a `.d.ts` parameter with no type

One build site (`typescript.zig:210`: `return if (name.len == 0) .missing else .{ .name = name };`),
and it is the most visible bridge in the tree — **14** snapshots emit an untyped parameter, e.g.
`export declare function double(x: ): i32;` (`import_multi_module_pub_fn_import.snap.md:18`),
`export declare function delete(with: , class: ): string;`
(`reserved_word_identifiers.snap.md:33`), and every `external_*` typedef. A `declare fn`'s
parameter types are not carried to the typedef backend.

The 14: `external_a2_chained_host_call_renders_verbatim`,
`external_a3_result_template_owned_declare_fn`, `external_call_emits_module_symbol`,
`external_global_math`, `external_import_binds_symbol`,
`external_target_mixed_with_external_in_one_decl`,
`external_target_template_equivalent_to_external_target_template`, `fn_max_via_if_comparison`,
`fn_pub_exported_function`, `import_cross_module_record_construct_and_assoc_fn`,
`import_multi_module_pub_fn_import`, `reserved_word_identifiers`, `star_fn_pub_typedefs`,
`std_package_order_enum_module_with_type_export`.

**What to do:** carry the declared parameter type through to `typescript.zig`. The emitted `.d.ts`
is not executed, so this step changes 14 snapshots without changing any RUN LOG — review each diff
as the assertion. `ts_emitter.zig:66` is the `.missing` arm to delete; `:266` is a unit test that
pins it and must go with it.

**Acceptance:**
- [ ] `rg -l ': \)|: ,' snapshots/codegen/commonJS/` is empty
- [ ] 0 `TsType.missing` build sites; the variant deleted

## Step 7 — wat `Module.externs`: four symbols nothing defines, on a path nothing calls

`Builder.externCall` (`wat/wat_ast.zig:564-569`) lets a module `call` a symbol it does not define
by recording it in `Module.externs` (`:268`), which `validateModule` (`:319-325`) then accepts.
Four symbols use it: `$__emit` (`wat.zig:2428`), `$__compilerError` (`:2435`), `$__binding_ref`
(`:2443`) and `$__str_concat_rt` (`:3634`).

They were defined by the `wat_runtime` prelude that `emitFnWat` (`wat.zig:130`) output was
concatenated with — and **`wat_runtime.zig` no longer exists**: it was deleted with the vendored
`wasm3` module, before this milestone. The evidence that this is a **delete-or-ship decision and
not a dangling-symbol bug**:

| Check | Result |
|---|---|
| Does anything define the four symbols? | no — `rg '__str_concat_rt\|__emit\|__compilerError\|__binding_ref' modules/` finds only these four call sites and their comments |
| Does any snapshot reach an arm? | no — `rg '__str_concat_rt\|__emit\|__compilerError\|__binding_ref' snapshots/codegen/wasm/` is empty |
| Does anything call `emitFnWat`? | **no — zero callers anywhere in `modules/`.** The 1.0.1-beta note said "no consumer outside `tests/wat.zig`"; there is no consumer at all, test included |
| Does the host it was written for still exist? | no — `wat.zig:129` says the output "runs through `wasm3_host.runWat`", and `wasm3_host` does not exist either |

**What to do:** the single-fn comptime path has no caller and no runtime, so the decision is
between shipping the definitions (only worth it if the wasm3-era comptime path is coming back —
`config.zig:22-23` and `runtime.zig:548-549` both record that it was retired) and deleting.
Recommended: delete `emitFnWat`, `renderItem`'s bare-form path (`wat/wat_emitter.zig:40`), the
four `externCall` sites, and `Module.externs` + `Builder.externs` with them, and lower those four
builtins to the honest `;; …` placeholder the rest of `wat.zig` uses. `wat_emitter.zig:352`
(`ok.externs = &.{"nope"}`) is the unit test that goes with it.

Either way, every comment that still names a file that is not there must stop:

| File | Lines |
|---|---|
| `wat.zig` | 127, 129, 138, 442, 968, 2417, 2421 |
| `wat/wat_ast.zig` | 265, 494 |
| `tests/wat.zig` | 402-403 |
| `tests/features.zig` | 927 |
| `comptime/tests/helpers.zig` | 127 |
| `codegen/AGENTS.md` | 508-514 |
| `libs/std/src/builtins.d.bp` | 272 |

(`build.zig:17`, `:95`, `config.zig:22-23` and `runtime.zig:548-549` also name `wasm3`; those are
[`05-repo-hygiene.md`](./05-repo-hygiene.md)'s, not this step's.)

**Acceptance:**
- [ ] No symbol is callable without a definition, or `Module.externs` is gone
- [ ] 0 references to `wat_runtime` or `wasm3_host` outside a changelog
- [ ] wasm snapshots byte-identical

## Step 8 — erlang `raw`: unreachable fallbacks and the pre-spelled call head

Of the 13 `Ast.Expr.r(` in `erlang.zig`, **seven** are *missing value* output bugs and belong to
[`03-codegen-hardening.md`](./03-codegen-hardening.md) step 2 (`:2308`, `:3174`, `:3175`, `:3176`,
`:3184`, `:3628`, `:3632` — `:3632` is what makes `comptime_block_with_break` emit
`result() -> (X * 2).`). This step takes the other two classes, both byte-identical:

1. **Unreachable fallbacks** — `erlang.zig:2967` (unknown `__bp_result`/`__bp_option_*` op),
   `:2977` (`opArg` with no fn argument), `:3537` (`interfaceAssocAtom` buffer overflow), `:3768`
   (empty `or` pattern) return `Ast.Expr.r("")`. Return an error (or assert) instead.
2. **Pre-spelled call head** — `headCall` (`erlang.zig:3667-3669`) wraps an already-spelled head in
   `Ast.Expr.r` at `:3668`, and has **11** callers (1758, 3448, 3476, 3498, 3509, 3529, 3538,
   3543, 3559, 3853, 3875). Replace with `.call{ .module, .name }` for a `qualified`
   (`:3662`) / `calleeAtom` / `interfaceAssocAtom` head and `.apply{ .fun = .variable }` for the
   `arenaVar` head (`:3476`); delete `qualified` if it goes unused. If a spelled external symbol
   now gets quoted by `writeAtom`, that diff is a fix → spec 03.

After both, the only `raw` left in `erlang.zig` is the host template text at `:1566`.

**Acceptance:**
- [ ] `Ast.Expr.r(` in `erlang.zig` is 1 (plus whatever spec 03 leaves), and
      `codegen/beam/AGENTS.md` documents why that one stays
- [ ] Erlang and beam snapshots byte-identical

## Step 9 — The last hand-written target text

`beam_asm.zig` writes the `.S` module preamble by hand — **9** writer calls in `emitBeamAsm` at
`:603-617` (`{module, …}.`, `{exports, [{f, N}, …]}.`, `{attributes, []}.`, `{labels, N}.`),
including its own `atomName` quoting for each export, plus the two `writeAll`s at `:615` and
`:617` that splice the already-rendered body and deferred lambdas. Everything else in the file
goes through `beam/beam_emitter.zig`.

Give the emitter `writeModuleForm` / `writeExports` / `writeAttributes` / `writeLabels` (it
already owns atom quoting via `writeAtomOperand`), and call them. Then the invariant "no backend
prints target syntax" holds with no exception but the `#[@External.Beam]` template body, whose
passthrough adapter is `:2689-2693` and `:2710` — those three stay and must be named in
`codegen/beam/AGENTS.md` as the exception.

**Related, but not this step:** the exports form this code writes is what hides two loader
rejections, because `erlc +from_asm` drops unexported functions before validating them. Spec 03
step 3 ships `scripts/beam_export_audit.sh` for that; land it before this refactor so the
byte-identical claim is checked against a fully validated tree.

**Acceptance:**
- [ ] 9 writer calls gone from `emitBeamAsm`; the 3 in the `#[@External.Beam]` passthrough remain
      and are documented
- [ ] Beam snapshots byte-identical

## Step 10 — Dead scaffolding and per-call allocation

Byte-identical cleanups left from the `Term` / `erl_ast` migration.

| What | Where | Why |
|---|---|---|
| `Body.raw_block`, `Form.attribute`, `Form.raw` | `beam/erl_ast.zig:213`, `:253`, `:260`; render arms at `beam/erl_emitter.zig:577`, `:604` (both `raw_block`), `:670` (`attribute`), `:676` (`raw`) | No producer anywhere in `compiler-core` — three ways to write verbatim text that nothing uses |
| Variable names built on `this.alloc`, then copied into `b.arena` and freed | `erlang.zig:2046` (`varRef`, 4 call sites: 1987, 2073, 2635, 3003), `:2069` (inside `bindExpr`), `:2661` (`arenaVar`, 18 call sites: 2064, 2254, 2294, 2480, 2481, 2678, 2712, 2738, 2836, 2861, 2864, 3115, 3201, 3260, 3262, 3277, 3476, 3817); `erlangVar` = `erlEmitter.varName` at `:1003` | Every variable read allocates and frees. Build the name once in `b.arena` (`Name@N` printed straight into it); drop the `erlangVar` alias if it goes unused |
| Constant number leaves `.{ .number = "0" / "1" }` | `erlang.zig:943`, `:979`, `:980`, `:1980`, `:3163`, `:3292` | `Term.int` already exists (`:3017` uses it) |
| The `$stringify(…)` wrapper written as template text | `erlang.zig:1583-1588` (`emitStringifyOpen` / `emitStringifyClose`) — the only two `writeAll` calls left in the file | It is the compiler's own `iolist_to_binary(io_lib:format("~p", [ … ]))`, not host text; build it as the `call` node `formatNode` (`:3592`) already produces, so the template `raw` at `:1566` carries host text only |

**Acceptance:**
- [ ] The three dead variants and their four render arms are gone; builds clean
- [ ] No per-variable allocation on `this.alloc` in `erlang.zig`
- [ ] 0 writer calls in `erlang.zig`
- [ ] Erlang and beam snapshots byte-identical

---

## Parallelism

Rows are cut by file and by snapshot directory. Two rows may run at the same time only when they
share neither.

| Row | Steps | Owns | May run beside |
|---|---|---|---|
| **js bridges** | 1, 2, 3, 4, 6 | `commonJS.zig`, `typescript.zig`, `js/**`, `snapshots/codegen/commonJS/` | erlang, beam, wat |
| **erlang raw** | 8, 10 | `erlang.zig`, `beam/erl_ast.zig`, `beam/erl_emitter.zig`, `snapshots/codegen/erlang/` | js, wat — **not beam** |
| **beam preamble** | 9 | `beam_asm.zig`, `beam/beam_emitter.zig`, `snapshots/codegen/beam/` | js, wat — **not erlang** |
| **wat externs** | 7 | `wat.zig`, `wat/**`, `snapshots/codegen/wasm/` | all |
| **blocked** | 5 | — | needs the `assert x is Some(n)` parser gap closed first |

Notes on the edges:

- **Steps 8 and 9 both touch `codegen/beam/`.** Step 10 deletes `Form.raw` / `raw_block` /
  `attribute` from `erl_ast.zig` and `erl_emitter.zig`; step 9 adds `writeModuleForm` and friends
  to `beam_emitter.zig`. Different files inside the same directory, but both re-record
  `snapshots/codegen/beam/` if anything drifts — sequence them, erlang first.
- **Every step here collides with its backend's row in
  [`03-codegen-hardening.md`](./03-codegen-hardening.md)**, because both edit the same backend
  file and the same snapshot directory. Steps 1–6 and spec 03's commonJS causes are one worktree;
  step 7 and spec 03's wasm causes are one worktree; and so on. Do not plan them as separate
  parallel rows.
- **Step 1 and spec 03's E8 are the same defect** seen from two backends. Whoever takes the
  `#[@result]` wrap takes both, in the transform pass, and re-records commonJS *and* erlang — so
  that work cannot run beside either backend row.
- **Step 4 and spec 03's `erlang.zig:3175`** are the same question (what a bare `throw` means).
  Answer it once before either row starts, or the two backends will disagree.
- **Step 7 is the only fully independent row.** It touches no other backend, changes no snapshot
  and has no caller to break; it is the safest thing to hand a second worker.
