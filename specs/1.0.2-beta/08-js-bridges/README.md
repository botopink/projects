# Front 08 — js-bridges

**Priority:** high — 12 commonJS snapshots pin JavaScript that does not parse, 4 of them invisible to
every RUN LOG, and three one-site lowering bugs print `undefined`/`NaN` in 10 more
**Depends on:** [`../03-std-surface/README.md`](../03-std-surface/README.md) — it runs alone and
re-records this front's snapshot directory (C1 is its row). Step 7 (JS-4) is blocked on the
`assert x is Some(n)` parser gap in [`../07-checker/README.md`](../07-checker/README.md)
**Owns:** `src/codegen/commonJS.zig`, `src/codegen/typescript.zig`, `src/codegen/js/**` ·
`snapshots/codegen/commonJS/` (279)
**Does not touch:** `src/codegen/erlang.zig`, `src/codegen/beam_asm.zig`, `src/codegen/wat.zig` ·
`libs/std/**` ([`../03-std-surface/`](../03-std-surface/README.md)) · `src/comptime/transform.zig`
(the `#[@result]` wrap) and `src/parser/**` ([`../07-checker/`](../07-checker/README.md)) ·
`src/codegen/runtime.zig` **without agreeing ownership first** — the `node --check` gate needs it and
no front in [`../fronts.md`](../fronts.md#ownership) owns it

Paths are relative to `repository/botopink-lang/modules/compiler-core/`, except those starting with
`libs/`, which are relative to `repository/botopink-lang/`. Every `file:line` is at HEAD.

---

## Problem

Twelve emitted commonJS modules are not JavaScript. `node --check` on them:

```
loop_continue_in_iteration/main.js
    (() => { if (((x % 2) !== 0)) { return continue; } })();
                                           ^^^^^^^^
SyntaxError: Unexpected token 'continue'

destructure_record_parameter_in_fn/main.js
function greet({ name, ... } = ) {
                           ^
SyntaxError: Unexpected token '}'

throw_inside_case_arm/main.js
        if (_s === "Fail") return return ({ error: "failed" });
                                  ^^^^^^
SyntaxError: Unexpected token 'return'
```

The harness records an unparseable module the same way it records a program that printed nothing —
an empty RUN LOG — and 4 of the 12 are label `a`, so no RUN LOG could show them anyway. Beside them,
modules that do parse print `undefined` where the program prints a length:

```
fn main() { val s = "hi " + "there"; @print(s.len); }    // string_concat_of_two_literals
→ console.log(s.len);                                    // node main.js prints: undefined
```

## Current state

Measured by extracting every `JAVASCRIPT` block under `snapshots/codegen/commonJS/`, running
`node --check` on each module, then `node main.js`; cross-backend agreement is compared under the
representation mapping recorded in [`causes.md`](./causes.md#how-the-numbers-were-measured).

| Measure | Value |
|---|---|
| snapshots | 279 |
| comparable `b` fixtures | 128 |
| reproduce erlang | 96 |
| abort | 15 |
| run and print something else | 17 — of which 6 are erlang's defect and 1 (`if_simple_conditional_in_fn_body`) a language question |
| real commonJS wrong values | 10 |
| modules `node --check` rejects | **12** (8 `b`, 4 `a`) |
| coverage (`scripts/snap_audit.sh --mode=coverage`) | a/empty 145 · a/nonempty 1 · b/missing 3 · b/empty 18 · b/nonempty 110 · c/empty 2 |

Five causes cover the 25 (15 aborts + 10 wrong values), ranked in [`causes.md`](./causes.md):

| # | Closes | What | Here? |
|---|---|---|---|
| C1 | 9 | `./gleam_stdlib.mjs` does not exist | no — [`../03-std-surface/node-externals.md`](../03-std-surface/node-externals.md) |
| C2 | 8 (6 visible) | the bridges: output that does not parse | yes — [`bridges.md`](./bridges.md) |
| C3 | 7 | `.len` read as a property | yes |
| C4 | 2 | variant payload destructured by the binding name | yes |
| C5 | 1 | `@Result` arm tests `.tag` on `{ ok }`/`{ error }` | yes |

The six bridges, with build sites and what each pins:

| Bridge | Build sites | Snapshots pinned | Illegal output |
|---|---|---|---|
| JS-1 `Expr.stmt_expr` | 8 | 9 | 9 |
| JS-2 `Expr.missing` | 6 | 2 | 2 |
| JS-3 `Rest.unnamed` / `Spread.unnamed` | 3 | 2 | 2 |
| JS-4 `Pattern.match` | 8 | 0 | — (blocked) |
| JS-5 `TsType.missing` | 1 | 14 | 0 — a `.d.ts` is never executed |
| JS-6 `Stmt.throw_ = null` | 1 | 0 | — |

## Mechanism

A bridge is a node the JS model carries only because the lowering produces a shape the model would
otherwise forbid; each is a *language* shape the lowering has no expression form for (a `loop` as a
value, a destructuring parameter, a bare `throw`). The build sites, the snapshot lines they pin and
what each lowering must learn are in [`bridges.md`](./bridges.md).

Two of the six are narrower than the 1.0.1-beta analysis recorded, and both fixes are local to this
front's files:

- **JS-3** is `{ x, .. }` — *ignore the rest*, not a named rest. The parser has no named form for a
  record rest (`src/ast.zig:984` `hasSpread: bool`), and JS destructuring already ignores unlisted
  keys, so an unnamed rest emits nothing.
- **JS-5** is not limited to `declare fn`: `pub fn max(a: i32, b: i32)` emits `max(a: , b: )`. The
  parser builds a plain parameter with `typeRef` only (`src/parser/decls.zig:1352`), and
  `src/codegen/typescript.zig:195` / `:181` read the legacy `Param.typeName`, whose default is `""`
  (`src/ast.zig:1022`).

The three lowering bugs are single sites in `src/codegen/commonJS.zig`: `:2171` (C3, no `len` case in
the `identAccess` arm), `:2957` (C4, `props[bi] = .{ .key = bb }` with the binding as the key) and
`:2967` (C5, the `.tag === "<Variant>"` arm test).

## Steps

Every step is one commit and updates `src/codegen/js/AGENTS.md` (the bridge table at `:60-70`) and
`src/codegen/AGENTS.md` in the same commit, deleting a bridge's row when its last build site goes.

### Step 1 — record an unparseable module as a visible block

Add `node --check` to `executeJavaScript` (`src/codegen/runtime.zig:263`): a module that fails it is
recorded as a `COMPILE ERROR (node --check):` block, mirroring `COMPILE ERROR (erlc):`
(`compileFailureLog`, `src/codegen/runtime.zig:128`). It costs nothing and would have caught all 12,
including the 4 label-`a` ones no RUN LOG can show. Do it first: it makes every later step's result
legible.

**Ownership:** `src/codegen/runtime.zig` is owned by no front, and the wasm front's
`RUNTIME TRAP (wasmtime):` block goes in the same file ([`../06-wasm/README.md`](../06-wasm/README.md)
step 1). **Stop and report** to agree the owner before editing it. The runtime cache key includes
`HARNESS_VERSION` (`src/codegen/runtime.zig:175`); bump it with this change.

**Acceptance:**
- [ ] `node --check` runs on every emitted module, and a failure records
      `COMPILE ERROR (node --check):` plus the message, never an empty log
- [ ] All 12 modules listed in [`bridges.md`](./bridges.md#how-illegal-output-was-measured) record
      the block until their bridge goes

### Step 2 — C3, C4, C5: the three lowering bugs

- **C3** — map `.len` to `.length` on a string / array receiver at the `identAccess` arm
  (`src/codegen/commonJS.zig:2168-2171`).
- **C4** — at `:2957`, key each prop by the declared field and bind it to the pattern's name
  (`const { radius: r } = _s;`), in declared field order.
- **C5** — at `:2967`, test a `@Result` arm against the `ok` / `error` keys, as the `try`/`catch`
  lowering already does (`"error" in _r`, `:2014`). C4 and C5 edit the same `.variant` arm: one
  commit.

**Acceptance:**
- [ ] The 7 C3, 2 C4 and 1 C5 fixtures in [`causes.md`](./causes.md) print the value the program
      means, cross-checked against the program rather than against erlang
- [ ] No commonJS RUN LOG records `undefined` / `NaN` except where the program really prints a
      none/null value (`optional_fn_return_null_path`,
      `array_at_lowers_byte_identically_across_backends`)

### Step 3 — JS-1: a `loop` used as a value

Lower a value-position `loop` to an expression (an accumulating IIFE, or `.map`/`.filter` where the
shape allows) and the jumps inside it to that expression's control flow. Delete the eight
`b.stmtExpr` calls, `Expr.stmt_expr` (`src/codegen/js/js_ast.zig:88`), `Block.Layout.bare` (`:399`),
their emitter arms (`src/codegen/js/js_emitter.zig:203`, `:541`) and the unit test at `:801`.

**Sequence:** `throw_inside_case_arm`'s `return return` is the `#[@result]` wrap applied to a whole
`case`, the same defect as erlang's E8, and it lives in the transform pass. Agree who takes the wrap
before this step; that commit re-records commonJS *and* erlang.

**Acceptance:**
- [ ] 0 `stmtExpr(` in `src/codegen/commonJS.zig`; `Expr.stmt_expr` and `Block.Layout.bare` deleted
- [ ] `node --check` passes for all nine JS-1 modules
- [ ] The 7 label-`b` snapshots carry a non-empty RUN LOG that is the value the program means
      (`loop_break_with_value`'s value only once the checker settles `fn find(arr) -> i32`
      returning a list)
- [ ] `loop_continue_in_iteration` drops odd elements rather than mapping them to `undefined`

### Step 4 — JS-2 and JS-3: the destructuring shapes

- **JS-2** — a destructuring parameter emits no `= ` (`src/codegen/commonJS.zig:1681`); a
  multi-subject `case` arm builds the conjunction of its per-subject tests and an arm with no test
  drops its `if` (`:2945`, as `:2936` and `:2943` already do). Then audit `:2082`, `:2133`,
  `:2227`, `:2414` — `:2414` is the commonJS twin of erlang's E5 and is fixed here, not left latent.
- **JS-3** — an unnamed `..` emits no rest element (`:1694`, `:1728`); decide whether `:2359` (a
  nameless spread in an array *literal*) is reachable and make it an error if not. Delete
  `Rest.unnamed` / `Spread.unnamed` (`src/codegen/js/js_ast.zig:257`, `:204`) and their emitter arms
  (`src/codegen/js/js_emitter.zig:374`, `:251`).

**Acceptance:**
- [ ] 0 `Expr.missing` build sites; the variant deleted
- [ ] 0 `.unnamed` build sites; both variants deleted
- [ ] `destructure_record_parameter_in_fn`, `case_multiple_subjects` and
      `destructure_record_val_binding_with_spread` pass `node --check` and run

### Step 5 — JS-6: a bare `throw`

No snapshot reaches `src/codegen/commonJS.zig:2224` today. **Add a fixture first** — a bare `throw`
inside a `try` — then decide the semantics (rethrow the caught value, or reject it in the checker)
and make `Stmt.throw_` non-optional. The erlang twin is `src/codegen/erlang.zig:3175`; decide once,
with the erlang front, before either changes.

**Acceptance:**
- [ ] A fixture exercises bare `throw` on all four backends
- [ ] `Stmt.throw_` carries a required operand
- [ ] The decision is written into `src/codegen/AGENTS.md`

### Step 6 — JS-5: typed parameters in the `.d.ts`

Build each parameter's type with `typeRef(p.typeRef)` (`src/codegen/typescript.zig:259`) instead of
`namedType(p.typeName)` at `:181` and `:195`. Delete `TsType.missing`, its arm
(`src/codegen/js/ts_emitter.zig:66`) and the unit test that pins it (`:266`). 14 snapshots change and
no RUN LOG does — review each diff as the assertion.

**Acceptance:**
- [ ] `rg -l ': \)|: ,' snapshots/codegen/commonJS/` is empty
- [ ] 0 `TsType.missing` build sites; the variant deleted

### Step 7 — JS-4: a pattern in binding position (blocked)

Blocked until `narrow_assert_pattern_with_print` (`assert x is Some(n)`, `val Circle(r) = shape`)
parses — [`../07-checker/README.md`](../07-checker/README.md)'s parser-gap step. Then a `ctor`
destructuring lowers to a real JS test-plus-destructure; delete the eight `Pattern.match` build sites
in `buildPattern` (`src/codegen/commonJS.zig:1704-1743`), `MatchPattern`
(`src/codegen/js/js_ast.zig:283`) and `writeMatchPattern` (`src/codegen/js/js_emitter.zig:378`).

**Acceptance:**
- [ ] A fixture destructures a variant in binding position and runs
- [ ] 0 `Pattern.match` build sites; `MatchPattern` and `writeMatchPattern` deleted
- [ ] commonJS snapshots otherwise byte-identical

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] `node --check` passes for every module under `snapshots/codegen/commonJS/`, or the failure is
      recorded as a `COMPILE ERROR (node --check):` block
- [ ] commonJS `b/empty` ≤ the count still explained by an open bridge
- [ ] 0 build sites for JS-1, JS-2, JS-3, JS-5, JS-6; JS-4's are gone or its blocker is named in
      `src/codegen/js/AGENTS.md`
- [ ] `src/codegen/AGENTS.md` and `src/codegen/js/AGENTS.md` updated in the same commit as each step
- [ ] Commit on `fix/js-bridges`; no push, no merge — landing is the maintainer's step

## Blast radius

- `snapshots/codegen/commonJS/` only, except where a step says otherwise.
- **Step 1 changes 12 RUN LOGs** from empty to a `COMPILE ERROR (node --check):` block, and every
  later bridge step changes them again to a real value. If step 1 lands in the harness, the wasm
  front's runtime change collides with it in `src/codegen/runtime.zig`.
- **Steps 3 and 4 change emitted code and RUN LOGs** — that is the point; each new snapshot must be a
  program that runs.
- **Step 6 changes 14 `.d.ts` sections** and no RUN LOG.
- **The `#[@result]` wrap** (JS-1's `throw_inside_case_arm`, erlang's E8) re-records commonJS and
  erlang together; it cannot run beside this front or the erlang front.
- **Step 7** must land byte-identical apart from its new fixture; a diff is a bug found, not a
  re-record.

## Notes

- **Erlang is not the oracle.** Six commonJS fixtures differ from erlang because erlang is wrong
  (listed in [`causes.md`](./causes.md#the-six-where-erlang-is-wrong-and-commonjs-is-right)); do not
  re-record commonJS to match.
- **`if_simple_conditional_in_fn_body` is not this front's** — the value of a value-less `if` is the
  checker front's question. Do not re-record it.
- **Two items are routed here from the std-surface front**
  ([`../03-std-surface/README.md`](../03-std-surface/README.md) § Ownership): the on-demand JS helper
  mechanism under `src/codegen/js/**` that replaces `./gleam_stdlib.mjs` where no native method
  matches (step 2, helper half — copy `src/codegen/wat/wat_prelude.zig`'s request-and-mark shape),
  and the import emitter that turns a template-form `@External.Node` into
  `const { (process.argv.slice(2)): args } = require("");` (step 3, 6d). Neither is a step here yet;
  schedule them with that front, which cannot run `env`/`os`/`process`/`random` tests until the
  second lands.
- **`./stdlib.mjs`** named by `external_import_binds_symbol` is a phantom companion of the same
  family as C1, in a fixture rather than in std source — the std-surface front leaves it to this one.
- **Corrections to the 1.0.1-beta analysis** (JS-2's disjunction, JS-3's "named rest", JS-5's
  `declare fn` scope) are recorded with their evidence in [`bridges.md`](./bridges.md).
