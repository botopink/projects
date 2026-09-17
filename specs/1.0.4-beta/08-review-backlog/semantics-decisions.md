# Cross-backend semantics — the four decisions (decided)

> **Status: decided 2026-09-16 — this file is now the reference, not an open question.** Every
> recommendation below was accepted. The analysis is kept because the implementing fronts cite its
> per-backend sites. Line numbers were measured at the 1.0.2-beta commit; re-locate by symbol.

Four language questions the 1.0.1-beta review could not grade, because the four backends disagree
and nothing in the tree says which is right. Each shows up in the reports as an `uncertain` row, or
as a `wrong-output` row that cannot be fixed without first picking an answer. **Fixing a blocked row
before its question is answered records the wrong answer in a snapshot.**

For each: what every backend does today with the deciding `file:line`, the snapshot that shows it,
the options, the recommendation, and what depends on the answer. The decision is written into the
language reference or `src/codegen/AGENTS.md`; the lowering that implements it belongs to the front
that owns the file (see [README § Blast radius](./README.md#blast-radius)).

Paths are relative to `repository/botopink-lang/modules/compiler-core/`. Line numbers were
re-checked at `botopink-lang` HEAD on 2026-09-16; re-locate by the quoted symbol if they drift.
Report citations (`codegen-features.md:85`) are lines in
[`../../1.0.1-beta/06-snapshot-review/`](../../1.0.1-beta/06-snapshot-review/).

Only **7 of the 14 `uncertain` rows** in the corpus map to these four questions (2 to decision 1,
4 to decision 2, 1 to decision 4). The other 7 are separate questions, listed in
[`backlog.md`](./backlog.md#the-7-uncertain-rows-no-decision-answers) so they are not lost when this
file closes.

| # | Question | Recommendation | `uncertain` rows it answers |
|---|---|---|---|
| [1](#decision-1) | The text `@print` produces | C — a runtime-dispatching `__bp_print/1` helper on the erlang family | 2 |
| [2](#decision-2) | The value of a block, and of a fn body's tail expression | B — a block is a statement; its value comes from `break`; the checker rejects the rest | 4 |
| [3](#decision-3) | The representation of `null` | C — box optionals on wasm; `0` stays null (beam half already closed) | 0 (two stale rows struck) |
| [4](#decision-4) | The severity of `assert` outside test mode | A — always fatal, with message and location, on every backend | 1 |
| [1a](#decision-1a) | The text `@print` produces for arrays and tuples | `[a,b]` and `#(a,b)`, a nested string quoted — on every backend | 0 (from WR4) |
| [5](#decision-5) | The markers of an `#[@External…]` template | only positional `$0`, `$1`, … over the declared parameters, `self` included; `$self` is removed | 0 (fronts.md unowned item; replaces rule T8) |

**Decided 2026-09-16 by the maintainer: every recommendation is accepted.** 1 → C (`__bp_print/1`
helper on erlang and beam), 2 → B (a block is a statement; its value comes from `break`), 3 → C (box
`?T` on wasm, `0` is null), 4 → A (`assert` is always fatal, with message and `file:line`). The
owning fronts implement them. Rows blocked on these decisions are unblocked.

<a id="implementation-status"></a>

### Implementation status

Verified at `botopink-lang` `origin/feat` = `ed15323` (2026-09-17), after the four backend fronts
landed (beam `a743955`, erlang `42429dc`, wasm `ed15323`, js-bridges `bd7836c`).

| # | commonJS | erlang | beam | wasm | Left |
|---|---|---|---|---|---|
| 1 | implemented | implemented — `__bp_print/1`, typed and comptime path | implemented — `__bp_print/1` | implemented — `$__print_*` executes under `wasmtime run` | the numeric divergence is written in `src/codegen/AGENTS.md`; the text of arrays and tuples is [decision 1a](#decision-1a), implemented by [`01-backend-residuals`](../01-backend-residuals/README.md) step 4 |
| 2 | — | — | — | — | **waits on the checker**: [`06-checker`](../06-checker/README.md#step-0--rows-added-in-104-beta) N6; the dead block-as-value lowerings follow it |
| 3 | n/a (`null`) | n/a (`undefined`) | n/a (`undefined`) | implemented — boxed `?T`, `0` = null; the four-backend table is in `src/codegen/AGENTS.md` | — |
| 4 | implemented | implemented | implemented — `{bp_assert, Msg, Loc}` | implemented — stderr message, then a trap | — |

---

<a id="decision-1"></a>

## Decision 1 — the text `@print` produces

### Today

| Backend | Lowering | Deciding site | `@print("hi")` prints |
|---|---|---|---|
| commonJS | `console.log($args)` | `src/codegen/commonJS.zig:917-918` (`putInlineBuiltinTemplate("print", …)` / `"println"`) | `hi` |
| erlang | `io:format("~p~n", [$args])` | `src/codegen/erlang.zig:1453-1455` (`putInlineErlangBuiltinTemplate` for `print`/`println`/`debug`) | `<<"hi">>` |
| beam | the same `~p~n` through `io:format/2` | `src/codegen/beam_asm.zig:3352-3359` (1 arg), `:3316-3350` (2…16 args) | `<<"hi">>` |
| wasm | `$__print_str` / `$__print_i32` / `$__print_bool` / `$__print_f64` (and `_raw` variants) over `fd_write` | the helper set is named at `src/codegen/wat/wat_ast.zig:405-415` and defined in `src/codegen/wat/wat_prelude.zig` | unobservable — `executeWat` (`src/codegen/runtime.zig:547-558`) returns `""` |

Both erlang backends widen a single control sequence to one per argument
(`src/codegen/erlang.zig:1500-1509` `widenFormatTemplate`; `src/codegen/beam_asm.zig:3336-3347`
builds `"~p ~p …~n"`), so arity is already handled — the divergence is purely the `~p` verb.

Four tests are named *"lowers byte-identically across backends"*. Their RUN LOGs at HEAD (first
line; `array_at` and `array_indexof` print a second line, `undefined` and `-1`, identically on the
three executing backends):

| Slug | node | erlang | beam | wasm |
|---|---|---|---|---|
| `array_at_lowers_byte_identically_across_backends` | `10` | `10` | `10` | empty |
| `array_indexof_lowers_byte_identically_across_backends` | `2` | `2` | `2` | empty |
| `array_join_lowers_byte_identically_across_backends` | `10, 20, 30` | `<<"10, 20, 30">>` | `<<"10, 20, 30">>` | empty |
| `array_slice_2_arg_lowers_byte_identically_across_backends` | **empty** | `[2,3,4]` | `[2,3,4]` | empty |

Integers already agree. Only the **string** case diverges — and `array_slice_2_arg`'s empty node log
is a different defect entirely (`String.prototype.slice` is patched to a
`require("./gleam_stdlib.mjs")` that throws; owned by
`std-surface` (1.0.2-beta, landed)).

The per-backend fronts compared RUN LOGs under a **representation mapping** that undoes `~p`
(`<<"x">>` → `x`, `1.0` → `1`, `[ 2, 4 ]` → `[2,4]`; see
[`../01-backend-residuals/measurement.md`](../01-backend-residuals/measurement.md#representation-mapping)).
That mapping is the workaround this decision removes for strings.

### Options

| | What it means | Cost |
|---|---|---|
| A | Keep `~p`. State that textual equality across backends is not a goal; rename the four tests to say "same lowering", not "byte-identical output" | Cheapest. Leaves `@print` of a string unreadable on two backends |
| B | Type-directed: emit `~ts` when the argument's inferred type is `string`, `~p` otherwise | Needs the type at the call site. The typed erlang path has it; **the untyped comptime path does not** (`src/codegen/erlang.zig:383-388` exists precisely because inference never ran over those bodies), so comptime `@print` would still diverge |
| C | A synthesised `__bp_print/1` helper that dispatches at runtime: `is_binary(X) -> io:format("~ts~n",[X]); _ -> io:format("~p~n",[X])` | One helper per erlang-family backend. Works on the typed **and** the untyped path. There is a precedent of exactly this shape: `__bp_text/1` (`src/codegen/erlang.zig:425-432`), a binary-first guarded clause chain; and beam already synthesises helpers on demand |

### Recommendation: C

It is the only option that makes the untyped comptime path agree too, and the pattern is already in
the tree. Two things must be written down alongside it:

- **Numeric formatting stays divergent.** `~p` of `1.0` is `1.0`; `console.log(1.0)` is `1`. That is
  `codegen-values-dispatch-externals.md:167` (`external_global_math`), already graded
  `ok (divergence noted)` — keep it graded that way and say so in `src/codegen/AGENTS.md`.
- Once `executeWat` exists, wasm's `$__print_*` family must match the same rule. (It executes since
  1.0.4-beta wasm, and does — [implementation status](#implementation-status).)

A multi-argument `@print` needs the same answer per argument: the widened `"~p ~p …~n"` forms
(`erlang.zig:1500-1509`, `beam_asm.zig:3316-3350`) either call the helper per argument or build the
format string from the helper's per-term verb.

### What depends on it

- `codegen-features.md:85` (**S16**) and `:217` (`array_join_lowers_byte_identically_across_backends`)
  — the two `uncertain` rows in this class. They are the same fixture: S16 is the root-cause index
  row and `:217` its per-slug row.
- Every row in reports 3.1 (`codegen-features.md`) and 3.5 (`codegen-builtins-aggregates.md`) that
  compares `@print` text across backends; the matrix under
  `codegen-builtins-aggregates.md` `## \`@print\` formatting consistency across backends` (`:150`,
  table at `:159`, no verdict column — its line citations predate the fix waves).
- [`../06-checker/README.md`](../06-checker/README.md) step 8 (narrowing, B7): its "identical RUN
  LOG" acceptance is blocked on this decision.
- The representation mapping the beam, erlang and wasm fronts compare under.

### Acceptance

- [x] `@print` of a string produces the same bytes on commonJS, erlang and beam, in typed and
      comptime code
- [x] Numeric formatting divergence is stated as intended in `src/codegen/AGENTS.md`
- [ ] The four "byte-identically" tests either hold or carry the name the decision implies

---

<a id="decision-1a"></a>

## Decision 1a — the text of an array and a tuple

**Decided 2026-09-17 by the maintainer**, from WR4 (`array_zip_via_external_node_template`: wasm
printed tuple addresses; erlang/beam `[{1,<<"a">>},…]`, commonJS `[ [ 1, 'a' ], … ]`).

| Value | Text |
|---|---|
| an array | `[e1,e2]` — no spaces |
| a tuple (labeled or not — labels live in the type only) | `#(e1,e2)` — the tuple literal of the 1.0.3 surface, no spaces |
| a string **nested** in an array or a tuple | quoted, as in source: `"a"` |
| a string at top level | bare, unchanged ([decision 1](#decision-1)) |

`[1,2].zip(["a","b"])` prints `[#(1,"a"),#(2,"b")]`; `[#(1,2),#(17,1)]` prints as written.

- **Every backend.** commonJS stops relying on `console.log`'s own array text; erlang and beam
  extend `__bp_print/1` past `~p` for lists and tuples; wasm prints arrays of tuples.
- **Unchanged:** the numeric divergence of decision 1 (erlang family `5.0`) and the text of records,
  enums and maps — not decided here.
- **Open for the implementing row:** escaping inside a nested string; the recommendation is the
  source literal's escapes (`\"`, `\\`, `\n`).

### Acceptance

- [ ] `@print` of an array of tuples, an array of strings and a nested tuple produces the same bytes on
      commonJS, erlang, beam and wasm (one fixture each, RUN LOG verified by running)
- [ ] `array_zip_via_external_node_template` loses its `KNOWN-WRONG` note

---

<a id="decision-5"></a>

## Decision 5 — template markers are positional only

**Decided 2026-09-17 by the maintainer.** A template names the parameters of the declaration it is
attached to by position: `$0` is the first declared parameter, `$1` the second, … — on a method,
`self` is a declared parameter and is `$0`. `$self` is removed. It replaces rule T8 of
[`../06-checker/external-annotations.md`](../06-checker/external-annotations.md) (`$self` on interface
methods, `$N` on `declare fn`) and closes the `$0` vs `$self` unowned item.

| Declaration | Before | After |
|---|---|---|
| `fn contains(self: Self, sub: string) -> bool` | `(string:find($self, $0) =/= nomatch)` | `(string:find($0, $1) =/= nomatch)` |
| `fn includes(self: Self, x: T) -> bool` | `lists:member($0, $self)` | `lists:member($1, $0)` |
| `declare fn encode(text: string) -> string` | `base64:encode($0)` | unchanged |

- **Why:** one rule, no receiver special case; the T8 failure (`$self` in a `declare fn`: a bare
  `PrimOpRecvInUserTemplate` on erlang, always on commonJS, `check` clean) cannot be written.
- **Unchanged:** `$args`, `$stringify(…)`, and the method-name bindings (`@External.Node("includes")`).
- **Measured 2026-09-17:** 47 `$self` (44 `libs/std/src/primitives.bp`, 3 `builtins.d.bp`), about 55
  method templates in `primitives.bp` to renumber, none in the sibling libraries; ~59 `$self`
  references in the template renderers (erlang, commonJS, beam's `$self → {x,0}`, `$N → {x,N+1}`).
- **The risk is silent:** a template left unrenumbered still compiles with its arguments swapped.
  The renumbering is one scripted commit, together with the renderers, proven by
  `libs/std/test/primitives_test.bp` on commonJS and erlang; the checker refuses `$self` and any
  `$N` with N ≥ the declaration's parameter count, with a location.
- **Owner:** [`../12-surface-cutover/`](../12-surface-cutover/README.md) step 3 — it owns `libs/std`, the
  renderers and the checker at that point, and rewrites those files anyway.

### Acceptance

- [ ] No `$self` in any template, renderer or test source; `$self` in a template is a located check error
- [ ] `$N` with N ≥ the parameter count is a located check error
- [ ] Generated code and RUN LOGs byte-identical before and after the renumbering commit

---

<a id="decision-2"></a>

## Decision 2 — the value of a block, and of a fn body's tail expression

### Today

For a `case` arm that is a block with no `break` — source
`val result = case 42 { 0 -> { case 1 { 0 -> 54; _ -> 1; }; }; _ -> 1; };`, snapshots
`snapshots/codegen/{commonJS,erlang,beam,wasm}/case_nested_case_in_block_arm.snap.md`:

| Backend | What the arm yields | Evidence (snapshot line at HEAD) |
|---|---|---|
| commonJS | **discarded** — the inner `(() => {…})()` is emitted as an expression statement and the outer arrow falls through to `return 1` | `commonJS/…:19-23` (inner IIFE), `:25` (`return 1;`) |
| erlang | the inner value — a nested `case … end` in tail position | `erlang/…:21-26` |
| beam | a **fun**: `{make_fun3, {f, 7}, 0, 0, {x, 0}, {list, []}}` lands in x0; the closure itself ends `{move, {atom, ok}, {x, 0}}`, so even calling it yields `ok` | `beam/…:30`, `:53` |
| wasm | `i32.const 0 ;; lambda` | `wasm/…:30` |
| comptime AST | typed `?` | `snapshots/comptime/node/case_nested_case_in_block_arm.snap.md` — the case, the arm and the block body all render `"return_type": "?"` |

Why a fun and a lambda: the typed AST carries a block arm as a zero-parameter `.lambda`
(`src/comptime/snapshot.zig:350-352` `buildCaseArm` tests exactly `fk.syntax == .lambda and
fk.params.len == 0` to render it as `"block"`). beam and wasm lower that node as the lambda it is;
commonJS wraps it in an IIFE whose result is dropped; erlang inlines it.

The comptime `?` here comes from `typeNameOf`'s `.typeVar` arm, not from the syntactic renderer —
the `case` type is a fresh variable its arms are never unified with (the checker's C2, see
[`../06-checker/`](../06-checker/README.md)), so it is a real tripwire and not renderer noise (see
[`../07-comptime-dedup/renderer.md`](../07-comptime-dedup/renderer.md)).

The same disagreement in a fn body with a declared return type is `codegen-features.md:84`
(**S15**): node returns `undefined`, erlang returns the value, beam returns `ok`.

### Options

| | Rule | Consequence |
|---|---|---|
| A | A block **is** an expression; its value is its last expression statement | Matches erlang only. node, beam and wasm all need codegen changes; and it silently gives a value to existing blocks that end in a side-effecting call |
| B | A block is a **statement**; its value is `unit` unless it ends in `break <e>`. The checker rejects a block in value position without `break`, and a fn with a non-`unit` return type whose body falls off the end | Matches the implemented majority (3 of 4 backends already produce no useful value). The construct already exists — `break <e>` is the block-value form throughout the language, and `comptime { break e; }` is the same shape |

### Recommendation: B

Enforced by a checker diagnostic rather than by four codegen changes. The divergence then becomes
unreachable instead of being papered over backend by backend, and no program that still compiles
changes meaning — the programs it affects start failing with a located error instead of running
with a backend-dependent value.

`comptime { break e; }` is currently typed `void` (`comptime-templates-types-exprs.md` cross-cutting
**C4**, `:84`; row `local_binding_inside_comptime`, `:98`) — that is the same rule mis-implemented,
and it is fixed by the same work (the checker's C2, `src/comptime/infer.zig` l.7524-7529 per
[`../06-checker/rows.md`](../06-checker/rows.md)).

### What depends on it

- The four `uncertain` rows in this class: `codegen-features.md:84` (S15), `:124`
  (`codegen_use_tuple_destructure_state_to_usestate`), `:133`
  (`codegen_inline_implement_context_base_erased_at_runtime`) and `codegen-control_flow.md:179`
  (`case_nested_case_in_block_arm`, `uncertain (semantics) + weak`). `:84` and `:133` are the same
  fixture (S15 is its root-cause index row).
- The "else-less `if` as a value" and "`try` in a non-`#[@result]` fn" type questions in report 3.2
  — e.g. `codegen-control_flow.md:156` (`if_simple_conditional_in_fn_body`, `wrong-output
  (divergence)`: node `undefined`, erlang `ok`, beam `undefined`) and `:160`
  (`try_propagate_without_catch`, `weak`).
- The checker rows in [`../06-checker/`](../06-checker/README.md) that decide how a block and a
  `return` are typed (C1, C2). The diagnostic this decision asks for is implemented there; this
  front only records the rule.

### Acceptance

- [ ] A block or fn body used as a value without `break`/`return` is a located checker error
- [ ] No backend emits a fun, a lambda placeholder or a discarded IIFE for a block arm
- [ ] The rule is in the language reference, with the `break` form shown

---

<a id="decision-3"></a>

## Decision 3 — the representation of `null`

### Correction: the beam half is already closed at HEAD

The review recorded beam emitting `{atom, nil}`. That is stale.
`src/codegen/beam_asm.zig:1843-1850` emits `{atom, undefined}` and carries the reason in a comment
("`undefined`, not `nil`: `nil` is the empty *list* on BEAM, and the `@Option` helpers here … test
absence against `undefined`"); `:4297` does the same in the operand path.
`grep '{atom, nil}' snapshots/codegen/beam/` returns nothing, and
`snapshots/codegen/beam/case_multiple_subjects.snap.md:30, 33` now read
`{move, {atom, undefined}, {x, 0}}`.

**Strike**, with that reason:

- `codegen-control_flow.md:196` — `case_multiple_subjects`, `weak (null representation)`
- `codegen-features.md:211` — `option_method_on_tuple_element`, `wrong-output`, which cites a
  `beam_asm.zig:4060` line that no longer exists. Only the `{atom, nil}` half of that row is stale;
  its `%% unresolved method call: slice/3` evidence is a separate beam defect — re-derive it before
  striking the whole row.

Both rows are still counted in the 777 open rows of [`backlog.md`](./backlog.md).

### What is left: wasm

| Backend | `null` lowers to | Deciding site |
|---|---|---|
| commonJS | JS `null` | `src/codegen/commonJS.zig:2148` |
| erlang | atom `undefined` | `src/codegen/erlang.zig:2991` |
| beam | atom `undefined` | `src/codegen/beam_asm.zig:1843-1850`, `:4297` |
| wasm | `i32.const 0` | `src/codegen/wat.zig:2164` — `.null_ => try self.emit(zero)` |

So a `?i32` holding a real `0` is indistinguishable from `null` on wasm, and every narrowing test
that checks a `?i32` for absence is unverifiable.

### Options

| | Representation | Cost |
|---|---|---|
| A | Two i32s — a present flag plus the value | Every signature carrying an optional changes arity |
| B | A sentinel outside the useful range (e.g. `i32.MIN`, or `-1`) | Cheap, and wrong for a full-range `i32` |
| C | Box it: `?T` is an i32 offset into linear memory; `0` is null, non-zero is the address of the payload | Matches the value model wasm already uses — strings are interned as offsets into linear memory, and `$__heap_ptr` is initialised to the end of the data segments (`src/codegen/wat.zig:292-297`, `.init = em.next_data_offset`), which starts at 256 (`snapshots/codegen/wasm/case_nested_case_in_block_arm.snap.md:19` reads `(global $__heap_ptr (mut i32) (i32.const 256))`), so `0` is already an impossible address |

### Recommendation: C

It keeps `0 == null`, which the backend already assumes everywhere, and needs no signature changes.
It costs a heap cell per non-null optional, which is the same price strings already pay.

**Conflict resolved:** the wasm front's W7 once suggested a sentinel ("a tagged pointer, or `-1`").
It implemented C, citing this file (1.0.4-beta wasm, `672165c`).

### What depends on it

- `codegen-wat-narrowing.md`'s `?i32` null-carrier finding — `## Cross-cutting observations`
  item 5 (`:156`, `optional_local_equals_null`; not counted as a verdict row) — and the narrowing
  rows around it in `## Non-ok findings`.
- The four W7 fixtures of the landed wasm front:
  `array_at_lowers_byte_identically_across_backends`, `optional_fn_return_null_path`,
  `narrow_if_null_check_with_print`, `narrow_type_guard_if_codegen`.
- Verification of any of them needs `executeWat` — it executes since 1.0.4-beta wasm.

### Acceptance

- [x] `null` and the integer `0` are distinguishable in a wasm `?i32`
- [x] The representation of `null` on all four backends is one table in `src/codegen/AGENTS.md`
- [ ] The two stale beam rows are struck in their reports with the reason

---

<a id="decision-4"></a>

## Decision 4 — the severity of `assert` outside test mode

### Correction: this is not a question about severity

**`assert` is a no-op on two of the four backends.** Source
`fn f() { assert false, "error message"; }`, snapshots `snapshots/codegen/*/assert_with_message.snap.md`:

| Backend | Emitted | Effect | Deciding site |
|---|---|---|---|
| commonJS | `console.assert(false, "error message");` (`commonJS/…:11`) | prints to stderr, **continues**, exit 0 | `src/codegen/commonJS.zig:2427-2431` |
| erlang | `true = (false).` (`erlang/…:13`) | raises `{badmatch, false}` — **the message and location are dropped** | `src/codegen/erlang.zig:3636` |
| beam | `{move,{atom,undefined},{x,0}}` then `{move,{atom,ok},{x,0}}` (`beam/…:21-22`) | **nothing** — `f()` returns `ok`. `grep assert src/codegen/beam_asm.zig` → **0 matches**: the construct has no lowering at all | — |
| wasm | `(func $f (result i32) i32.const 0)` — the body is gone (`wasm/…:13-15`) | **nothing.** `grep assert src/codegen/wat.zig` → **0 matches**: no lowering at all | — |
| all, **test mode** | `__bp_assert(cond, msg, loc)` / `erlang:error({bp_assert, Msg, Where})` | a tagged throw the runner catches per test, then continues | `src/codegen/commonJS.zig:2418-2425`, `src/codegen/erlang.zig:3637-3645` |

### Options

| | Rule | Consequence |
|---|---|---|
| A | `assert` is always fatal, on every backend, carrying the message and the `file:line` | node reuses the `__bp_assert` helper it already has, rethrowing instead of recording; erlang reuses the `{bp_assert, Msg, Where}` raise it already builds; beam and wasm need an implementation (an `erlang:error/1` call and an `unreachable`, respectively) |
| B | `assert` is debug-only, compiled out outside test mode | node and erlang must stop emitting anything; beam and wasm already comply. Cheapest, but it makes `assert` useless in a shipped program |
| C | Keep the per-backend behaviour and document it | Not viable — on beam and wasm there is nothing to document but the absence |

### Recommendation: A

The helper exists on both backends that emit anything, it fixes erlang's dropped message and
location for free, and a construct that silently vanishes on half the targets is exactly the blind
spot the gate front is about (no snapshot asserts on stdout on any backend —
[`../05-cli-residuals/`](../05-cli-residuals/README.md)). If B is chosen instead, `assert` must be removed from
the language reference's list of runtime checks and the two backends that still emit must be
changed — B is not the no-work option it looks like.

### What depends on it

- `codegen-builtins-aggregates.md:90` (`assert_with_message`, the one `uncertain` row in this
  class — the row's slug cell reads `same 4`; the slug is in its evidence).
- The "beam `assert` bodies dropped" class in report 3.5: `codegen-builtins-aggregates.md:88`
  (4 `assert_*` slugs, beam, `wrong-output`) and `:95` (9 `assert_pattern_*` slugs, beam,
  `wrong-output`).

### Acceptance

- [x] `assert false, "msg"` behaves identically on all four backends outside test mode
- [x] The failure names the message and the `file:line` on every backend that fails
- [ ] Test mode is unchanged: the runner catches per test and continues
