# Spec 04 — Emitter Centralization

**Version:** 1.0.2-beta
**Priority:** medium
**Continues:** [`../1.0.1-beta/04-emitter-centralization.md`](../1.0.1-beta/04-emitter-centralization.md)
**Depends on:** nothing — every step is scoped to one bridge

---

## Objective

Empty the bridge inventory. Each bridge is a node the code model carries only because the
lowering still produces a shape that model would otherwise forbid; deleting its **build
sites** is the fix, and the node goes with the last one. What is left after that is the last
hand-written target text in the tree and the dead scaffolding the migration left behind.

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/codegen/`, except
`snapshots/…` (relative to `modules/compiler-core/`) and `libs/…` (relative to
`repository/botopink-lang/`).

## Current state

All four backends build a model and let an emitter render it. Writer calls
(`w.print` / `w.writeAll`) in the backends: `wat.zig` **0**, `commonJS.zig` **0**,
`typescript.zig` **0**, `erlang.zig` **0**, `beam_asm.zig` **9**. `Ast.Expr.r(` in
`erlang.zig`: **13**.

The bridges are named, so a grep finds every one:

```sh
rg 'stmtExpr\(|\.missing|\.unnamed|\.match = |throw_ = ' commonJS.zig typescript.zig
rg 'externCall\(' wat.zig
rg 'Expr\.r\(' erlang.zig
```

| Bridge | Build sites | Snapshots that show it |
|---|---|---|
| JS-1 `Expr.stmt_expr` | 8 (`commonJS.zig` 2220, 2223, 2242, 2249, 2285, 2313, 2505, 2587) | 7 |
| JS-2 `Expr.missing` | 6 (`commonJS.zig` 1681, 2082, 2133, 2227, 2414, 2945) | 2 |
| JS-3 `Rest.unnamed` / `Spread.unnamed` | 3 (`commonJS.zig` 1694, 1728, 2359) | 2 |
| JS-4 `Pattern.match` | 8 (`commonJS.zig` 1709, 1710, 1714, 1717, 1718, 1724, 1734, 1739) | 0 |
| JS-5 `TsType.missing` | 1 (`typescript.zig:210`) | 14 |
| JS-6 `Stmt.throw_ = null` | 1 (`commonJS.zig:2224`) | 0 |
| wat `Module.externs` | 4 (`wat.zig` 2428, 2435, 2443, 3630) | 0 |
| erlang `raw` — missing value | 5 (`erlang.zig` 2308, 3174, 3176, 3184, 3632) | → spec 03 |
| erlang `raw` — unreachable | 4 (`erlang.zig` 2967, 2977, 3537, 3768) | — |
| erlang `raw` — pre-spelled call head | 1 helper, 12 callers (`erlang.zig:3667`) | — |
| erlang `raw` — host template text | 1 (`erlang.zig:1566`) | stays |

## Rule

Every step is one commit.

- A step that deletes a build site whose bridge is *illegal output* (JS-1, JS-2, JS-3, JS-6)
  **changes the emitted code and its RUN LOG** — that is the point, and the new snapshot must
  be a program that runs.
- JS-5 changes 14 `.d.ts` sections and no RUN LOG (a typedef is never executed), so each diff
  is reviewed as the assertion.
- A step that is only a shape concern (JS-4 once unblocked, the erlang refactors, steps 7, 9
  and 10) keeps the snapshots **byte-identical**; a diff there means a bug was found, and it
  moves to [`03-codegen-hardening.md`](./03-codegen-hardening.md).

Update `AGENTS.md` — `codegen/AGENTS.md`, `codegen/js/AGENTS.md`, `codegen/wat/AGENTS.md`,
`codegen/beam/AGENTS.md` — in the same commit as each step, deleting the bridge's row when
its last build site goes.

---

## Step 1 — JS-1 `Expr.stmt_expr`: a statement in expression position

Renders the statement with no terminator of its own (`js/js_ast.zig:88`, builder at
`:686-689`, emitter at `js_emitter.zig:203`).

**What it pins:** `const dobrados = for (const id of ids) { … };`
(`snapshots/codegen/commonJS/loop_map_with_break_simple.snap.md:16`),
`return return x;` (`loop_break_with_value.snap.md:17`), `return continue;`
(`loop_continue_in_iteration.snap.md:15`), plus `loop_even_numbers_with_break.snap.md:15-16`,
`loop_filter_with_conditional_break.snap.md:18-19`, `loop_map_with_break_add_tax.snap.md:17`,
`throw_inside_case_arm.snap.md:28`. All seven are JS SyntaxErrors — every one of these
snapshots has an empty RUN LOG.

**What to do:** a botopink `loop` used as a value is a comprehension; lower it to an
expression (an accumulating IIFE, or `.map`/`.filter` where the shape allows), and lower
`break <v>` / `continue` inside it to that expression's control flow rather than to a JS
`return` wrapped in an arrow. Delete the eight `b.stmtExpr` calls, then `Expr.stmt_expr` and
`Block.Layout.bare` (reachable only through it).

**Acceptance:**
- [ ] 0 `stmtExpr(` in `commonJS.zig`; `Expr.stmt_expr` deleted from `js/js_ast.zig`
- [ ] The 7 snapshots above carry a non-empty RUN LOG that matches the erlang backend
- [ ] `zig build test` green

## Step 2 — JS-2 `Expr.missing`: an expression the lowering never produced

**What it pins:** `function greet({ name, ... } = ) {`
(`destructure_record_parameter_in_fn.snap.md:22` — `commonJS.zig:1681` gives an object
destructuring *parameter* the `= ` of a destructuring assignment with nothing to assign) and
`if () return null;` twice (`case_multiple_subjects.snap.md:16-17` — `commonJS.zig:2945`
emits a `case` arm with a multi-pattern and no condition). Both are SyntaxErrors.

**What to do:** a destructuring parameter takes no default; a multi-pattern arm builds a real
disjunction. Then audit the four remaining sites (2082, 2133, 2227, 2414) — each is either a
real absence to spell out or an unreachable case that should be an error.

**Acceptance:**
- [ ] 0 `Expr.missing` build sites; the variant deleted
- [ ] `destructure_record_parameter_in_fn` and `case_multiple_subjects` run

## Step 3 — JS-3 `Rest.unnamed` / `Spread.unnamed`: a rest whose name is not carried

**What it pins:** `const { x, ... } = p;`
(`destructure_record_val_binding_with_spread.snap.md:21`) and the same `...` inside
`destructure_record_parameter_in_fn.snap.md:22`. `buildNamesPattern`
(`commonJS.zig:1694`) can only write `...` because the frontend records
`ParamDestruct.names.hasSpread` as a bool, not a name.

**What to do:** carry the spread binding's name through the AST, then fill it in at the three
build sites (1694, 1728, 2359).

**Acceptance:**
- [ ] The frontend carries the name; 0 `.unnamed` build sites; both variants deleted
- [ ] Both snapshots run

## Step 4 — JS-6 `Stmt.throw_ = null`: a bare `throw`

One build site (`commonJS.zig:2224`): a botopink `throw` with no value becomes `throw;`,
which is a JS SyntaxError. No snapshot reaches it today, so **add one first** — a fixture
that throws bare inside a `try` — then decide the semantics (rethrow the caught value, or
reject it in the checker) and make `Stmt.throw_` non-optional.

**Acceptance:**
- [ ] A fixture exercises bare `throw` on all four backends
- [ ] `Stmt.throw_` carries a required operand

## Step 5 — JS-4 `Pattern.match`: a botopink pattern as a JS binding target

Eight build sites (`commonJS.zig` `buildPattern`, 1709-1739), reached from `buildParam`
(`:1683-1684`) and `buildDestructPattern` (`:1749-1750`) — i.e. a `ctor` or `list`
destructuring in parameter or `val` position. `writeMatchPattern`
(`js_emitter.zig:378-410`) then writes botopink's own spelling (`Circle(r)`, `1 | 2`) into
JS.

No snapshot reaches it, because the surface that would (`assert x is Some(n)`,
`val Circle(r) = shape`) does not parse — it is one of the three `COMPILE DIAGNOSTIC`
fixtures spec 03 lists. **This step is blocked on that parser gap**; once it lands, a `ctor`
destructuring must lower to a real JS test-plus-destructure, not to a pattern spelling.

**Acceptance:**
- [ ] A fixture destructures a variant in binding position and runs
- [ ] 0 `Pattern.match` build sites; `MatchPattern` and `writeMatchPattern` deleted

## Step 6 — JS-5 `TsType.missing`: a `.d.ts` parameter with no type

One build site (`typescript.zig:210`: `if (name.len == 0) .missing`), and it is the most
visible bridge in the tree — **14** snapshots emit an untyped parameter, e.g.
`export declare function double(x: ): i32;`
(`import_multi_module_pub_fn_import.snap.md:18`),
`export declare function delete(with: , class: ): string;`
(`reserved_word_identifiers.snap.md:33`), and every `external_*` typedef. A `declare fn`'s
parameter types are not carried to the typedef backend.

**What to do:** carry the declared parameter type through to `typescript.zig`. The emitted
`.d.ts` is not executed, so this step changes 14 snapshots without changing any RUN LOG —
review each diff as the assertion.

**Acceptance:**
- [ ] No `.d.ts` in `snapshots/codegen/commonJS/` contains `: )` or `: ,`
- [ ] 0 `TsType.missing` build sites; the variant deleted

## Step 7 — wat `Module.externs`: four symbols nothing defines

`Builder.externCall` (`wat/wat_ast.zig:565`) lets a module `call` a symbol it does not define
by recording it in `Module.externs` (`:268`), which `validateModule` (`:319-325`) then
accepts. Four symbols use it: `$__emit` (`wat.zig:2428`), `$__compilerError` (`:2435`),
`$__binding_ref` (`:2443`) and `$__str_concat_rt` (`:3630`).

They were defined by the `wat_runtime` prelude that `emitFnWat` (`wat.zig:130`) output was
concatenated with — and **`wat_runtime.zig` no longer exists**: it was deleted with the
vendored wasm3 module, before this milestone. Nothing in the repository defines any of the
four, `emitFnWat` has no consumer outside `tests/wat.zig`, and no snapshot reaches any of the
arms (`rg '__str_concat_rt|__emit|__compilerError|__binding_ref' snapshots/codegen/wasm/`
is empty).

**What to do:** decide whether the single-fn comptime path still exists. If it does, ship the
definitions; if it does not, delete `emitFnWat`, `renderItem`'s bare-form path, the four
`externCall` sites and `Module.externs` + `Builder.externs` with them, and lower those
builtins to the honest `;; …` placeholder the rest of `wat.zig` uses. Either way, the eight
comment sites that still name `wat_runtime` (`wat.zig` 127, 138, 442, 968, 2417;
`wat/wat_ast.zig` 265, 494; `tests/wat.zig:403`; plus `codegen/AGENTS.md` and
`libs/std/src/builtins.d.bp:272`) must stop referring to a file that is not there.

**Acceptance:**
- [ ] No symbol is callable without a definition, or `Module.externs` is gone
- [ ] 0 references to `wat_runtime` outside a changelog

## Step 8 — erlang `raw`: unreachable fallbacks and the pre-spelled call head

The five *missing value* sites (`erlang.zig` 2308, 3174, 3176, 3184, 3632) are output bugs
and belong to [`03-codegen-hardening.md`](./03-codegen-hardening.md) — `:3632` is what makes
`comptime_block_with_break` emit `result() -> (X * 2).`. This step takes the other two
classes, both byte-identical:

1. **Unreachable fallbacks** — `erlang.zig:2967` (unknown `__bp_result`/`__bp_option_*` op),
   `:2977` (`opArg` with no fn argument), `:3537` (`interfaceAssocAtom` buffer overflow),
   `:3768` (empty `or` pattern) return `Ast.Expr.r("")`. Return an error (or assert) instead.
2. **Pre-spelled call head** — `headCall` (`:3667`) wraps an already-spelled head in
   `Ast.Expr.r`, and has 12 callers (1758, 3448, 3476, 3498, 3509, 3529, 3538, 3543, 3559,
   3853, 3875). Replace with `.call{ .module, .name }` for a `qualified` /
   `calleeAtom` / `interfaceAssocAtom` head and `.apply{ .fun = .variable }` for the
   `arenaVar` head (`:3476`); delete `qualified` if it goes unused. If a spelled external
   symbol now gets quoted by `writeAtom`, that diff is a fix → spec 03.

After both, the only `raw` left in `erlang.zig` is the host template text at `:1566`.

**Acceptance:**
- [ ] `Ast.Expr.r(` in `erlang.zig` is 1 (plus whatever spec 03 leaves), and
      `codegen/beam/AGENTS.md` documents why that one stays
- [ ] Erlang and beam snapshots byte-identical

## Step 9 — The last hand-written target text

`beam_asm.zig` writes the `.S` module preamble by hand — 9 writer calls in `emitBeamAsm` at `:603-617`
(`{module, …}.`, `{exports, [{f, N}, …]}.`, `{attributes, []}.`, `{labels, N}.`), including
its own `atomName` quoting for each export. Everything else in the file goes through
`beam/beam_emitter.zig`.

Give the emitter `writeModuleForm` / `writeExports` / `writeAttributes` / `writeLabels` (it
already owns atom quoting via `writeAtomOperand`), and call them. Then the invariant
"no backend prints target syntax" holds with no exception but the `#[@External.Beam]`
template body.

**Acceptance:**
- [ ] 0 writer calls in `beam_asm.zig`
- [ ] Beam snapshots byte-identical

## Step 10 — Dead scaffolding and per-call allocation

Byte-identical cleanups left from the `Term` / `erl_ast` migration.

| What | Where | Why |
|---|---|---|
| `Body.raw_block`, `Form.raw`, `Form.attribute` | `beam/erl_ast.zig:213`, `:260`, `:253`; render arms at `beam/erl_emitter.zig:577`, `:604`, `:670`, `:676` | No producer anywhere in `compiler-core` — three ways to write verbatim text that nothing uses |
| Variable names built on `this.alloc`, then copied into `b.arena` and freed | `erlang.zig:2046` (`varRef`), `:2060` (`bindExpr`), `:2661` (`arenaVar`), fanned out to 20 `arenaVar` and 3 `varRef` callers; `erlangVar` = `erlEmitter.varName` at `:1003` | Every variable read allocates and frees. Build the name once in `b.arena` (`Name@N` printed straight into it); drop the `erlangVar` alias if it goes unused |
| Constant number leaves `.{ .number = "0" / "1" }` | `erlang.zig:943`, `:979`, `:980`, `:1980`, `:3163`, `:3292` | `Term.int` already exists (`:3017` uses it) |
| The `$stringify(…)` wrapper written as template text | `erlang.zig:1583-1588` (`emitStringifyOpen` / `emitStringifyClose`) | It is the compiler's own `iolist_to_binary(io_lib:format("~p", [ … ]))`, not host text; build it as the `call` node `formatNode` (`:3592`) already produces, so the template `raw` carries host text only |

**Acceptance:**
- [ ] The three dead variants and their render arms are gone; builds clean
- [ ] No per-variable allocation on `this.alloc` in `erlang.zig`
- [ ] Erlang and beam snapshots byte-identical
